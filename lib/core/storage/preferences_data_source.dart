import 'package:shared_preferences/shared_preferences.dart';

import '../error/exceptions.dart';

/// Small key-value flags kept in shared_preferences.
class PreferencesDataSource {
  PreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const onboardingSeenKey = 'vampior.onboardingSeen';
  static const rememberedIdKey = 'vampior.rememberedId';

  bool get onboardingSeen => _prefs.getBool(onboardingSeenKey) ?? false;

  Future<void> setOnboardingSeen() => _guard(() => _prefs.setBool(onboardingSeenKey, true));

  String? get rememberedIdentifier => _prefs.getString(rememberedIdKey);

  Future<void> setRememberedIdentifier(String? id) => _guard(
        () => id == null || id.isEmpty
            ? _prefs.remove(rememberedIdKey)
            : _prefs.setString(rememberedIdKey, id),
      );

  Future<void> _guard(Future<bool> Function() write) async {
    final ok = await write();
    if (!ok) throw const CacheException();
  }
}
