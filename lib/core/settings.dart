import 'package:flutter/material.dart';

/// App-specific theme modes including AMOLED.
enum AppThemeMode { system, light, dark, amoled }

/// Immutable settings model for the Gym Rest Timer app.
///
/// Stores:
/// - Default timer duration in seconds
/// - Theme mode (light/dark/amoled/system)
/// - Custom accent color (null means use default teal)
/// - Monochrome accent flag
/// - Notification settings (sound, vibration, silent mode behavior)
class Settings {
  /// Default timer duration in seconds (e.g., 90 = 1:30)
  final int defaultDurationSeconds;

  /// Theme mode preference
  final AppThemeMode themeMode;

  /// Custom accent color for the app theme.
  /// If null and [monochromeAccent] is false, uses the default primary color (teal).
  final Color? accentColor;

  /// Whether to use monochrome (B&W) accent colors.
  /// Overrides [accentColor] if true.
  final bool monochromeAccent;

  /// Whether sound is enabled when timer completes.
  final bool soundEnabled;

  /// Whether vibration is enabled when timer completes.
  final bool vibrationEnabled;

  /// Whether to vibrate even when device is in silent/DND mode.
  final bool vibrateInSilentMode;

  /// Path to the sound file to play.
  /// - 'default': uses the bundled assets/sounds/beep.mp3
  /// - Custom path: user-selected file from device storage
  final String soundPath;

  /// Locale preference.
  /// - null: System Default
  /// - Locale('en'): English
  /// - Locale('it'): Italian
  final Locale? locale;

  const Settings({
    required this.defaultDurationSeconds,
    required this.themeMode,
    this.accentColor,
    this.monochromeAccent = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.vibrateInSilentMode = false,
    this.soundPath = 'default',
    this.locale,
  });

  /// Factory for initial/default settings.
  /// 90 seconds is a common gym rest time.
  factory Settings.initial() {
    return const Settings(
      defaultDurationSeconds: 90,
      themeMode: AppThemeMode.system,
      accentColor: null,
      monochromeAccent: false,
      soundEnabled: true,
      vibrationEnabled: true,
      vibrateInSilentMode: false,
      soundPath: 'default',
      locale: null,
    );
  }

  /// Create a copy with some fields changed - immutability pattern.
  Settings copyWith({
    int? defaultDurationSeconds,
    AppThemeMode? themeMode,
    Color? accentColor,
    bool clearAccentColor = false,
    bool? monochromeAccent,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? vibrateInSilentMode,
    String? soundPath,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return Settings(
      defaultDurationSeconds:
          defaultDurationSeconds ?? this.defaultDurationSeconds,
      themeMode: themeMode ?? this.themeMode,
      accentColor: clearAccentColor ? null : (accentColor ?? this.accentColor),
      monochromeAccent: monochromeAccent ?? this.monochromeAccent,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      vibrateInSilentMode: vibrateInSilentMode ?? this.vibrateInSilentMode,
      soundPath: soundPath ?? this.soundPath,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  /// Format the default duration as MM:SS for display.
  String get formattedDefaultDuration {
    final minutes = (defaultDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (defaultDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settings &&
        other.defaultDurationSeconds == defaultDurationSeconds &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.monochromeAccent == monochromeAccent &&
        other.soundEnabled == soundEnabled &&
        other.vibrationEnabled == vibrationEnabled &&
        other.vibrateInSilentMode == vibrateInSilentMode &&
        other.soundPath == soundPath &&
        other.locale == locale;
  }

  @override
  int get hashCode =>
      defaultDurationSeconds.hashCode ^
      themeMode.hashCode ^
      accentColor.hashCode ^
      monochromeAccent.hashCode ^
      soundEnabled.hashCode ^
      vibrationEnabled.hashCode ^
      vibrateInSilentMode.hashCode ^
      soundPath.hashCode ^
      locale.hashCode;
}
