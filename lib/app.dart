import 'dart:async';

import 'package:flutter/material.dart';

import 'core/auth/session_events.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/status_banner.dart';

/// Root widget. Expects `configureDependencies()` to have run.
class VampiorApp extends StatefulWidget {
  const VampiorApp({super.key});

  @override
  State<VampiorApp> createState() => _VampiorAppState();
}

class _VampiorAppState extends State<VampiorApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _sessionSub;

  @override
  void initState() {
    super.initState();
    // The refresh token was rejected deep in the network layer: send the
    // user back to Login from wherever they are.
    _sessionSub = sl<SessionEvents>().onSessionExpired.listen((_) {
      final nav = _navigatorKey.currentState;
      if (nav == null || !nav.mounted) return;
      nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      AppSnackbar.show(nav.context, 'Session expired, please log in again', tone: StatusTone.error);
    });
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vampior',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // StartupPage picks Onboarding (first launch), Home (session restored)
      // or Login.
      initialRoute: AppRoutes.startup,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: (name) => [AppRouter.onGenerateRoute(RouteSettings(name: name))],
    );
  }
}
