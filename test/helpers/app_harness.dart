import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vampiordesigns/app.dart';
import 'package:vampiordesigns/core/di/service_locator.dart';
import 'package:vampiordesigns/core/storage/preferences_data_source.dart';

import 'fakes.dart';

/// The fakes behind a pumped app, for assertions.
class AppHarness {
  AppHarness(this.prefs, this.users, this.sessions, this.tokens);
  final SharedPreferences prefs;
  final FakeUserStore users;
  final FakeSessionStore sessions;
  final InMemoryTokenStorage tokens;
}

const onboardingDone = {PreferencesDataSource.onboardingSeenKey: true};

/// Wires the real DI graph with in-memory fakes for storage, then pumps
/// [VampiorApp]. Pair it with `tearDown(resetDependencies)`.
Future<AppHarness> pumpVampiorApp(
  WidgetTester tester, {
  Map<String, Object> prefs = onboardingDone,
  SharedPreferences? prefsInstance,
  FakeUserStore? users,
  FakeSessionStore? sessions,
  InMemoryTokenStorage? tokens,
  Duration apiLatency = const Duration(milliseconds: 300),
  Widget Function(Widget app)? wrap,
}) async {
  await resetDependencies();
  if (prefsInstance == null) {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(prefs);
  }
  final harness = AppHarness(
    prefsInstance ?? await SharedPreferences.getInstance(),
    users ?? FakeUserStore(),
    sessions ?? FakeSessionStore(),
    tokens ?? InMemoryTokenStorage(),
  );
  await configureDependencies(
    DependencyOverrides(
      prefs: harness.prefs,
      userStore: harness.users,
      sessionStore: harness.sessions,
      tokenStorage: harness.tokens,
      apiLatency: apiLatency,
    ),
  );
  const app = VampiorApp();
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  await tester.pumpAndSettle();
  return harness;
}
