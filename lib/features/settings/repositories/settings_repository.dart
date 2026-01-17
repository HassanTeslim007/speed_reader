import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reader/core/constants/app_constants.dart';
import 'package:speed_reader/features/settings/models/app_settings.dart';

/// Repository for settings persistence
class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Get app settings
  AppSettings getSettings() {
    final jsonString = _prefs.getString(AppConstants.keyThemeMode);
    if (jsonString == null) return const AppSettings();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      return const AppSettings();
    }
  }

  /// Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(
      AppConstants.keyThemeMode,
      jsonEncode(settings.toJson()),
    );
  }

  /// Reset settings to default
  Future<void> resetSettings() async {
    await _prefs.remove(AppConstants.keyThemeMode);
  }
}
