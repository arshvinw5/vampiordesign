import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_link.dart';
import '../../../../shared/widgets/responsive_frame.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../widgets/success_badge.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key, required this.args});
  final SuccessArgs args;

  void _leave(BuildContext context, String route) {
    // Don't let the "Welcome back" snackbar follow us onto the next screen.
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  void _logout(BuildContext context) => _leave(context, AppRoutes.login);

  void _replayOnboarding(BuildContext context) => _leave(context, AppRoutes.onboarding);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Back from Success would re-enter the auth form.
      child: Scaffold(
        backgroundColor: AppColors.ice,
        body: ResponsiveFrame(
          child: Column(
            children: [
              const AppTopBar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: (c.maxHeight - 40).clamp(0, double.infinity)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SuccessBadge(),
                          const SizedBox(height: 24),
                          Semantics(header: true, child: Text(args.title, style: AppTextStyles.title)),
                          const SizedBox(height: 8),
                          Text(args.body, style: AppTextStyles.body),
                          const SizedBox(height: 24),
                          const Divider(height: 2, thickness: 2, color: AppColors.pale),
                          for (final (i, row) in args.rows.indexed)
                            _SummaryRow(label: row.$1, value: row.$2, delay: 200 + i * 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.pale, width: 2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SecondaryButton(
                      key: const Key('success.logout'),
                      label: 'Log out',
                      onPressed: () => _logout(context),
                    ),
                    const SizedBox(height: 8),
                    AppTextLink(
                      label: 'Replay onboarding',
                      color: AppColors.ink64,
                      hoverColor: AppColors.navy,
                      onPressed: () => _replayOnboarding(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label/value row that rises 8px into place after [delay] ms.
class _SummaryRow extends StatefulWidget {
  const _SummaryRow({required this.label, required this.value, required this.delay});
  final String label;
  final String value;
  final int delay;

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 280),
      curve: AppMotion.easeOut,
      child: AnimatedSlide(
        offset: _shown || reduced ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 280),
        curve: AppMotion.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.pale, width: 2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: AppTextStyles.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
