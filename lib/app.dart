import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class VampiorApp extends StatelessWidget {
  const VampiorApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: dependencies.providers,
      child: MaterialApp(
        title: 'Vampior',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // Onboarding only on first launch; afterwards the app opens on Login.
        initialRoute: dependencies.onboardingSeen ? AppRoutes.login : AppRoutes.onboarding,
        onGenerateRoute: AppRouter.onGenerateRoute,
        // initialRoute '/login' would otherwise also push '/' underneath.
        onGenerateInitialRoutes: (name) => [AppRouter.onGenerateRoute(RouteSettings(name: name))],
      ),
    );
  }
}
