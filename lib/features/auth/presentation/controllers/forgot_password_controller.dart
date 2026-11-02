import 'dart:async';

import '../../../../core/presentation/form_controller.dart';
import '../../domain/usecases/request_password_reset.dart';

class ForgotPasswordController extends FormController {
  ForgotPasswordController({
    required this._requestReset,
    this.cooldownSeconds = 30,
  });

  final RequestPasswordReset _requestReset;
  final int cooldownSeconds;

  String? _sentTo;

  /// Identifier the last reset link was sent to; `null` hides the notice.
  String? get sentTo => _sentTo;

  int _cooldown = 0;
  int get cooldown => _cooldown;
  bool get canResend => _sentTo != null && _cooldown == 0 && !isLoading;

  Timer? _timer;

  Future<bool> send(String identifier) async {
    final id = identifier.trim();
    final result = await run(() => _requestReset(id));
    final ok = result?.isRight() ?? false;
    if (ok) {
      _sentTo = id;
      _startCooldown();
    }
    notifyListeners();
    return ok;
  }

  /// Editing the identifier hides the "sent" notice.
  void onIdentifierChanged() {
    if (_sentTo == null && failure == null) return;
    _sentTo = null;
    _timer?.cancel();
    _cooldown = 0;
    clearError();
    notifyListeners();
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _cooldown = (_cooldown - 1).clamp(0, cooldownSeconds);
      if (_cooldown == 0) t.cancel();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
