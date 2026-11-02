import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/validation/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/password_strength_meter.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/shake.dart';
import '../../../../shared/widgets/status_banner.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _focus = List.generate(5, (_) => FocusNode());
  final _shakeKey = GlobalKey<ShakeState>();

  String get _mobileDigits => LkMobile.parse(_mobile.text);
  String? _validateMobile(String? v) => Validators.mobile(LkMobile.parse(v ?? ''));
  String? _validateConfirm(String? v) => Validators.confirmPassword(v, _password.text);

  @override
  void initState() {
    super.initState();
    // Re-check "confirm" whenever the password changes.
    _password.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _password.removeListener(_onPasswordChanged);
    for (final c in [_name, _email, _mobile, _password, _confirm]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<RegisterController>();
    if (controller.isLoading) return;
    controller.markSubmitted();

    final errors = [
      Validators.fullName(_name.text),
      Validators.email(_email.text),
      _validateMobile(_mobile.text),
      Validators.newPassword(_password.text),
      _validateConfirm(_confirm.text),
    ];
    final firstInvalid = errors.indexWhere((e) => e != null);
    if (firstInvalid != -1) {
      _shakeKey.currentState?.shake();
      _focus[firstInvalid].requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext();
    final session = await controller.register(
      fullName: _name.text,
      email: _email.text,
      mobileDigits: _mobileDigits,
      password: _password.text,
    );
    if (!mounted) return;

    if (session == null) {
      AppSnackbar.show(context, controller.errorMessage ?? 'Registration failed', tone: StatusTone.error);
      return;
    }
    final user = session.user;
    AppSnackbar.show(context, 'Account created successfully');
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.success,
      (_) => false,
      arguments: SuccessArgs(
        title: 'Account created',
        body: 'Welcome, ${user.firstName}. Your account is ready.',
        rows: [
          ('Name', user.fullName),
          ('Email', user.email),
          ('Mobile', LkMobile.international(user.mobile)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegisterController>();
    final force = controller.submitted;

    return AuthScaffold(
      title: 'Create account',
      subtitle: 'It takes less than a minute.',
      onBack: () => Navigator.of(context).maybePop(),
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
                    fieldKey: const Key('register.name'),
                    controller: _name,
                    focusNode: _focus[0],
                    label: 'Full name',
                    placeholder: 'Jane Doe',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.fullName,
                    forceValidation: force,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    fieldKey: const Key('register.email'),
                    controller: _email,
                    focusNode: _focus[1],
                    label: 'Email address',
                    placeholder: 'you@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    forceValidation: force,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    fieldKey: const Key('register.mobile'),
                    controller: _mobile,
                    focusNode: _focus[2],
                    label: 'Mobile number',
                    placeholder: '77 123 4567',
                    icon: Icons.smartphone,
                    prefixText: LkMobile.prefix,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [LkMobileInputFormatter()],
                    maxLength: 11,
                    validator: _validateMobile,
                    forceValidation: force,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    fieldKey: const Key('register.password'),
                    controller: _password,
                    focusNode: _focus[3],
                    label: 'Password',
                    placeholder: 'Create a password',
                    hint: '8+ characters with letters and a number',
                    icon: Icons.lock_outline,
                    obscurable: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                    forceValidation: force,
                    below: PasswordStrengthMeter(controller: _password),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    fieldKey: const Key('register.confirm'),
                    controller: _confirm,
                    focusNode: _focus[4],
                    label: 'Confirm password',
                    placeholder: 'Re-enter password',
                    icon: Icons.lock_outline,
                    obscurable: true,
                    textInputAction: TextInputAction.go,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _validateConfirm,
                    forceValidation: force,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 8),
              StatusBanner(message: controller.errorMessage!, tone: StatusTone.error),
            ],
          ],
        ),
      ),
      cta: PrimaryButton(
        key: const Key('register.submit'),
        label: 'Create account',
        loadingLabel: 'Creating account…',
        loading: controller.isLoading,
        onPressed: _submit,
      ),
      footer: FooterPrompt(
        text: 'Already have an account?',
        linkLabel: 'Log in',
        onTap: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
