import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';
import 'settings_repository.dart';
import 'services/background_service.dart';

/// Provider for SharedPreferences instance.
/// Must be overridden at app startup with the actual instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in ProviderScope',
  );
});

/// Provider for the SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

/// The main settings provider - AsyncNotifier pattern for robust loading.
///
/// This handles:
/// - Async loading of settings on app startup
/// - Immediate updates when settings change
/// - Persistence to SharedPreferences
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

/// Notifier that manages settings state and persistence.
class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() async {
    // Load settings from SharedPreferences
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.loadSettings();
  }

  /// Update the default timer duration.
  Future<void> setDefaultDuration(int seconds) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    // Clamp to reasonable values (1 second to 99 minutes 59 seconds)
    final clampedSeconds = seconds.clamp(1, 5999);

    final newSettings = currentSettings.copyWith(
      defaultDurationSeconds: clampedSeconds,
    );

    // Update state immediately for responsive UI
    state = AsyncData(newSettings);

    // Persist in background
    await repository.saveDefaultDuration(clampedSeconds);

    // CRITICAL: Sync to background service immediately!
    // This ensures the running service always has the latest duration.
    BackgroundTimerService.instance.updateDuration(clampedSeconds);
  }

  /// Update the theme mode.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = currentSettings.copyWith(themeMode: mode);

    // Update state immediately for responsive UI
    state = AsyncData(newSettings);

    // Persist in background
    await repository.saveThemeMode(mode);
  }

  /// Update the accent color.
  Future<void> setAccentColor(Color? color) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = color != null
        ? currentSettings.copyWith(
            accentColor: color,
            monochromeAccent: false, // Disable monochrome if custom color set
          )
        : currentSettings.copyWith(
            clearAccentColor: true,
            // Don't disable monochrome here, let explicit toggle handle it
            // or if "Use Default" is clicked, we might want to disable monochrome too.
            // Let's assume clearAccentColor is "Use Default", so we should disable monochrome.
            monochromeAccent: false,
          );

    // Update state immediately for responsive UI
    state = AsyncData(newSettings);

    // Persist in background
    await repository.saveAccentColor(color);
    await repository.saveMonochromeAccent(false);
  }

  /// Update monochrome accent setting.
  Future<void> setMonochromeAccent(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    // If enabling monochrome, we ignore accent color (UI handles this via provider)
    // but in model, monochromeAccent takes precedence.
    final newSettings = currentSettings.copyWith(monochromeAccent: enabled);

    state = AsyncData(newSettings);
    await repository.saveMonochromeAccent(enabled);
  }

  /// Update sound enabled setting.
  Future<void> setSoundEnabled(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = currentSettings.copyWith(soundEnabled: enabled);

    state = AsyncData(newSettings);
    await repository.saveSoundEnabled(enabled);
  }

  /// Update vibration enabled setting.
  Future<void> setVibrationEnabled(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = currentSettings.copyWith(vibrationEnabled: enabled);

    state = AsyncData(newSettings);
    await repository.saveVibrationEnabled(enabled);
  }

  /// Update vibrate in silent mode setting.
  Future<void> setVibrateInSilentMode(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = currentSettings.copyWith(vibrateInSilentMode: enabled);

    state = AsyncData(newSettings);
    await repository.saveVibrateInSilentMode(enabled);
  }

  /// Update sound path setting.
  Future<void> setSoundPath(String soundPath) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = currentSettings.copyWith(soundPath: soundPath);

    state = AsyncData(newSettings);
    await repository.saveSoundPath(soundPath);
  }

  /// Update locale setting.
  Future<void> setLocale(Locale? locale) async {
    final repository = ref.read(settingsRepositoryProvider);
    final currentSettings = state.value ?? Settings.initial();

    final newSettings = locale != null
        ? currentSettings.copyWith(locale: locale)
        : currentSettings.copyWith(clearLocale: true);

    state = AsyncData(newSettings);
    await repository.saveLocale(locale);

    // Sync language to background service for localized notifications
    // Use 'en' as fallback when locale is null (system default)
    final langCode = locale?.languageCode ?? 'en';
    BackgroundTimerService.instance.syncLanguage(langCode);
  }
}

/// Convenience provider for just the theme mode.
/// Useful for watching in MaterialApp without rebuilding on duration changes.
final themeModeProvider = Provider<AppThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.themeMode ?? AppThemeMode.system;
});

/// Convenience provider for just the accent color.
/// Null means use default color.
final accentColorProvider = Provider<Color?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.accentColor;
});

/// Convenience provider for monochrome accent flag.
final monochromeAccentProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.monochromeAccent ?? false;
});

/// Convenience provider for just the default duration.
final defaultDurationProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.defaultDurationSeconds ?? 90;
});

/// Convenience provider for sound enabled setting.
final soundEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.soundEnabled ?? true;
});

/// Convenience provider for vibration enabled setting.
final vibrationEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.vibrationEnabled ?? true;
});

/// Convenience provider for vibrate in silent mode setting.
final vibrateInSilentModeProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.vibrateInSilentMode ?? false;
});

/// Convenience provider for sound path setting.
final soundPathProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.soundPath ?? 'default';
});

/// Convenience provider for locale setting.
final localeProvider = Provider<Locale?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.value?.locale;
});
