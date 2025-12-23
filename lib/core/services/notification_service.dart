import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../l10n/app_localizations.dart';

/// ============================================================================
/// NOTIFICATION SERVICE
/// ============================================================================
///
/// This service handles local notifications for the timer countdown.
///
/// KEY CONCEPTS:
/// - Uses flutter_local_notifications package
/// - Creates a "sticky" foreground notification that shows the countdown
/// - Provides action buttons (Pause/Resume, Stop) in the notification
/// - Updates the notification text every second with the remaining time
///
/// ARCHITECTURE:
/// - This runs in the SAME isolate as the caller (UI or background)
/// - The background service calls this to update the notification
/// - Action button callbacks are handled via streams
/// ============================================================================

/// Action types for notification buttons.
enum NotificationAction { pause, resume, stop, restart, start }

/// Service for managing timer notifications.
///
/// This is a singleton to ensure only one notification channel and plugin
/// instance exists throughout the app lifecycle.
class NotificationService {
  // Singleton pattern
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  /// The flutter_local_notifications plugin instance.
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Stream controller for notification action events.
  ///
  /// When user taps a notification button, this stream emits the action.
  /// The timer provider listens to this to update state accordingly.
  final StreamController<NotificationAction> _actionController =
      StreamController<NotificationAction>.broadcast();

  /// Stream of notification actions (Pause/Resume/Stop button presses).
  Stream<NotificationAction> get actionStream => _actionController.stream;

  /// Notification channel ID - must be unique per app.
  static const String _channelId = 'gym_rest_timer_channel';
  static const String _channelName = 'Rest Timer';
  static const String _channelDescription =
      'Shows countdown during rest periods';

  /// The notification ID - we use a single ID to update the same notification.
  static const int _notificationId = 888;

  /// Whether the service has been initialized.
  bool _initialized = false;

  /// Initialize the notification service.
  ///
  /// Must be called before showing any notifications.
  /// Call this in main() before runApp().
  Future<void> init() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      'ic_stat_icon_foreground',
    );

    // iOS/macOS settings (for future use)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    // Initialize with callback for when user taps the notification itself
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create the notification channel on Android 8.0+
    await _createNotificationChannel();

    _initialized = true;
    debugPrint('NotificationService: Initialized');
  }

  /// Create the notification channel for Android.
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: false, // We handle sound ourselves
      enableVibration: false, // We handle vibration ourselves
      showBadge: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap when app is in foreground.
  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationAction(response.actionId);
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermission() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      debugPrint('NotificationService: Permission granted: $granted');
      return granted ?? false;
    }

    return true; // iOS handles permissions differently
  }

  /// Get localized strings for the given language code.
  AppLocalizations _getLoc(String langCode) {
    try {
      return lookupAppLocalizations(Locale(langCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Show a chronometer notification that counts down automatically.
  ///
  /// This uses Android's native Chronometer widget which updates the display
  /// at the system level - no need for Flutter to push updates every second.
  ///
  /// [endTimeMillis] - The epoch timestamp (in milliseconds) when the timer will finish.
  /// [languageCode] - The language code for localization (e.g., 'en', 'it').
  Future<void> showChronometerNotification({
    required int endTimeMillis,
    String languageCode = 'en',
  }) async {
    final loc = _getLoc(languageCode);

    // Build action buttons - timer is running, so show Pause and Stop
    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'pause',
        loc.notificationPause,
        showsUserInterface: false,
        cancelNotification: false,
      ),
      AndroidNotificationAction(
        'stop',
        loc.notificationStop,
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];

    // Android notification details with chronometer enabled
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Makes it "sticky" - can't be swiped away
      autoCancel: false,
      // CHRONOMETER SETTINGS:
      usesChronometer: true, // Enable native chronometer
      chronometerCountDown: true, // Count DOWN instead of up
      showWhen: true, // Required for chronometer to display
      when: endTimeMillis, // The target end time
      playSound: false,
      enableVibration: false,
      actions: actions,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      loc.statusResting,
      null,
      notificationDetails,
    );

    debugPrint(
      'NotificationService: Chronometer notification shown (end: $endTimeMillis)',
    );
  }

  /// Show a static "paused" notification with the remaining time.
  ///
  /// This is shown when the timer is paused - no chronometer, just static text.
  ///
  /// [remainingSeconds] - Current remaining time to display
  /// [languageCode] - The language code for localization (e.g., 'en', 'it').
  Future<void> showPausedNotification({
    required int remainingSeconds,
    String languageCode = 'en',
  }) async {
    final loc = _getLoc(languageCode);
    final formattedTime = _formatTime(remainingSeconds);

    // Build action buttons - timer is paused, so show Resume and Stop
    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'resume',
        loc.notificationResume,
        showsUserInterface: false,
        cancelNotification: false,
      ),
      AndroidNotificationAction(
        'stop',
        loc.notificationStop,
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ];

    // Android notification details WITHOUT chronometer
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      // NO chronometer for paused state
      usesChronometer: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: actions,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      loc.statusPaused,
      formattedTime,
      notificationDetails,
    );

    debugPrint(
      'NotificationService: Paused notification shown ($formattedTime)',
    );
  }

  /// Cancel the timer notification.
  Future<void> cancelNotification() async {
    await _notificationsPlugin.cancel(_notificationId);
    debugPrint('NotificationService: Notification cancelled');
  }

  /// Show the "finished" notification when timer hits 0.
  ///
  /// Shows "Time's Up!" with the actual timer duration and a "Start" button.
  /// This is shown during the 3-second cooldown period.
  ///
  /// [durationSeconds] - The timer duration to display (already reset)
  /// [languageCode] - The language code for localization (e.g., 'en', 'it').
  Future<void> showFinishedNotification({
    required int durationSeconds,
    String languageCode = 'en',
  }) async {
    final loc = _getLoc(languageCode);
    final formattedTime = _formatTime(durationSeconds);

    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'start',
        loc.actionStart,
        showsUserInterface: false,
        cancelNotification: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Sticky - cannot be dismissed by swiping
      autoCancel: false,
      usesChronometer: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: actions,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      loc.statusDone,
      null,
      notificationDetails,
    );

    debugPrint(
      'NotificationService: Finished notification shown ($formattedTime)',
    );
  }

  /// Show the "ready" notification when timer is stopped/ready.
  ///
  /// This notification is sticky and shows a "Start" button.
  /// Shown after Stop button is pressed or after the 3-second done delay.
  ///
  /// [durationSeconds] - The current timer duration to display
  /// [languageCode] - The language code for localization (e.g., 'en', 'it').
  Future<void> showReadyNotification({
    int durationSeconds = 90,
    String languageCode = 'en',
  }) async {
    final loc = _getLoc(languageCode);
    final formattedTime = _formatTime(durationSeconds);

    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        'start',
        loc.actionStart,
        showsUserInterface: false,
        cancelNotification: false,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Sticky - cannot be dismissed by swiping
      autoCancel: false,
      usesChronometer: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: actions,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      _notificationId,
      loc.statusReady,
      formattedTime,
      notificationDetails,
    );

    debugPrint(
      'NotificationService: Ready notification shown ($formattedTime)',
    );
  }

  /// Handle action button press.
  void _handleNotificationAction(String? actionId) {
    debugPrint('NotificationService: Action received: $actionId');

    switch (actionId) {
      case 'pause':
        _actionController.add(NotificationAction.pause);
        break;
      case 'resume':
        _actionController.add(NotificationAction.resume);
        break;
      case 'restart':
        _actionController.add(NotificationAction.restart);
        break;
      case 'start':
        _actionController.add(NotificationAction.start);
        break;
      case 'stop':
        _actionController.add(NotificationAction.stop);
        break;
    }
  }

  /// Format seconds as MM:SS.
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Dispose of resources.
  void dispose() {
    _actionController.close();
    _instance = null;
  }
}

/// Background notification response handler.
///
/// This is a TOP-LEVEL function (not a method) because it needs to be
/// called from a separate isolate when the app is in the background.
/// The @pragma annotation ensures the function is not tree-shaken.
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('NotificationService: Background action: ${response.actionId}');

  // Forward the action to the running background service isolate
  // This allows notification buttons to work even when app is backgrounded/killed
  final service = FlutterBackgroundService();
  service.invoke('notificationAction', {'actionId': response.actionId});
}
