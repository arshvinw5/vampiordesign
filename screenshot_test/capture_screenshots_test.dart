// Renders every key screen/state to PNGs in `screenshots/`.
//
//   flutter test screenshot_test
//
// Uses the real bundled Archivo + Material Icons fonts so output matches
// the running app. Kept outside `test/` so the normal test run stays fast.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vampiordesigns/app.dart';
import 'package:vampiordesigns/core/database/app_database.dart';
import 'package:vampiordesigns/core/di/injection.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';

import '../test/helpers/fake_user_data_source.dart';

const _latency = Duration(milliseconds: 1500);
const _phone = Size(390, 844);
final _boundary = GlobalKey();

Future<void> _loadFonts() async {
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));

  final archivo = FontLoader('Archivo')
    ..addFont(read('assets/fonts/Archivo-Regular.ttf'))
    ..addFont(read('assets/fonts/Archivo-Bold.ttf'));
  await archivo.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _pumpApp(WidgetTester tester, {required bool onboardingSeen, Size size = _phone}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    if (onboardingSeen) PreferencesDataSource.onboardingSeenKey: true,
  });
  final deps = await AppDependencies.init(
    prefs: await SharedPreferences.getInstance(),
    users: FakeUserDataSource(),
    apiLatency: _latency,
  );
  await tester.pumpWidget(RepaintBoundary(key: _boundary, child: VampiorApp(dependencies: deps)));
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('screenshots/$name.png')..createSync(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key, {bool settle = true}) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  if (settle) await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.drag(scrollable, const Offset(0, 2000));
  await tester.pumpAndSettle();
}

/// Waits out the mock API and the success animations.
Future<void> _finishRequest(WidgetTester tester) async {
  await tester.pump(_latency);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('onboarding', (tester) async {
    await _pumpApp(tester, onboardingSeen: false);
    await _capture(tester, '01_onboarding');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'Next');
    await _capture(tester, '02_onboarding_last');
  });

  testWidgets('login states', (tester) async {
    await _pumpApp(tester, onboardingSeen: true);
    await _capture(tester, '03_login');

    await _tapKey(tester, 'login.submit');
    await _capture(tester, '04_login_validation');

    await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
    await _enter(tester, 'login.password', 'wrongpass');
    await tester.tap(find.byTooltip('Show password'));
    await _blur(tester);
    await _capture(tester, '05_login_filled_password_visible');

    await _tapKey(tester, 'login.submit', settle: false);
    await tester.pump(); // first frame starts the crossfade tickers
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, '06_login_loading');
    await _finishRequest(tester);
    await _capture(tester, '07_login_api_error');

    await _enter(tester, 'login.password', AppDatabase.demoPassword);
    await _tapKey(tester, 'login.submit', settle: false);
    await _finishRequest(tester);
    await _capture(tester, '08_login_success');
  });

  testWidgets('register states', (tester) async {
    await _pumpApp(tester, onboardingSeen: true);
    await _tapText(tester, 'Create one');
    await _capture(tester, '09_register');

    await _tapKey(tester, 'register.submit');
    await _scrollToTop(tester);
    await _capture(tester, '10_register_validation');

    await _enter(tester, 'register.name', 'Jane Doe');
    await _enter(tester, 'register.email', 'jane@doe.com');
    await _enter(tester, 'register.mobile', '0712345678');
    await _enter(tester, 'register.password', 'Vampior2026');
    await _enter(tester, 'register.confirm', 'Vampior2026');
    await _blur(tester);
    await _scrollToTop(tester);
    await _capture(tester, '11_register_filled');

    await _tapKey(tester, 'register.submit', settle: false);
    await _finishRequest(tester);
    await _capture(tester, '12_register_success');
  });

  testWidgets('duplicate email', (tester) async {
    await _pumpApp(tester, onboardingSeen: true);
    await _tapText(tester, 'Create one');
    await _enter(tester, 'register.name', 'Demo User');
    await _enter(tester, 'register.email', AppDatabase.demoEmail);
    await _enter(tester, 'register.mobile', '701234567');
    await _enter(tester, 'register.password', 'abcdefg1');
    await _enter(tester, 'register.confirm', 'abcdefg1');
    await _blur(tester);
    await _tapKey(tester, 'register.submit', settle: false);
    await _finishRequest(tester);
    await _capture(tester, '13_register_duplicate_email');
  });

  testWidgets('forgot password', (tester) async {
    await _pumpApp(tester, onboardingSeen: true);
    await _enter(tester, 'login.identifier', AppDatabase.demoEmail);
    await _tapText(tester, 'Forgot password?');
    await _tapKey(tester, 'forgot.submit', settle: false);
    await _finishRequest(tester);
    await _capture(tester, '14_forgot_password_sent');
  });

  testWidgets('responsive', (tester) async {
    await _pumpApp(tester, onboardingSeen: true, size: const Size(1280, 860));
    await _capture(tester, '15_tablet_desktop_login');

    await _pumpApp(tester, onboardingSeen: true, size: const Size(320, 568));
    await _tapText(tester, 'Create one');
    await _tapKey(tester, 'register.submit');
    await _scrollToTop(tester);
    await _capture(tester, '16_small_phone_register_validation');
    addTearDown(tester.view.reset);
  });
}
