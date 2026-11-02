# CLAUDE.md — Vampior auth app

Project guide for Claude Code and contributors. Read this before you change anything.
`README.md` explains the project to reviewers, and `DESIGN.md` is the visual spec and the
source of truth for UI.

## Commands

```bash
flutter pub get
flutter analyze                       # must report "No issues found!"
flutter test                          # unit + widget tests (≈85); must be green
flutter test screenshot_test          # re-renders screenshots/*.png (real fonts)
flutter run -d emulator-5554          # Android emulator
flutter build linux --debug           # needs: sudo apt install libsecret-1-dev
dart format -l 100 lib test screenshot_test
```

Toolchain: Flutter 3.47 / Dart 3.13. Private named initializing formals (`required this._x`)
are used on purpose, since the `prefer_initializing_formals` lint asks for them.

## Architecture (feature-first Clean Architecture)

```
lib/
  core/            shared kernel: di, network, storage, auth (tokens/events), error, theme,
                   router, validation, utils, presentation (FormController)
  features/<f>/
    domain/        entities, repository interfaces, use cases (no Flutter, Dio or sqflite imports)
    data/          models (JSON), data sources, repository implementations
    presentation/  controllers (ChangeNotifier), pages, feature widgets
    di/            <f>_module.dart (get_it registrations for this feature)
  features/startup/ launch screen + StartupController (routing decision, auto-login)
  shared/widgets/  design-system UI kit
  mock_backend/    the fake server: SQLite DB, stores, token service, MockAuthServer,
                   MockApiInterceptor, mock_backend_module.dart
```

Rules:
- **Dependencies point inward.** presentation → domain ← data. Domain imports only `core`
  primitives (`Failure`, `UseCase`, `AuthTokens`), `dartz` and `equatable`.
- **The app never imports `mock_backend/`** except `core/di/service_locator.dart`, which
  registers it. The app talks to the backend only over HTTP-shaped Dio calls. The backend
  may import shared contracts (`ApiEndpoints`, validators, `LkMobile`).
- **Errors:** data sources throw (`DioException`, `CacheException`). Repositories catch
  everything and return `Either<Failure, T>` (`DioErrorMapper` maps HTTP status to `Failure`).
  Controllers and widgets never see exceptions. Add new failure kinds to the sealed `Failure`
  in `core/error/failures.dart`.
- **One use case per action**, as a callable class (`LoginUser`, `GetCurrentSession`,
  `RestoreSession`, …).

## Dependency injection (get_it)

- `sl` lives in `core/di/service_locator.dart`. Only use it inside DI modules and in
  `AppRouter` / `app.dart`. Everything else takes constructor parameters.
- `configureDependencies([DependencyOverrides])` registers modules in order:
  `core_module` (Clock, SharedPreferences, PreferencesDataSource, TokenStorage, SessionEvents)
  → `mock_backend_module` (AppDatabase, UserStore, SessionStore, MockTokenService,
  MockAuthServer, transport `Interceptor`) → `network_module` (bare Dio, AuthInterceptor,
  main Dio) → `onboarding_module` → `auth_module` → `startup_module` (it uses use cases from both).
- Services and use cases are `registerLazySingleton`. **Controllers are `registerFactory`**.
  `AppRouter._scoped<T>()` wraps each page in `ChangeNotifierProvider(create: (_) => sl<T>())`,
  so state is per route and disposed on pop.
- To add a feature, create `features/<f>/di/<f>_module.dart` with a `register<F>Module(GetIt sl)`
  function, call it from `configureDependencies`, and add a route in `AppRouter`.
- Tests call `configureDependencies(DependencyOverrides(...))` and
  `tearDown(resetDependencies)`. Widget tests use `test/helpers/app_harness.dart`.

## State (Provider)

- Form screens extend `FormController` (`core/presentation/form_controller.dart`). Its `run()`
  handles loading, failure and success, ignores double submits, and is safe after dispose.
- Widgets use `context.watch<T>()` to rebuild and `context.read<T>()` in callbacks.
- `HomeController` drives the signed-in screen: it calls `/auth/me`, runs a token countdown
  and handles logout.

## Auth and tokens

- Login and register return `{user, accessToken, refreshToken, tokenType, expiresIn}`. The
  repository saves the pair through `TokenStorage` (`SecureTokenStorage` uses
  flutter_secure_storage). **Tokens never go to prefs or SQLite on the client.**
- Mark public requests with `Options(extra: ApiEndpoints.publicRequest)`. Anything else gets
  `Authorization: Bearer` from `AuthInterceptor` (a `QueuedInterceptor`):
  - expired before sending (10s skew) → refresh first;
  - 401 → refresh once, then retry once. If another request already refreshed, it only
    retries;
  - refresh 401 → clear tokens + `SessionEvents.sessionExpired()`. `VampiorApp` then routes
    to Login with a toast. A network error during refresh keeps the session.
- Refresh and retry go through the **bare Dio** (no AuthInterceptor), which avoids queue
  deadlock and recursion.
- Mock server: access token is a JWT-shaped HS256 token with a 60s TTL. The refresh token is
  random, lasts 7 days, and is rotated on every refresh (the old one is revoked; replaying it
  gives a 401). Logout revokes it.
- **Launch / auto-login:** the initial route is `/` → `StartupPage` + `StartupController`:
  onboarding not seen → Onboarding; else `RestoreSession` (tokens present and
  `keepSignedIn` → `/auth/me`, refreshing if needed) → Home; offline or 5xx → Home anyway
  (tokens are still valid, Home can retry); anything else → Login.
- **Remember me** = stay signed in: `LoginUser` saves `keepSignedIn = rememberMe` (and the
  remembered identifier); `RegisterUser` saves `true`. With it off, the next launch clears
  the tokens and opens Login. Logout clears the tokens, so the next launch opens Login.

## Storage map

| What | Where |
|---|---|
| access/refresh token, access expiry | flutter_secure_storage (`vampior.accessToken`, `vampior.refreshToken`, `vampior.accessExpiresAt`) |
| onboarding seen, remembered identifier, stay signed in | shared_preferences (`vampior.onboardingSeen`, `vampior.rememberedId`, `vampior.keepSignedIn`) |
| users, sessions (server side) | SQLite `vampior.db` v2. Mobile: sqflite default dir. Desktop: app-support dir |

Schema changes: bump `AppDatabase.version`, add a step to `_onUpgrade`, and add a migration
test as in `test/mock_backend/backend_test.dart`.

## UI rules

- Use `shared/widgets`: `AppTextField` (label, icon/prefix, eye toggle, valid check, reserved
  message row), **`PhoneField`** (prebuilt +94 mobile input: always use it for phone numbers,
  read the value with `PhoneField.digitsOf`), `PrimaryButton` (loading crossfade, `expand: false`
  to hug its label, `destructive` red variant, `icon`),
  `SecondaryButton`, `AppTextLink`, `StatusBanner`, `AppSnackbar` (top toast),
  `PasswordStrengthMeter`, `Shake`, `Pressable`, `ResponsiveFrame` / `AppTopBar`.
- Use colors, type and motion from `core/theme`. No raw hex values or magic durations in
  pages.
- Validation: pure functions in `core/validation/validators.dart` return `String?`. Fields
  show errors once blurred with content, or after submit via `forceValidation: controller.submitted`.
- **Confirmations:** destructive or irreversible actions (Log out, delete, discard) must go
  through `showConfirmDialog(...)` from `shared/widgets/app_dialog.dart`. Act only when it
  returns `true`. Test keys: `dialog.confirm`, `dialog.cancel`.
- **Messages:** form errors show as an inline `StatusBanner`. Success toasts use `AppSnackbar`,
  pinned to the **top** so they never cover the bottom CTA bar.
- Every form screen uses `AuthScaffold` (top bar, scrollable body, pinned CTA). Check for
  overflow at 320×568 and 1280×800 (there are tests for both).

## Testing conventions

- `test/helpers/fakes.dart`: `FakeUserStore`, `FakeSessionStore`, `InMemoryTokenStorage`,
  `TestClock`. Widget tests can't run real sqflite I/O inside fake async, so use the fakes.
  Data tests use `sqflite_common_ffi` with `inMemoryDatabasePath`.
- `test/core/auth_flow_test.dart` runs the real client stack against the real mock server,
  with separate client and server clocks to simulate skew.
- Find widgets by key: `login.identifier|password|submit|remember`,
  `register.name|email|mobile|password|confirm|submit`, `forgot.identifier|submit|sent`,
  `success.logout|refresh|error`, `dialog.confirm|cancel`, `onboarding.next|pager`.

## Gotchas

- **google_fonts × material_ui:** on Flutter 3.47, `google_fonts` returns `material_ui` types
  that clash with `flutter/material`. Archivo is bundled in `assets/fonts` and declared in
  pubspec instead. Don't re-add google_fonts.
- **Animations in tests:** the first `pump()` after a `setState` only starts tickers; pump
  again (e.g. `pump(300ms)`) before asserting or capturing mid-animation.
- The `PrimaryButton` spinner sits in `TickerMode(enabled: loading)`, so idle screens can
  settle (`pumpAndSettle`).
- Don't put a `Spacer` and a `Flexible` in the same Row (they split the free space 50/50).
  The onboarding controls measure the label and switch to a stacked layout when it doesn't
  fit.
- The test font draws every glyph 1em wide. Tests that depend on text width load Archivo
  with `FontLoader`.
- The headless screenshot renderer doesn't blur shadows; on a device they look fine.
- Linux builds need `libsecret-1-dev` for flutter_secure_storage.
