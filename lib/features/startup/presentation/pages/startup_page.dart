import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../../shared/widgets/responsive_frame.dart';
import '../controllers/startup_controller.dart';

/// Launch screen shown while [StartupController] decides where to go
/// (it may call `/auth/me` and `/auth/refresh` to restore the session).
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final decision = await context.read<StartupController>().decide();
    if (!mounted) return;
    final nav = Navigator.of(context);
    switch (decision.destination) {
      case StartupDestination.onboarding:
        nav.pushNamedAndRemoveUntil(AppRoutes.onboarding, (_) => false);
      case StartupDestination.login:
        nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      case StartupDestination.home:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.success,
          (_) => false,
          arguments: SuccessArgs(
            title: 'Welcome back',
            body: decision.session != null
                ? 'You’re still signed in from your last session.'
                : 'You’re signed in. We couldn’t refresh your profile just now.',
            rows: const [],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ice,
      body: ResponsiveFrame(
        child: Semantics(
          label: 'Loading',
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(),
                SizedBox(height: 24),
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                ),
                SizedBox(height: 16),
                Text('Checking your session…', style: AppTextStyles.meta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
