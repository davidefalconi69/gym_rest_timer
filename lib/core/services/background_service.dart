import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background service implementation using `flutter_background_service`.
///
/// Runs the timer logic in a separate isolate to ensure accurate countdowns
/// even when the app is minimized or the screen is off.
///
/// **Note:** This runs in a separate memory space. It cannot access the main
/// isolate's memory or Riverpod providers. Use [BackgroundCommand] and
/// [BackgroundEvent] for all communication.
///
/// Communicates with the main UI isolate via:
/// - Commands (UI -> Service): start, pause, resume, stop.
/// - Events (Service -> UI): State sync, timer completion.

/// Commands sent FROM the UI TO the background service.
class BackgroundCommand {
  static const String start = 'startTimer';
  static const String pause = 'pauseTimer';
  static const String resume = 'resumeTimer';
  static const String stop = 'stopTimer';
  static const String getState = 'getState';
  static const String updateDuration = 'updateDuration';
  static const String setLanguage = 'set_language';
}

/// Events sent FROM the background TO the UI.
class BackgroundEvent {
  static const String stateSync = 'stateSync';
  static const String timerComplete = 'timerComplete';
  static const String actionFromNotification = 'actionFromNotification';
}

/// Error types that can occur during service operations.
enum ServiceErrorType {
  /// Service failed to start (permissions, system restrictions, etc.)
  startupFailed,

  /// Service was unexpectedly stopped
  unexpectedStop,
}

/// Represents an error from the background service.
class ServiceError {
  final ServiceErrorType type;
  final String message;

  const ServiceError({required this.type, required this.message});

  @override
  String toString() => 'ServiceError($type): $message';
}

/// Service for managing background timer execution.
class BackgroundTimerService {
  // Singleton pattern
  static BackgroundTimerService? _instance;
  static BackgroundTimerService get instance =>
      _instance ??= BackgroundTimerService._();

  BackgroundTimerService._();

  /// The background service instance.
  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Stream controller for events from the background.
  /// The timer provider listens to this to update state.
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream controller for service errors.
  /// The UI can listen to this to show error messages.
  final StreamController<ServiceError> _errorController =
      StreamController<ServiceError>.broadcast();

  /// Stream of events from the background service.
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  /// Stream of service errors for UI error handling.
  Stream<ServiceError> get errorStream => _errorController.stream;

  /// Whether the service is currently running.
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Initialize the background service.
  ///
  /// This sets up the service configuration but doesn't start it yet.
  /// Call startService() to actually start the background execution.
  Future<void> init() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        // Called when the background isolate starts
        onStart: onStart,
        // Auto-start is ON - service starts immediately with the app
        autoStart: true,
        // This keeps the service running even when app is killed
        isForegroundMode: true,
        // Notification shown while service is running
        notificationChannelId: 'gym_rest_timer_channel',
        initialNotificationTitle: 'Rest Timer',
        initialNotificationContent: 'Ready',
        foregroundServiceNotificationId: 888,
        // Auto-start after device reboot (optional)
        autoStartOnBoot: false,
      ),
      // iOS configuration (for future use)
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Listen for events from the background service
    // stateSync is the ONLY event for state updates (Single Source of Truth)
    _service.on(BackgroundEvent.stateSync).listen((event) {
      if (event != null) {
        _eventController.add(event);
      }
    });

    _service.on(BackgroundEvent.timerComplete).listen((event) {
      if (event != null) {
        _eventController.add({'event': BackgroundEvent.timerComplete});
      }
    });

    _service.on(BackgroundEvent.actionFromNotification).listen((event) {
      if (event != null) {
        _eventController.add(event);
      }
    });

    debugPrint('BackgroundTimerService: Initialized');
  }

  /// Start the background service with the timer.
  ///
  /// [totalSeconds] - Total duration of the timer
  /// [remainingSeconds] - Current remaining time (for resume)
  ///
  /// Returns `true` if the service started successfully, `false` otherwise.
  /// Also emits a [ServiceError] on the error stream if startup fails.
  Future<bool> startService({
    required int totalSeconds,
    required int remainingSeconds,
  }) async {
    if (_isRunning) {
      debugPrint(
        'BackgroundTimerService: Already running, sending start command',
      );
      _service.invoke(BackgroundCommand.start, {
        'totalSeconds': totalSeconds,
        'remainingSeconds': remainingSeconds,
      });
      return true;
    }

    // Start the background service
    final started = await _service.startService();
    if (started) {
      _isRunning = true;
      debugPrint('BackgroundTimerService: Service started');

      // Give the service a moment to initialize, then send the start command
      await Future.delayed(const Duration(milliseconds: 500));
      _service.invoke(BackgroundCommand.start, {
        'totalSeconds': totalSeconds,
        'remainingSeconds': remainingSeconds,
      });
      return true;
    } else {
      debugPrint('BackgroundTimerService: Failed to start service');
      // Emit error for UI to handle
      _errorController.add(
        const ServiceError(
          type: ServiceErrorType.startupFailed,
          message:
              'Failed to start background service. '
              'Please check app permissions and try again.',
        ),
      );
      return false;
    }
  }

  /// Pause the timer.
  void pauseTimer() {
    _service.invoke(BackgroundCommand.pause);
  }

  /// Resume the timer.
  void resumeTimer() {
    _service.invoke(BackgroundCommand.resume);
  }

  /// Reset the timer to ready state (does NOT stop the service).
  void resetTimer() {
    _service.invoke(BackgroundCommand.stop);
    debugPrint('BackgroundTimerService: Timer reset to ready');
  }

  /// Update the duration in the background service.
  /// This should be called when the user changes the duration in settings.
  void updateDuration(int durationSeconds) {
    _service.invoke(BackgroundCommand.updateDuration, {
      'durationSeconds': durationSeconds,
    });
    debugPrint('BackgroundTimerService: Duration updated to $durationSeconds');
  }

  /// Update the language in the background service.
  /// This should be called when the user changes the language in settings.
  void syncLanguage(String languageCode) {
    _service.invoke(BackgroundCommand.setLanguage, {'lang': languageCode});
    debugPrint('BackgroundTimerService: Language synced to $languageCode');
  }

  /// Request the current state from the background.
  void requestState() {
    _service.invoke(BackgroundCommand.getState);
  }

  /// Tell background service to show ready notification.
  void showReadyNotification() {
    _service.invoke('showReadyNotification');
  }

  /// Dispose of resources.
  void dispose() {
    _eventController.close();
    _errorController.close();
    _instance = null;
  }
}

/// ============================================================================
/// BACKGROUND ISOLATE ENTRY POINT
/// ============================================================================
///
/// This function runs in a COMPLETELY SEPARATE ISOLATE from the main app.
/// It has NO access to:
/// - Riverpod providers
/// - BuildContext
/// - Any UI widgets
/// - Any state from the main isolate
///
/// It CAN:
/// - Run Dart code
/// - Use platform channels
/// - Update notifications
/// - Communicate with main isolate via invoke()
/// ============================================================================

/// Entry point for the background service.
///
/// The @pragma annotation ensures this function is not removed by tree-shaking.
/// This is REQUIRED because the function is called from native code.
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Ensure we have access to platform channels
  DartPluginRegistrant.ensureInitialized();

  debugPrint('BackgroundService: onStart called');

  // Read duration and language from SharedPreferences (Single Source of Truth)
  // This ensures we initialize with the user's saved settings, not hardcoded values.
  final prefs = await SharedPreferences.getInstance();
  final savedDuration = prefs.getInt('default_duration_seconds') ?? 90;
  final savedLanguage = prefs.getString('locale') ?? 'en';

  // Timer state in this isolate
  int totalSeconds = savedDuration;
  int remainingSeconds = savedDuration;
  bool isRunning = false;
  Timer? countdownTimer;
  int timerGeneration = 0; // Guard for async race conditions
  String languageCode = savedLanguage; // Language for localized notifications

  debugPrint('[BG Service] Language set to: $savedLanguage');
  debugPrint('[BG Service] Duration set to: $savedDuration');

  // ==========================================================================
  // STATE BROADCAST HELPER
  // ==========================================================================
  // Broadcasts the full timer state to the UI. This is the ONLY way the UI
  // should receive state updates - ensuring Single Source of Truth.
  void broadcastState(String status) {
    service.invoke(BackgroundEvent.stateSync, {
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'status': status, // 'running', 'paused', 'ready', 'done'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint(
      'Service: Broadcasting state -> $status, ${remainingSeconds}s remaining',
    );
  }

  // Initialize notification service in this isolate
  final notificationService = NotificationService.instance;
  await notificationService.init();

  // Show "Ready" notification immediately on service start
  await _showReadyNotification(notificationService, totalSeconds, languageCode);
  debugPrint('BackgroundService: Initial ready notification shown');

  // Broadcast initial ready state so UI syncs on app launch
  broadcastState('ready');

  // ==========================================================================
  // NOTIFICATION ACTION HANDLERS (Consolidated)
  // ==========================================================================
  // Helper functions to handle notification actions. These are called from
  // both the foreground actionStream and background notificationAction handlers.

  /// Handle pause action from notification.
  void handlePause() {
    countdownTimer?.cancel();
    isRunning = false;
    broadcastState('paused');
    _showPausedNotification(
      notificationService,
      remainingSeconds,
      languageCode,
    );
    service.invoke(BackgroundEvent.actionFromNotification, {
      'action': 'pause',
      'remainingSeconds': remainingSeconds,
    });
  }

  /// Handle resume action from notification.
  void handleResume() {
    isRunning = true;
    broadcastState('running');
    final myGen = ++timerGeneration;
    _startCountdown(
      service,
      notificationService,
      () => remainingSeconds,
      (val) => remainingSeconds = val,
      () => isRunning,
      (val) {
        isRunning = val;
        countdownTimer?.cancel();
      },
      getTotalSeconds: () => totalSeconds,
      broadcastState: broadcastState,
      generation: myGen,
      currentGeneration: () => timerGeneration,
      getLanguageCode: () => languageCode,
    ).then((timer) {
      if (timer != null) countdownTimer = timer;
    });
    service.invoke(BackgroundEvent.actionFromNotification, {
      'action': 'resume',
      'remainingSeconds': remainingSeconds,
    });
  }

  /// Handle stop action from notification.
  void handleStop() {
    countdownTimer?.cancel();
    isRunning = false;
    remainingSeconds = totalSeconds;
    broadcastState('ready');
    _showReadyNotification(notificationService, totalSeconds, languageCode);
    service.invoke(BackgroundEvent.actionFromNotification, {'action': 'stop'});
  }

  /// Handle start action from notification (from ready state).
  void handleStart() {
    remainingSeconds = totalSeconds;
    isRunning = true;
    countdownTimer?.cancel();
    broadcastState('running');
    final myGen = ++timerGeneration;
    _startCountdown(
      service,
      notificationService,
      () => remainingSeconds,
      (val) => remainingSeconds = val,
      () => isRunning,
      (val) {
        isRunning = val;
        countdownTimer?.cancel();
      },
      getTotalSeconds: () => totalSeconds,
      broadcastState: broadcastState,
      generation: myGen,
      currentGeneration: () => timerGeneration,
      getLanguageCode: () => languageCode,
    ).then((timer) {
      if (timer != null) countdownTimer = timer;
    });
    service.invoke(BackgroundEvent.actionFromNotification, {
      'action': 'start',
      'remainingSeconds': totalSeconds,
    });
  }

  /// Handle restart action from notification.
  void handleRestart() {
    remainingSeconds = totalSeconds;
    isRunning = true;
    countdownTimer?.cancel();
    broadcastState('running');
    final myGen = ++timerGeneration;
    _startCountdown(
      service,
      notificationService,
      () => remainingSeconds,
      (val) => remainingSeconds = val,
      () => isRunning,
      (val) {
        isRunning = val;
        countdownTimer?.cancel();
      },
      getTotalSeconds: () => totalSeconds,
      broadcastState: broadcastState,
      generation: myGen,
      currentGeneration: () => timerGeneration,
      getLanguageCode: () => languageCode,
    ).then((timer) {
      if (timer != null) countdownTimer = timer;
    });
    service.invoke(BackgroundEvent.actionFromNotification, {
      'action': 'restart',
      'remainingSeconds': totalSeconds,
    });
  }

  // Listen for notification action buttons (app in foreground)
  notificationService.actionStream.listen((action) {
    debugPrint('BackgroundService: Notification action (foreground): $action');
    switch (action) {
      case NotificationAction.pause:
        handlePause();
        break;
      case NotificationAction.resume:
        handleResume();
        break;
      case NotificationAction.stop:
        handleStop();
        break;
      case NotificationAction.start:
        handleStart();
        break;
      case NotificationAction.restart:
        handleRestart();
        break;
    }
  });

  // Listen for notification actions from background handler (app backgrounded/killed)
  service.on('notificationAction').listen((event) {
    if (event == null) return;
    final actionId = event['actionId'] as String?;
    debugPrint(
      'BackgroundService: Notification action (background): $actionId',
    );

    switch (actionId) {
      case 'pause':
        handlePause();
        break;
      case 'resume':
        handleResume();
        break;
      case 'stop':
        handleStop();
        break;
      case 'start':
        handleStart();
        break;
      case 'restart':
        handleRestart();
        break;
    }
  });

  // Handle start timer command from UI
  service.on(BackgroundCommand.start).listen((event) {
    if (event == null) return;

    totalSeconds = event['totalSeconds'] ?? 90;
    remainingSeconds = event['remainingSeconds'] ?? totalSeconds;
    isRunning = true;

    debugPrint('Service: Start command received - $remainingSeconds seconds');

    // Cancel any existing timer
    countdownTimer?.cancel();

    // Broadcast state IMMEDIATELY - UI updates only from this
    broadcastState('running');

    // Start the countdown
    final myGen = ++timerGeneration;
    _startCountdown(
      service,
      notificationService,
      () => remainingSeconds,
      (val) => remainingSeconds = val,
      () => isRunning,
      (val) {
        isRunning = val;
        countdownTimer?.cancel();
      },
      getTotalSeconds: () => totalSeconds,
      broadcastState: broadcastState,
      generation: myGen,
      currentGeneration: () => timerGeneration,
      getLanguageCode: () => languageCode,
    ).then((timer) {
      if (timer != null) countdownTimer = timer;
    });
  });

  // Handle pause command
  service.on(BackgroundCommand.pause).listen((event) {
    debugPrint('Service: Pause command received');
    countdownTimer?.cancel();
    isRunning = false;
    // Broadcast state IMMEDIATELY - UI updates only from this
    broadcastState('paused');
    // Show static paused notification
    _showPausedNotification(
      notificationService,
      remainingSeconds,
      languageCode,
    );
  });

  // Handle resume command
  service.on(BackgroundCommand.resume).listen((event) {
    debugPrint('Service: Resume command received');
    isRunning = true;
    // Broadcast state IMMEDIATELY - UI updates only from this
    broadcastState('running');
    final myGen = ++timerGeneration;
    _startCountdown(
      service,
      notificationService,
      () => remainingSeconds,
      (val) => remainingSeconds = val,
      () => isRunning,
      (val) {
        isRunning = val;
        countdownTimer?.cancel();
      },
      getTotalSeconds: () => totalSeconds,
      broadcastState: broadcastState,
      generation: myGen,
      currentGeneration: () => timerGeneration,
      getLanguageCode: () => languageCode,
    ).then((timer) {
      if (timer != null) countdownTimer = timer;
    });
  });

  // Handle stop/reset command - resets timer to ready state but keeps service alive
  service.on(BackgroundCommand.stop).listen((event) {
    debugPrint('Service: Stop/Reset command received');
    countdownTimer?.cancel();
    isRunning = false;
    remainingSeconds = totalSeconds;
    // Broadcast state IMMEDIATELY - UI updates only from this
    broadcastState('ready');
    // Show ready notification instead of stopping service
    _showReadyNotification(notificationService, totalSeconds, languageCode);
    // Service stays alive for quick restart from notification
  });

  // Handle duration update command - sync duration from UI settings
  service.on(BackgroundCommand.updateDuration).listen((event) {
    if (event == null) return;
    final newDuration = event['durationSeconds'] as int? ?? 90;
    debugPrint('BackgroundService: Duration updated to $newDuration seconds');
    totalSeconds = newDuration;
    // Only update remainingSeconds if timer is not running
    if (!isRunning) {
      remainingSeconds = newDuration;
      // Update the ready notification with new duration
      _showReadyNotification(notificationService, totalSeconds, languageCode);
      // CRITICAL: Broadcast state to UI so it updates instantly!
      broadcastState('ready');
    }
  });

  // Handle language update command - sync language from UI settings
  service.on(BackgroundCommand.setLanguage).listen((event) {
    if (event == null) return;
    final newLang = event['lang'] as String? ?? 'en';
    debugPrint('[BG Service] Language set to: $newLang');
    languageCode = newLang;
    // IMMEDIATELY update notification with new language (regardless of state)
    // This ensures the user sees the language change instantly.
    if (isRunning) {
      // Timer running: show chronometer notification with new language
      final endTimeMillis =
          DateTime.now().millisecondsSinceEpoch +
          (remainingSeconds * 1000) +
          1000;
      notificationService.showChronometerNotification(
        endTimeMillis: endTimeMillis,
        languageCode: newLang,
      );
    } else {
      // Timer not running: show ready notification with new language
      _showReadyNotification(notificationService, totalSeconds, newLang);
    }
  });

  // Handle state request (for syncing when app resumes)
  service.on(BackgroundCommand.getState).listen((event) {
    debugPrint('Service: State request received, broadcasting current state');
    // Determine current status string
    final status = isRunning ? 'running' : 'ready';
    broadcastState(status);
  });

  // Handle ready notification request
  service.on('showReadyNotification').listen((event) {
    debugPrint('BackgroundService: Show ready notification requested');
    _showReadyNotification(notificationService, totalSeconds, languageCode);
  });
}

/// Start the countdown timer in the background.
///
/// REFACTORED: Now uses Android's native Chronometer for notification display.
/// The timer still runs every second to track state for UI sync and detect
/// completion, but we only send ONE notification at the start (not every tick).
///
/// When timer hits 0, we IMMEDIATELY reset remainingSeconds to totalSeconds
/// and broadcast 'cooldown'. After 3 seconds, we broadcast 'ready'.
Future<Timer?> _startCountdown(
  ServiceInstance service,
  NotificationService notificationService,
  int Function() getRemainingSeconds,
  void Function(int) setRemainingSeconds,
  bool Function() getIsRunning,
  void Function(bool) setIsRunning, {
  required int Function() getTotalSeconds,
  required void Function(String status) broadcastState,
  required int generation,
  required int Function() currentGeneration,
  required String Function() getLanguageCode,
}) async {
  // Calculate the end timestamp for the chronometer
  // Add 1000ms padding because Timer.periodic fires after 1s delay,
  // while Chronometer starts immediately (flooring the value).
  // This syncs the visual countdown: App(10) <-> Notif(10).
  final endTimeMillis =
      DateTime.now().millisecondsSinceEpoch +
      (getRemainingSeconds() * 1000) +
      1000;

  // Show ONE chronometer notification - Android handles the countdown display
  await notificationService.showChronometerNotification(
    endTimeMillis: endTimeMillis,
    languageCode: getLanguageCode(),
  );

  // RACE CONDITION CHECK:
  // If a new timer started while we were awaiting the notification, ABORT.
  // This prevents multiple timers from running simultaneously.
  if (generation != currentGeneration()) {
    debugPrint(
      'BackgroundService: Race condition detected, aborting old timer start',
    );
    return null;
  }

  debugPrint(
    'BackgroundService: Chronometer started, end time: $endTimeMillis',
  );

  // Start periodic timer for state tracking (NOT for notification updates)
  return Timer.periodic(const Duration(seconds: 1), (timer) async {
    final remaining = getRemainingSeconds();

    if (remaining <= 1) {
      // Timer complete!
      timer.cancel();
      setIsRunning(false);

      // IMMEDIATE RESET: Set remainingSeconds back to totalSeconds
      final totalSecs = getTotalSeconds();
      setRemainingSeconds(totalSecs);

      // Broadcast 'cooldown' state to UI (full time displayed, "DONE!" label)
      broadcastState('cooldown');

      // Notify the UI that timer is complete (for legacy compatibility)
      service.invoke(BackgroundEvent.timerComplete);

      // Show "Ready" notification with actual duration IMMEDIATELY
      await notificationService.showFinishedNotification(
        durationSeconds: totalSecs,
        languageCode: getLanguageCode(),
      );

      debugPrint(
        'BackgroundService: Timer complete, entering cooldown (${totalSecs}s)',
      );

      // Start 3-second internal timer, then transition to ready
      Timer(const Duration(seconds: 3), () {
        // After 3 seconds, broadcast 'ready' state
        broadcastState('ready');
        debugPrint('BackgroundService: Cooldown complete, now ready');
      });
    } else {
      // Tick down - update internal state only
      final newRemaining = remaining - 1;
      setRemainingSeconds(newRemaining);

      // Broadcast state to UI every tick (so UI stays synced)
      // Using stateSync for consistent single source of truth
      broadcastState('running');
    }
  });
}

/// Show paused notification with static time remaining.
Future<void> _showPausedNotification(
  NotificationService notificationService,
  int remainingSeconds,
  String languageCode,
) async {
  await notificationService.showPausedNotification(
    remainingSeconds: remainingSeconds,
    languageCode: languageCode,
  );
}

/// Show ready notification with duration display.
Future<void> _showReadyNotification(
  NotificationService notificationService,
  int durationSeconds,
  String languageCode,
) async {
  await notificationService.showReadyNotification(
    durationSeconds: durationSeconds,
    languageCode: languageCode,
  );
}

/// iOS background handler.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  debugPrint('BackgroundService: iOS background handler called');
  return true;
}
