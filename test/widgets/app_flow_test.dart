import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vampiordesigns/app.dart';
import 'package:vampiordesigns/core/database/app_database.dart';
import 'package:vampiordesigns/core/di/injection.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';
import 'package:vampiordesigns/shared/widgets/primary_button.dart';

import '../helpers/fake_user_data_source.dart';

const _latency = Duration(milliseconds: 300);

Future<SharedPreferences> _prefs(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<void> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {PreferencesDataSource.onboardingSeenKey: true},
  SharedPreferences? instance,
  FakeUserDataSource? users,
}) async {
  final deps = await AppDependencies.init(
    prefs: instance ?? await _prefs(prefs),
    users: users ?? FakeUserDataSource(),
    apiLatency: _latency,
  );
  await tester.pumpWidget(VampiorApp(dependencies: deps));
  await tester.pumpAndSettle();
}

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

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

void main() {
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
            find.descendant(of: find.byKey(const Key('login.password')), matching: find.byType(EditableText)),
          );
      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(field().obscureText, isFalse);
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(field().obscureText, isTrue);
    });

    testWidgets('success: loading state → Success → Log out keeps remembered id', (tester) async {
      await _pumpApp(tester);
      await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
      await _enter(tester, 'login.password', AppDatabase.demoPassword);

      await _tapKey(tester, 'login.submit');
      await tester.pump();
      expect(tester.widget<PrimaryButton>(find.byKey(const Key('login.submit'))).loading, isTrue);

      await tester.pump(_latency);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text(AppDatabase.demoEmail), findsOneWidget);

      await tester.tap(find.byKey(const Key('success.logout')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, AppDatabase.demoEmail), findsOneWidget);
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
    Future<void> openRegister(WidgetTester tester, {FakeUserDataSource? users}) async {
      await _pumpApp(tester, users: users);
      await _tapText(tester, 'Create one');
      expect(find.text('Create account'), findsWidgets);
    }

    Future<void> fill(WidgetTester tester, {String email = 'jane@doe.com', String confirm = 'abcdefg1'}) async {
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
      final users = FakeUserDataSource();
      await openRegister(tester, users: users);
      await fill(tester);
      await _submit(tester, 'register.submit');
      expect(find.text('Account created'), findsOneWidget);
      expect(find.text('+94 71 234 5678'), findsOneWidget);
      expect(users.rows.length, 2);

      // Log out → register again with the same email.
      await tester.tap(find.byKey(const Key('success.logout')));
      await tester.pumpAndSettle();
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
