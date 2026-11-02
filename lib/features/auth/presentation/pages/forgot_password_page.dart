import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/validation/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_text_link.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/shake.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialIdentifier});

  final String? initialIdentifier;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final _identifier = TextEditingController(text: widget.initialIdentifier);
  final _focus = FocusNode();
  final _shakeKey = GlobalKey<ShakeState>();
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _lastText = _identifier.text;
    _identifier.addListener(_onChanged);
  }

  void _onChanged() {
    if (_identifier.text == _lastText) return; // ignore selection-only changes
    _lastText = _identifier.text;
    context.read<ForgotPasswordController>().onIdentifierChanged();
  }

  @override
  void dispose() {
    _identifier.removeListener(_onChanged);
    _identifier.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<ForgotPasswordController>();
    if (controller.isLoading) return;
    controller.markSubmitted();
    if (Validators.identifier(_identifier.text) != null) {
      _shakeKey.currentState?.shake();
      _focus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    // Success and failure are both shown inline (StatusBanner).
    await controller.send(_identifier.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ForgotPasswordController>();

    return AuthScaffold(
      title: 'Reset password',
      subtitle: 'Enter your email or mobile number and we’ll send you a reset link.',
      onBack: () => Navigator.of(context).maybePop(),
      loading: controller.isLoading,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Shake(
            key: _shakeKey,
            child: AppTextField(
              fieldKey: const Key('forgot.identifier'),
              controller: _identifier,
              focusNode: _focus,
              label: 'Email or mobile number',
              placeholder: 'you@example.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.go,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              validator: Validators.identifier,
              forceValidation: controller.submitted,
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (controller.sentTo != null)
            StatusBanner(
              key: const Key('forgot.sent'),
              message: 'Reset link sent to ${controller.sentTo}. It may take a minute to arrive.',
              footer: controller.cooldown > 0
                  ? Text(
                      'Resend available in ${controller.cooldown}s',
                      style: AppTextStyles.meta.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : AppTextLink(
                      label: 'Resend link',
                      onPressed: controller.canResend
                          ? () => controller.send(controller.sentTo!)
                          : null,
                    ),
            )
          else if (controller.errorMessage != null)
            StatusBanner(message: controller.errorMessage!, tone: StatusTone.error),
        ],
      ),
      cta: PrimaryButton(
        key: const Key('forgot.submit'),
        label: 'Send reset link',
        loadingLabel: 'Sending…',
        loading: controller.isLoading,
        onPressed: _submit,
      ),
      footer: FooterPrompt(
        text: 'Remembered it?',
        linkLabel: 'Back to log in',
        onTap: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
