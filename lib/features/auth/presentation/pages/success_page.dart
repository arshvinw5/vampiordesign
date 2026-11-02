import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_text_link.dart';
import '../../../../shared/widgets/responsive_frame.dart';
import '../../../../shared/widgets/secondary_button.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../controllers/home_controller.dart';
import '../widgets/success_badge.dart';

/// Signed-in screen. The header comes from the flow that got here
/// ([SuccessArgs]); the profile is loaded live from the protected
/// `/auth/me` endpoint via [HomeController], which proves the stored
/// access token (and its silent refresh) works.
class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key, required this.args});
  final SuccessArgs args;

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeController>().load();
    });
  }

  void _leave(String route) {
    // Don't let the "Welcome back" toast follow us onto the next screen.
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'Your session will end on this device and you\u2019ll need to sign in again.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay signed in',
      destructive: true,
      icon: Icons.logout,
    );
    if (!confirmed || !mounted) return;
    await context.read<HomeController>().logout();
    if (mounted) _leave(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final args = widget.args;
    final session = home.session;
    final rows = <(String, String)>[
      ...args.rows,
      if (session != null) ...[
        ('Name', session.user.fullName),
        ('Email', session.user.email),
        ('Mobile', LkMobile.international(session.user.mobile)),
        (
          'Access token',
          home.accessSecondsLeft > 0
              ? 'Expires in ${home.accessSecondsLeft}s'
              : 'Expired \u00b7 refreshes on next request',
        ),
        ('Refresh token', 'Stored in secure storage'),
      ],
    ];

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
                      constraints: BoxConstraints(
                        minHeight: (c.maxHeight - 40).clamp(0, double.infinity),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SuccessBadge(),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(args.title, style: AppTextStyles.title),
                          ),
                          const SizedBox(height: 8),
                          Text(args.body, style: AppTextStyles.body),
                          const SizedBox(height: 24),
                          const Divider(height: 2, thickness: 2, color: AppColors.pale),
                          for (final (i, row) in rows.indexed)
                            _SummaryRow(
                              key: ValueKey(row.$1),
                              label: row.$1,
                              value: row.$2,
                              delay: 200 + i * 60,
                            ),
                          if (home.isLoading && session == null) const _LoadingRow(),
                          if (home.failure != null) ...[
                            const SizedBox(height: 16),
                            StatusBanner(
                              key: const Key('success.error'),
                              message: home.failure!.message,
                              tone: StatusTone.error,
                            ),
                          ],
                          const SizedBox(height: 8),
                          AppTextLink(
                            key: const Key('success.refresh'),
                            label: home.isLoading ? 'Refreshing\u2026' : 'Refresh profile',
                            onPressed: home.isLoading ? null : home.load,
                          ),
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
                      label: home.loggingOut ? 'Logging out\u2026' : 'Log out',
                      onPressed: home.loggingOut ? null : _logout,
                    ),
                    const SizedBox(height: 8),
                    AppTextLink(
                      label: 'Replay onboarding',
                      color: AppColors.ink64,
                      hoverColor: AppColors.navy,
                      onPressed: () => _leave(AppRoutes.onboarding),
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

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
          ),
          SizedBox(width: 12),
          Text('Loading your profile\u2026', style: AppTextStyles.secondary),
        ],
      ),
    );
  }
}

/// Label/value row that rises 8px into place after [delay] ms.
class _SummaryRow extends StatefulWidget {
  const _SummaryRow({super.key, required this.label, required this.value, required this.delay});
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
                child: Text(widget.value, textAlign: TextAlign.right, style: AppTextStyles.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
