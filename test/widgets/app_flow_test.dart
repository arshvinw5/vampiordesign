import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vampiordesigns/core/auth/auth_tokens.dart';
import 'package:vampiordesigns/core/di/service_locator.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';
import 'package:vampiordesigns/mock_backend/database/app_database.dart';
import 'package:vampiordesigns/shared/widgets/primary_button.dart';

import '../helpers/app_harness.dart';
import '../helpers/fakes.dart';

const _latency = Duration(milliseconds: 300);

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<AppHarness> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = onboardingDone,
  SharedPreferences? instance,
  FakeUserStore? users,
}) => pumpVampiorApp(
  tester,
  prefs: prefs,
  prefsInstance: instance,
  users: users,
  apiLatency: _latency,
);

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
}

/// Submits and waits out the mock API latency.
Future<void> _submit(WidgetTester tester, String key) async {
  await _tapKey(tester, key);
  await tester.pump();
  await tester.pump(_latency);
  await tester.pumpAndSettle();
}

/// Taps Log out, confirms the dialog, and waits for the logout API call.
Future<void> _logOut(WidgetTester tester) async {
  await _tapKey(tester, 'success.logout');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dialog.confirm')));
  await tester.pump();
  await tester.pump(_latency);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

void main() {
  tearDown(resetDependencies);

  group('Onboarding', () {
    testWidgets('shows on first launch only; Skip persists and opens Login', (tester) async {
      final prefs = await _prefs({});
      await _pumpApp(tester, instance: prefs);
      expect(find.text('Design that sets your brand apart'), findsOneWidget);

      await _tapText(tester, 'Skip');
      expect(find.text('Welcome back. Enter your details to continue.'), findsOneWidget);
      expect(prefs.getBool(PreferencesDataSource.onboardingSeenKey), isTrue);

      // "Relaunch" with the same preferences → straight to Login.
      await tester.pumpWidget(const SizedBox());
      await _pumpApp(tester, instance: prefs);
      expect(find.text('Design that sets your brand apart'), findsNothing);
      expect(find.text('Welcome back. Enter your details to continue.'), findsOneWidget);
    });

    testWidgets('Next → Next → Get started reaches Login', (tester) async {
      await _pumpApp(tester, prefs: {});
      await _tapText(tester, 'Next');
      expect(find.text('Websites and apps built to convert'), findsOneWidget);
      await _tapText(tester, 'Next');
      expect(find.text('Get started'), findsWidgets);
      await _tapText(tester, 'Get started');
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
    });
  });

  group('Launch / auto-login', () {
    /// Logs in through the UI, then "relaunches" the app reusing the same
    /// preferences, secure storage and backend (as a real restart would).
    Future<AppHarness> loginThenRelaunch(
      WidgetTester tester, {
      bool rememberMe = true,
      Future<void> Function(AppHarness app)? beforeRelaunch,
    }) async {
      final app = await _pumpApp(tester);
      if (!rememberMe) await tester.tap(find.byKey(const Key('login.remember')));
      await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
      await _enter(tester, 'login.password', AppDatabase.demoPassword);
      await _submit(tester, 'login.submit');
      expect(find.text('Welcome back'), findsOneWidget);
      await beforeRelaunch?.call(app);

      await tester.pumpWidget(const SizedBox());
      final relaunched = await pumpVampiorApp(
        tester,
        prefsInstance: app.prefs,
        users: app.users,
        sessions: app.sessions,
        tokens: app.tokens,
        apiLatency: _latency,
      );
      await tester.pump(_latency * 3);
      await tester.pumpAndSettle();
      return relaunched;
    }

    testWidgets('first launch → onboarding; seen + no session → login', (tester) async {
      final prefs = await _prefs({});
      await _pumpApp(tester, instance: prefs);
      expect(find.text('Design that sets your brand apart'), findsOneWidget);
      await _tapText(tester, 'Skip');
      await _pumpApp(tester, instance: prefs);
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
    });

    testWidgets('signed in + Remember me → relaunch opens the signed-in screen', (tester) async {
      await loginThenRelaunch(tester);
      expect(find.text('You\u2019re still signed in from your last session.'), findsOneWidget);
      expect(find.text('Demo User'), findsOneWidget); // profile via /auth/me
      expect(find.byKey(const Key('login.identifier')), findsNothing);
    });

    testWidgets('Remember me off → relaunch opens Login and drops the tokens', (tester) async {
      final app = await loginThenRelaunch(tester, rememberMe: false);
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
      expect(app.tokens.tokens, isNull);
    });

    testWidgets('session revoked while closed → relaunch opens Login', (tester) async {
      final app = await loginThenRelaunch(
        tester,
        beforeRelaunch: (app) async {
          await app.sessions.revoke(app.tokens.tokens!.refreshToken);
          // Force a refresh on launch: access token already expired.
          app.tokens.tokens = AuthTokens(
            accessToken: app.tokens.tokens!.accessToken,
            refreshToken: app.tokens.tokens!.refreshToken,
            accessExpiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
          );
        },
      );
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
      expect(app.tokens.tokens, isNull);
    });

    testWidgets('log out → relaunch opens Login', (tester) async {
      final app = await loginThenRelaunch(
        tester,
        beforeRelaunch: (app) async {
          await _logOut(tester);
          expect(find.byKey(const Key('login.identifier')), findsOneWidget);
        },
      );
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
      expect(app.tokens.tokens, isNull);
    });
  });

  group('Login', () {
    testWidgets('empty submit shows required errors', (tester) async {
      await _pumpApp(tester);
      await _tapKey(tester, 'login.submit');
      await tester.pumpAndSettle();
      expect(find.text('Email or mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('invalid formats show specific errors, fixed live', (tester) async {
      await _pumpApp(tester);
      await _enter(tester, 'login.identifier', 'nope');
      await _enter(tester, 'login.password', '123');
      await _tapKey(tester, 'login.submit');
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email or mobile number'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      await _enter(tester, 'login.identifier', 'demo@vampior.com');
      expect(find.text('Enter a valid email or mobile number'), findsNothing);
    });

    testWidgets('show / hide password toggles obscureText', (tester) async {
      await _pumpApp(tester);
      EditableText field() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('login.password')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(field().obscureText, isTrue);
    });

    testWidgets(
      'success: loading → tokens stored → profile from /auth/me → Log out revokes + clears',
      (tester) async {
        final app = await _pumpApp(tester);
        await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
        await _enter(tester, 'login.password', AppDatabase.demoPassword);

        await _tapKey(tester, 'login.submit');
        await tester.pump();
        expect(tester.widget<PrimaryButton>(find.byKey(const Key('login.submit'))).loading, isTrue);

        await tester.pump(_latency);
        await tester.pumpAndSettle(); // also waits for the /auth/me call
        expect(find.text('Welcome back'), findsOneWidget);
        final stored = app.tokens.tokens!;
        expect(app.sessions.sessions[stored.refreshToken]!.revoked, isFalse);

        // Profile rows came from the protected endpoint.
        expect(find.text('Demo User'), findsOneWidget);
        expect(find.text('+94 77 123 4567'), findsOneWidget);
        expect(find.textContaining('Expires in'), findsOneWidget);
        expect(find.text('Stored in secure storage'), findsOneWidget);

        // Cancel first: nothing happens.
        await _tapKey(tester, 'success.logout');
        await tester.pumpAndSettle();
        expect(find.text('Log out?'), findsOneWidget);
        await tester.tap(find.byKey(const Key('dialog.cancel')));
        await tester.pumpAndSettle();
        expect(find.text('Log out?'), findsNothing);
        expect(app.tokens.tokens, isNotNull);
        expect(find.text('Welcome back'), findsOneWidget);

        // Confirm: session revoked, tokens cleared.
        await _logOut(tester);
        expect(app.tokens.tokens, isNull);
        expect(app.sessions.sessions[stored.refreshToken]!.revoked, isTrue);
        // Back on Login, identifier remembered.
        expect(find.widgetWithText(TextField, AppDatabase.demoEmail), findsOneWidget);
      },
    );

    testWidgets('revoked session on Success → back to Login with "session expired"', (
      tester,
    ) async {
      final app = await _pumpApp(tester);
      await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
      await _enter(tester, 'login.password', AppDatabase.demoPassword);
      await _submit(tester, 'login.submit');
      expect(find.text('Welcome back'), findsOneWidget);

      // Server revokes the session; the access token is also rejected.
      await app.sessions.revoke(app.tokens.tokens!.refreshToken);
      app.tokens.tokens = AuthTokens(
        accessToken: 'bogus.token.sig',
        refreshToken: app.tokens.tokens!.refreshToken,
        accessExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      await _tapKey(tester, 'success.refresh');
      await tester.pump();
      await tester.pump(_latency * 3);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
      expect(find.text('Session expired, please log in again'), findsOneWidget);
      expect(app.tokens.tokens, isNull);
    });

    testWidgets('wrong password shows API error', (tester) async {
      await _pumpApp(tester);
      await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
      await _enter(tester, 'login.password', 'wrongpass');
      await _submit(tester, 'login.submit');
      expect(find.text('Incorrect email/mobile or password'), findsWidgets);
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('network failure is reported', (tester) async {
      await _pumpApp(tester);
      await _enter(tester, 'login.identifier', 'network@vampior.com');
      await _enter(tester, 'login.password', 'whatever');
      await _submit(tester, 'login.submit');
      expect(find.textContaining('No connection'), findsWidgets);
    });
  });

  group('Register', () {
    Future<void> openRegister(WidgetTester tester, {FakeUserStore? users}) async {
      await _pumpApp(tester, users: users);
      await _tapText(tester, 'Create one');
      expect(find.text('Create account'), findsWidgets);
    }

    Future<void> fill(
      WidgetTester tester, {
      String email = 'jane@doe.com',
      String confirm = 'abcdefg1',
    }) async {
      await _enter(tester, 'register.name', 'Jane Doe');
      await _enter(tester, 'register.email', email);
      await _enter(tester, 'register.mobile', '0712345678');
      await _enter(tester, 'register.password', 'abcdefg1');
      await _enter(tester, 'register.confirm', confirm);
    }

    testWidgets('validates every field on submit', (tester) async {
      await openRegister(tester);
      await _tapKey(tester, 'register.submit');
      await tester.pumpAndSettle();
      for (final msg in [
        'Full name is required',
        'Email address is required',
        'Mobile number is required',
        'Password is required',
        'Please confirm your password',
      ]) {
        expect(find.text(msg), findsOneWidget, reason: msg);
      }
    });

    testWidgets('mobile is formatted and mismatched confirm is caught', (tester) async {
      await openRegister(tester);
      await fill(tester, confirm: 'abcdefg2');
      expect(find.widgetWithText(TextField, '71 234 5678'), findsOneWidget);
      await _tapKey(tester, 'register.submit');
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('creates account → Success; duplicate email → error', (tester) async {
      final users = FakeUserStore();
      await openRegister(tester, users: users);
      await fill(tester);
      await _submit(tester, 'register.submit');
      expect(find.text('Account created'), findsOneWidget);
      expect(find.text('+94 71 234 5678'), findsOneWidget);
      expect(users.rows.length, 2);
      expect(find.text('Jane Doe'), findsOneWidget); // from /auth/me

      // Log out (revokes the session over the API) → register again with the same email.
      await _logOut(tester);
      await _tapText(tester, 'Create one');
      await fill(tester);
      await _submit(tester, 'register.submit');
      expect(find.text('Email already registered'), findsWidgets);
    });

    testWidgets('back returns to Login', (tester) async {
      await openRegister(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login.identifier')), findsOneWidget);
    });
  });

  testWidgets('Forgot password: prefilled id → link sent with cooldown', (tester) async {
    await _pumpApp(tester);
    await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
    await _tapText(tester, 'Forgot password?');
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.widgetWithText(TextField, AppDatabase.demoEmail), findsOneWidget);

    await _submit(tester, 'forgot.submit');
    expect(find.byKey(const Key('forgot.sent')), findsOneWidget);
    expect(find.textContaining('Resend available in'), findsOneWidget);
  });

  group('Onboarding controls', () {
    // Real glyph widths matter here (the test font draws every glyph 1em wide).
    setUpAll(() async {
      Future<ByteData> read(String path) async =>
          ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
      await (FontLoader('Archivo')
            ..addFont(read('assets/fonts/Archivo-Regular.ttf'))
            ..addFont(read('assets/fonts/Archivo-Bold.ttf')))
          .load();
    });

    for (final width in const [320.0, 390.0]) {
      testWidgets('Next / Get started is never squeezed at ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpApp(tester, prefs: {});

        for (var slide = 0; slide < 3; slide++) {
          final button = find.byKey(const Key('onboarding.next'));
          expect(tester.getSize(button).width, greaterThanOrEqualTo(152), reason: 'slide $slide');
          final label = slide == 2 ? 'Get started' : 'Next';
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: button, matching: find.text(label)).first,
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: '"$label" clipped on slide $slide');
          // Button stays inside the screen with the 24px gutter.
          expect(tester.getTopRight(button).dx, lessThanOrEqualTo(width - 24 + 0.5));
          if (slide < 2) await _tapText(tester, 'Next');
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Responsive', () {
    for (final size in const [Size(320, 568), Size(1280, 800)]) {
      testWidgets('no overflow at ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _pumpApp(tester, prefs: {});
        expect(tester.takeException(), isNull);
        await _tapText(tester, 'Skip');
        await _tapKey(tester, 'login.submit'); // show all error rows
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _tapText(tester, 'Create one');
        await _tapKey(tester, 'register.submit');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
