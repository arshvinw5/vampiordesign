# Vampior — Auth Flow (Flutter)

Onboarding, login, registration and password reset for Vampior Designs, built from the
`Auth Flow v3` design (spec in [`DESIGN.md`](DESIGN.md)).

- **Flutter 3.47 / Dart 3.13** · **Provider** for state · **dartz `Either`** for errors
- **Dio** + a mock API interceptor (no backend needed) · **SQLite** (`sqflite`) user store
- **shared_preferences** for "onboarding seen" and "Remember me"
- Clean Architecture: `domain` ← `data`, `domain` ← `presentation`

## Run

```bash
flutter pub get
flutter run                 # Android / iOS / Linux / macOS / Windows
flutter test                # 62 unit + widget tests
flutter test screenshot_test   # regenerates screenshots/ (see below)
```

Web isn't supported because sqflite has no web backend.

### Demo accounts and mock API scenarios

Every request goes through Dio and waits 1.5s to simulate the network. `MockApiInterceptor`
answers the request from `MockAuthServer`, which reads and writes the SQLite `users` table.

| Try | Result |
|---|---|
| `demo@vampior.com` / `demo1234` (or mobile `0771234567`) | 200 → Success screen (this user is seeded on first launch) |
| Wrong password or an unknown user | 401 → "Incorrect email/mobile or password" |
| Register a new user | 201 → user saved in SQLite → Success screen; you can log in with it afterwards |
| Register with an existing email or mobile | 409 → "Email already registered" / "Mobile number already registered" |
| Forgot password with a known or unknown user | 200 "Reset link sent" (30s resend cooldown) / 404 |
| Any identifier starting with `network@` | Connection error → "No connection…" |
| Any identifier starting with `server@` | 500 → "Something went wrong on our side…" |

To use a real backend, remove `MockApiInterceptor` in `core/di/injection.dart` and set
`ApiEndpoints.baseUrl`. Nothing else changes.

## Behaviour

- **Onboarding** appears only on first launch. Skip or "Get started" saves a flag, and later launches open on **Login**. "Replay onboarding" is on the Success screen.
- **Login**: email-or-mobile field, password with show/hide, Remember me (prefills the identifier next time), Forgot password link, and a loading button that crossfades to a spinner while the form dims and ignores taps.
- **Register**: full name, email, `+94` mobile (auto-formatted `77 123 4567`), password with a strength meter, and confirm password.
- **Validation**: errors appear after a field loses focus with content, or on every field at submit, and then update live. An invalid submit shakes the form and focuses the first bad field. The message row's space is always reserved, so the layout never jumps.
- **Feedback**: API errors show an inline banner and a snackbar; successes show a snackbar and navigate.
- **Navigation**: Navigator with named routes and a fade + 24px slide transition. Success clears the stack, so Back can't return to a submitted form.
- **Responsive**: full-bleed on phones. At 600px+ wide it becomes a framed 400px card on the ice background. Every form scrolls and the CTA stays pinned. Widget tests check 320×568 and 1280×800 for overflow.
- **Reduced motion** is respected: slides and blur turn off, fades stay.

## Architecture

```
lib/
├─ main.dart, app.dart            bootstrap, MaterialApp, providers
├─ core/
│  ├─ di/injection.dart           composition root (builds the graph, exposes use cases)
│  ├─ database/app_database.dart  SQLite open/schema/seed
│  ├─ network/                    Dio client, endpoints, DioException → Failure mapper
│  │  └─ mock/                    MockApiInterceptor + MockAuthServer (fake backend)
│  ├─ storage/                    shared_preferences data source
│  ├─ error/                      Failure (sealed) + data-layer exceptions
│  ├─ usecase/, presentation/     UseCase base, FormController base (loading/error/submitted)
│  ├─ router/                     route names, onGenerateRoute, page transition
│  ├─ theme/                      colour, type, motion tokens from DESIGN.md
│  ├─ validation/validators.dart  pure field validators
│  └─ utils/                      +94 phone formatter, password strength, hashing
├─ features/
│  ├─ auth/
│  │  ├─ domain/                  User, AuthSession, AuthRepository (abstract), use cases
│  │  ├─ data/                    models (JSON), remote (Dio) + SQLite data sources, repository impl
│  │  └─ presentation/            controllers (ChangeNotifier), pages, auth-only widgets
│  └─ onboarding/                 same three layers
└─ shared/widgets/                reusable UI kit: AppTextField, PrimaryButton, SecondaryButton,
                                  AppTextLink, PasswordStrengthMeter, StatusBanner/AppSnackbar,
                                  Shake, Pressable, ResponsiveFrame/AppTopBar
```

A request flows **Page → Controller (Provider) → UseCase → AuthRepository → Dio data source →
(MockApiInterceptor → MockAuthServer → SQLite)**. Failures come back as
`Either<Failure, T>` and are never thrown into the UI.

## Screenshots

These are rendered headlessly by `screenshot_test/` using the app's real fonts. The test
renderer doesn't blur shadows, so drop shadows look like hard bands in these images. On a
device they render soft.

| | | |
|---|---|---|
| ![](screenshots/01_onboarding.png) Onboarding | ![](screenshots/03_login.png) Login | ![](screenshots/04_login_validation.png) Validation |
| ![](screenshots/06_login_loading.png) Loading | ![](screenshots/07_login_api_error.png) API error | ![](screenshots/08_login_success.png) Logged in |
| ![](screenshots/10_register_validation.png) Register errors | ![](screenshots/11_register_filled.png) Register filled | ![](screenshots/12_register_success.png) Account created |
| ![](screenshots/13_register_duplicate_email.png) Duplicate email | ![](screenshots/14_forgot_password_sent.png) Reset sent | ![](screenshots/16_small_phone_register_validation.png) 320×568 |

![Tablet / desktop](screenshots/15_tablet_desktop_login.png)
