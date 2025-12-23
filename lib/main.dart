import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_rest_timer/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/settings.dart';
import 'core/settings_provider.dart';
import 'core/theme.dart';
import 'core/services/background_service.dart';
import 'core/services/notification_service.dart';
import 'features/settings/settings_screen.dart';
import 'features/timer/timer_screen.dart';
import 'core/licenses.dart';

/// App entry point.
///
/// Initializes core services (Storage, Notifications, Background Service) *before*
/// the UI is built. This ensures the app starts with a valid state and can
/// immediately handle background events or deep links.

/// App entry point with async initialization of all services.
void main() async {
  // Ensure Flutter bindings are initialized for async operations.
  WidgetsFlutterBinding.ensureInitialized();

  // Register Outfit font license
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
      LicenseEntryWithLineBreaks(<String>['Outfit Font'], outfitFontLicense),
    ]);
  });

  // Register beep sound license
  LicenseRegistry.addLicense(() {
    return Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
      LicenseEntryWithLineBreaks(<String>['beep.mp3 Sound'], beepSoundLicense),
    ]);
  });

  // Initialize services in parallel for faster startup.
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    _initializeServices(),
  ]);

  final sharedPreferences = results[0] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the actual instance.
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

/// Initialize notification and background services.
Future<void> _initializeServices() async {
  // Initialize notification service first (required for background service)
  await NotificationService.instance.init();

  // Initialize background timer service
  await BackgroundTimerService.instance.init();

  // Request notification permission on Android 13+
  // This shows a permission dialog if not already granted
  await NotificationService.instance.requestPermission();
}

// GoRouter configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TimerScreen()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// Main app widget - uses ConsumerStatefulWidget for lifecycle handling.
///
/// We need StatefulWidget here to:
/// 1. Add WidgetsBindingObserver for app lifecycle events
/// 2. Sync timer state when app returns from background
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events (foreground/background changes)
    WidgetsBinding.instance.addObserver(this);

    // Sync initial settings from settings to background service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncInitialSettings();
    });
  }

  /// Sync initial settings (duration and language) to the background service.
  /// This ensures the notification shows the correct duration and language on app launch.
  void _syncInitialSettings() {
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.value;

    // Sync duration
    final duration = settings?.defaultDurationSeconds ?? 90;
    BackgroundTimerService.instance.updateDuration(duration);

    // Sync language (use 'en' as fallback for system default)
    final langCode = settings?.locale?.languageCode ?? 'en';
    BackgroundTimerService.instance.syncLanguage(langCode);

    debugPrint(
      'MyApp: Synced initial settings - duration: $duration, lang: $langCode',
    );
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when app lifecycle state changes.
  ///
  /// This is how we detect when the app returns from background.
  /// When the app resumes, we sync the timer state from the background service.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App returned to foreground - sync timer state from background
      // The timer provider will request state from the background service
      // and update its local state accordingly.
      debugPrint('MyApp: App resumed, syncing timer state');
      // We don't directly call the timer provider here because it
      // automatically syncs via its background event listener.
      // Just request an update in case the listener hasn't received one.
      BackgroundTimerService.instance.requestState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme settings for reactive updates.
    final appThemeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final monochromeAccent = ref.watch(monochromeAccentProvider);
    final locale = ref.watch(localeProvider);

    // Map AppThemeMode to Flutter's ThemeMode
    ThemeMode themeMode;
    switch (appThemeMode) {
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        themeMode = ThemeMode.dark;
        break;
    }

    // Select the correct theme data builder
    final lightTheme = AppTheme.buildLightTheme(accentColor, monochromeAccent);
    final darkTheme = appThemeMode == AppThemeMode.amoled
        ? AppTheme.buildAmoledTheme(accentColor, monochromeAccent)
        : AppTheme.buildDarkTheme(accentColor, monochromeAccent);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      // Apply dynamic theme based on settings.
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      // Localization configuration
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    );
  }
}
