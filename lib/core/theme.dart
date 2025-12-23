import 'package:flutter/material.dart';

class AppTheme {
  // Default Brand Colors
  static const Color defaultPrimaryColor = Color(0xFF00D1C1); // Vibrant Teal
  static const Color secondaryColor = Color(0xFF2C3E50); // Deep Blue Grey

  /// Build light theme with optional custom accent color.
  static ThemeData buildLightTheme([
    Color? seedColor,
    bool isMonochrome = false,
  ]) {
    final effectiveSeed = seedColor ?? defaultPrimaryColor;

    // 1. Generate ColorScheme
    ColorScheme colorScheme;
    if (isMonochrome) {
      // Monochrome: Force grayscale
      colorScheme = const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFF424242),
        onSecondary: Colors.white,
        tertiary: Color(0xFF616161),
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    } else {
      // Standard: Generate from seed
      colorScheme = ColorScheme.fromSeed(
        seedColor: effectiveSeed,
        brightness: Brightness.light,
      ).copyWith(surface: Colors.white, onSurface: Colors.black);
    }

    // 2. Build Base Theme
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Outfit'),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );

    // 3. Apply Component Overrides
    return _applyComponentThemes(baseTheme, colorScheme);
  }

  /// Build dark theme with optional custom accent color.
  static ThemeData buildDarkTheme([
    Color? seedColor,
    bool isMonochrome = false,
  ]) {
    final effectiveSeed = seedColor ?? defaultPrimaryColor;

    // 1. Generate ColorScheme
    ColorScheme colorScheme;
    if (isMonochrome) {
      // Monochrome: Force grayscale (inverted for dark mode)
      colorScheme = const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Color(0xFFBDBDBD),
        onSecondary: Colors.black,
        tertiary: Color(0xFF9E9E9E),
        onTertiary: Colors.black,
        surface: Color(0xFF121212),
        onSurface: Colors.white,
      );
    } else {
      // Standard: Generate from seed
      colorScheme = ColorScheme.fromSeed(
        seedColor: effectiveSeed,
        brightness: Brightness.dark,
      ).copyWith(surface: const Color(0xFF121212), onSurface: Colors.white);
    }

    // 2. Build Base Theme
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Outfit'),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
    );

    // 3. Apply Component Overrides
    return _applyComponentThemes(baseTheme, colorScheme);
  }

  /// Build AMOLED theme (pure black background).
  static ThemeData buildAmoledTheme([
    Color? seedColor,
    bool isMonochrome = false,
  ]) {
    // Start with standard Dark Theme logic
    final baseTheme = buildDarkTheme(seedColor, isMonochrome);

    // Override background to pure black
    final amoledColorScheme = baseTheme.colorScheme.copyWith(
      surface: Colors.black,
      onSurface: Colors.white, // Ensure visibility
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: amoledColorScheme,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: Colors.black,
      ),
    );
  }

  /// Apply consistent component styles based on the ColorScheme.
  static ThemeData _applyComponentThemes(
    ThemeData baseTheme,
    ColorScheme colorScheme,
  ) {
    return baseTheme.copyWith(
      // Switch: Active track uses primary color
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      // Slider: Active part uses primary color
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.24),
      ),
      // Radio: Selected circle uses primary color
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      // Checkbox: Checked box uses primary color
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      // Segmented Button: Selected segment uses primaryContainer equivalent
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurface;
          }),
        ),
      ),
      // Icon Button: Default tinting
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(colorScheme.primary),
        ),
      ),
    );
  }

  /// Legacy getters for backward compatibility.
  static ThemeData get lightTheme => buildLightTheme();
  static ThemeData get darkTheme => buildDarkTheme();
}
