import 'package:shared_preferences/shared_preferences.dart';

import '../error/exceptions.dart';

/// Small key-value flags kept in shared_preferences.
class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const onboardingSeenKey = 'vampior.onboardingSeen';
  static const rememberedIdKey = 'vampior.rememberedId';
  static const keepSignedInKey = 'vampior.keepSignedIn';

  bool get onboardingSeen => _prefs.getBool(onboardingSeenKey) ?? false;

  Future<void> setOnboardingSeen() => _guard(() => _prefs.setBool(onboardingSeenKey, true));

  String? get rememberedIdentifier => _prefs.getString(rememberedIdKey);

  Future<void> setRememberedIdentifier(String? id) => _guard(
    () => id == null || id.isEmpty
        ? _prefs.remove(rememberedIdKey)
        : _prefs.setString(rememberedIdKey, id),
  );

  /// The user's "Remember me" choice at sign-in. When `true`, the next
  /// launch restores the session from secure storage (auto-login).
  bool get keepSignedIn => _prefs.getBool(keepSignedInKey) ?? false;

  Future<void> setKeepSignedIn(bool value) => _guard(() => _prefs.setBool(keepSignedInKey, value));

  Future<void> _guard(Future<bool> Function() write) async {
    final ok = await write();
    if (!ok) throw const CacheException();
  }
}
