import 'package:flutter/foundation.dart';
import 'package:speed_reader/features/settings/models/app_settings.dart';
import 'package:speed_reader/features/settings/repositories/settings_repository.dart';

/// Settings notifier using ChangeNotifier
class SettingsNotifier extends ChangeNotifier {
  final SettingsRepository _repository;
  AppSettings _state = const AppSettings();

  SettingsNotifier(this._repository) {
    _loadSettings();
  }

  AppSettings get state => _state;

  void _loadSettings() {
    _state = _repository.getSettings();
    notifyListeners();
  }

  Future<void> updateThemeMode(themeMode) async {
    _state = _state.copyWith(themeMode: themeMode);
    await _repository.saveSettings(_state);
    notifyListeners();
  }

  Future<void> updateAutoSaveProgress(bool value) async {
    _state = _state.copyWith(autoSaveProgress: value);
    await _repository.saveSettings(_state);
    notifyListeners();
  }

  Future<void> updateShowPageNumbers(bool value) async {
    _state = _state.copyWith(showPageNumbers: value);
    await _repository.saveSettings(_state);
    notifyListeners();
  }

  Future<void> updateDefaultZoom(double value) async {
    _state = _state.copyWith(defaultZoom: value);
    await _repository.saveSettings(_state);
    notifyListeners();
  }

  Future<void> resetSettings() async {
    await _repository.resetSettings();
    _state = const AppSettings();
    notifyListeners();
  }
}
