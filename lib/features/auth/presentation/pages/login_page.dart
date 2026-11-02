import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/validation/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/shake.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/remember_forgot_row.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _identifier;
  final _password = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _shakeKey = GlobalKey<ShakeState>();

  @override
  void initState() {
    super.initState();
    _identifier = TextEditingController(text: context.read<LoginController>().initialIdentifier);
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<LoginController>();
    if (controller.isLoading) return;
    controller.markSubmitted();

    final checks = [
      (_identifierFocus, Validators.identifier(_identifier.text)),
      (_passwordFocus, Validators.loginPassword(_password.text)),
    ];
    final firstInvalid = checks.where((c) => c.$2 != null).firstOrNull;
    if (firstInvalid != null) {
      _shakeKey.currentState?.shake();
      firstInvalid.$1.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext();
    final session = await controller.login(identifier: _identifier.text, password: _password.text);
    if (!mounted) return;

    if (session == null) {
      AppSnackbar.show(context, controller.errorMessage ?? 'Login failed', tone: StatusTone.error);
      return;
    }
    final id = _identifier.text.trim();
    AppSnackbar.show(context, 'Welcome back, ${session.user.firstName}!');
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.success,
      (_) => false,
      arguments: SuccessArgs(
        title: 'Welcome back',
        body: 'You’re signed in and ready to go.',
        rows: [
          ('Account', id),
          ('Name', session.user.fullName),
          ('Mobile', LkMobile.international(session.user.mobile)),
          ('Remember me', controller.rememberMe ? 'On' : 'Off'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final force = controller.submitted;

    return AuthScaffold(
      title: 'Log in',
      subtitle: 'Welcome back. Enter your details to continue.',
      loading: controller.isLoading,
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Shake(
              key: _shakeKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    fieldKey: const Key('login.identifier'),
                    controller: _identifier,
                    focusNode: _identifierFocus,
                    label: 'Email or mobile number',
                    placeholder: 'you@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    validator: Validators.identifier,
                    forceValidation: force,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    fieldKey: const Key('login.password'),
                    controller: _password,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    placeholder: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscurable: true,
                    textInputAction: TextInputAction.go,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.loginPassword,
                    forceValidation: force,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            RememberForgotRow(
              rememberMe: controller.rememberMe,
              onRememberChanged: controller.setRememberMe,
              onForgot: () => Navigator.of(context)
                  .pushNamed(AppRoutes.forgotPassword, arguments: _identifier.text.trim()),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              StatusBanner(message: controller.errorMessage!, tone: StatusTone.error),
            ],
          ],
        ),
      ),
      cta: PrimaryButton(
        key: const Key('login.submit'),
        label: 'Log in',
        loadingLabel: 'Logging in…',
        loading: controller.isLoading,
        onPressed: _submit,
      ),
      footer: FooterPrompt(
        text: 'No account?',
        linkLabel: 'Create one',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.register),
      ),
    );
  }
}
