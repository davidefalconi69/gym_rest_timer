import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';

/// Repository for persisting and loading user settings using SharedPreferences.
///
/// This provides a clean abstraction over the storage mechanism.
/// If we ever want to switch to Hive or another solution, we only change this file.
class SettingsRepository {
  // SharedPreferences keys
  static const _keyDefaultDuration = 'default_duration_seconds';
  static const _keyThemeMode = 'theme_mode';
  static const _keyAccentColor = 'accent_color';
  static const _keyMonochromeAccent = 'monochrome_accent';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyVibrateInSilentMode = 'vibrate_in_silent_mode';
  static const _keySoundPath = 'sound_path';
  static const _keyLocale = 'locale';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Load settings from SharedPreferences.
  /// Returns Settings.initial() for any missing values.
  Settings loadSettings() {
    final defaultDuration = _prefs.getInt(_keyDefaultDuration) ?? 90;

    final themeModeIndex = _prefs.getInt(_keyThemeMode);
    final themeMode = themeModeIndex != null
        ? AppThemeMode.values[themeModeIndex.clamp(
            0,
            AppThemeMode.values.length - 1,
          )]
        : AppThemeMode.system;

    final accentColorValue = _prefs.getInt(_keyAccentColor);
    final accentColor = accentColorValue != null
        ? Color(accentColorValue)
        : null;

    final monochromeAccent = _prefs.getBool(_keyMonochromeAccent) ?? false;

    final soundEnabled = _prefs.getBool(_keySoundEnabled) ?? true;
    final vibrationEnabled = _prefs.getBool(_keyVibrationEnabled) ?? true;
    final vibrateInSilentMode =
        _prefs.getBool(_keyVibrateInSilentMode) ?? false;
    final soundPath = _prefs.getString(_keySoundPath) ?? 'default';

    final localeCode = _prefs.getString(_keyLocale);
    final locale = localeCode != null ? Locale(localeCode) : null;

    return Settings(
      defaultDurationSeconds: defaultDuration,
      themeMode: themeMode,
      accentColor: accentColor,
      monochromeAccent: monochromeAccent,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      vibrateInSilentMode: vibrateInSilentMode,
      soundPath: soundPath,
      locale: locale,
    );
  }

  /// Save settings to SharedPreferences.
  Future<void> saveSettings(Settings settings) async {
    await _prefs.setInt(_keyDefaultDuration, settings.defaultDurationSeconds);
    await _prefs.setInt(_keyThemeMode, settings.themeMode.index);

    if (settings.accentColor != null) {
      await _prefs.setInt(_keyAccentColor, settings.accentColor!.toARGB32());
    } else {
      await _prefs.remove(_keyAccentColor);
    }

    await _prefs.setBool(_keyMonochromeAccent, settings.monochromeAccent);

    await _prefs.setBool(_keySoundEnabled, settings.soundEnabled);
    await _prefs.setBool(_keyVibrationEnabled, settings.vibrationEnabled);
    await _prefs.setBool(_keyVibrateInSilentMode, settings.vibrateInSilentMode);
    await _prefs.setString(_keySoundPath, settings.soundPath);

    if (settings.locale != null) {
      await _prefs.setString(_keyLocale, settings.locale!.languageCode);
    } else {
      await _prefs.remove(_keyLocale);
    }
  }

  /// Update just the default duration.
  Future<void> saveDefaultDuration(int seconds) async {
    await _prefs.setInt(_keyDefaultDuration, seconds);
  }

  /// Update just the theme mode.
  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, mode.index);
  }

  /// Update just the accent color.
  Future<void> saveAccentColor(Color? color) async {
    if (color != null) {
      await _prefs.setInt(_keyAccentColor, color.toARGB32());
    } else {
      await _prefs.remove(_keyAccentColor);
    }
  }

  /// Update just the monochrome accent flag.
  Future<void> saveMonochromeAccent(bool enabled) async {
    await _prefs.setBool(_keyMonochromeAccent, enabled);
  }

  /// Update sound enabled setting.
  Future<void> saveSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keySoundEnabled, enabled);
  }

  /// Update vibration enabled setting.
  Future<void> saveVibrationEnabled(bool enabled) async {
    await _prefs.setBool(_keyVibrationEnabled, enabled);
  }

  /// Update vibrate in silent mode setting.
  Future<void> saveVibrateInSilentMode(bool enabled) async {
    await _prefs.setBool(_keyVibrateInSilentMode, enabled);
  }

  /// Update sound path setting.
  Future<void> saveSoundPath(String soundPath) async {
    await _prefs.setString(_keySoundPath, soundPath);
  }

  /// Update locale setting.
  Future<void> saveLocale(Locale? locale) async {
    if (locale != null) {
      await _prefs.setString(_keyLocale, locale.languageCode);
    } else {
      await _prefs.remove(_keyLocale);
    }
  }
}
