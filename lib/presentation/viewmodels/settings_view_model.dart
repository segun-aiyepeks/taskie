import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _keyName = 'user_name';
  static const _keyTheme = 'theme_mode';
  static const _keyOnboard = 'has_seen_onboarding';
  static const _keyTutorial = 'has_seen_tutorial';

  final SharedPreferences _prefs;

  SettingsViewModel(this._prefs);

  String? get userName => _prefs.getString(_keyName);
  bool get hasSeenOnboarding => _prefs.getBool(_keyOnboard) ?? false;
  bool get hasSeenTutorial => _prefs.getBool(_keyTutorial) ?? false;

  ThemeMode get themeMode {
    final value = _prefs.getString(_keyTheme);
    return switch(value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _    => ThemeMode.system
     };
  }

  //If no name is set
  String get displayName {
    final name = userName;
    return (name == null || name.isEmpty)? 'there': name;
  }

  //Avatar Bubble
  String get initials {
    final name = userName;
    if(name == null || name.isEmpty)return '?';
    return name.trim()[0].toUpperCase();
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyName, name.trim());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch(mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system'
    };
    await _prefs.setString(_keyTheme, value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboard, true);
    notifyListeners();
  }

  Future<void> completeTutorial() async {
  await _prefs.setBool(_keyTutorial, true);
  notifyListeners();
  }
}