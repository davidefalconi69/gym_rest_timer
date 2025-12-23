import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings_provider.dart';
import '../../../core/services/background_events.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/notification_service.dart';
import 'timer_state.dart';

/// Manages timer state by listening to the [BackgroundTimerService].
///
/// **Architecture: Single Source of Truth (SSOT)**
///
/// This provider implements a focused reactive pattern where the [BackgroundTimerService]
/// acts as the sole authoritative source for timer state.
///
/// *   **Role**: Acts as a "Listener/Slave" to the Background Service "Master".
/// *   **Commands**: Sends user intents (start, pause, reset) to the Service.
/// *   **Updates**: Listens for state broadcasts to update the UI.
///
/// This unidirectional flow prevents state drift between the foreground UI and
/// the background service, ensuring 100% accuracy.

/// The main timer provider - this is what the UI will watch.
/// Using Riverpod 2.0+ Notifier pattern for clean state management.
final timerProvider = NotifierProvider<TimerNotifier, TimerState>(
  TimerNotifier.new,
);

/// Provider for service errors - UI can watch this to show error messages.
/// Returns null when there's no error.
final serviceErrorProvider = StreamProvider<ServiceError?>((ref) {
  return BackgroundTimerService.instance.errorStream;
});

/// TimerNotifier manages timer state by listening to the Background Service.
///
/// It sends commands to the service and updates local state based on broadcasts.
class TimerNotifier extends Notifier<TimerState> {
  // REMOVED: Timer? _timer - UI no longer has its own timer

  /// Timer for the 3-second delay after completion.
  Timer? _doneDelayTimer;

  /// Subscription to background service events.
  /// This receives messages from the background isolate.
  StreamSubscription<Map<String, dynamic>>? _backgroundSubscription;

  /// Subscription to notification action events.
  StreamSubscription<NotificationAction>? _notificationSubscription;

  /// Subscription to service errors.
  StreamSubscription<ServiceError>? _errorSubscription;

  @override
  TimerState build() {
    // Get the default duration from settings (only once, on initial build).
    final defaultDuration = ref.read(defaultDurationProvider);

    // Important: Clean up resources when this provider is disposed.
    ref.onDispose(() {
      // REMOVED: _timer?.cancel() - UI no longer has its own timer
      _doneDelayTimer?.cancel();
      _backgroundSubscription?.cancel();
      _notificationSubscription?.cancel();
      _errorSubscription?.cancel();
    });

    // Set up listeners for background service events.
    // This handles messages from the background isolate.
    _setupBackgroundListeners();

    // Listen for settings changes and sync to background service.
    // Using ref.listen instead of ref.watch to avoid full state rebuilds.
    ref.listen<int>(defaultDurationProvider, (previous, next) {
      if (previous != next) {
        _onDefaultDurationChanged(next);
      }
    });

    // Sync initial duration to background service
    BackgroundTimerService.instance.updateDuration(defaultDuration);

    // Initialize with settings default duration in ready phase.
    return TimerState(
      totalDurationSeconds: defaultDuration,
      remainingSeconds: defaultDuration,
      phase: TimerPhase.ready,
    );
  }

  /// Called when the default duration setting changes.
  /// Updates both local state (if in ready phase) and background service.
  void _onDefaultDurationChanged(int newDuration) {
    debugPrint('UI: Default duration changed to $newDuration');

    // Always sync to background service
    BackgroundTimerService.instance.updateDuration(newDuration);

    // Only update local state if timer is stopped (ready phase)
    if (state.isStopped) {
      state = state.copyWith(
        totalDurationSeconds: newDuration,
        remainingSeconds: newDuration,
      );
    }
  }

  // ==========================================================================
  // BACKGROUND SERVICE LISTENERS
  // ==========================================================================

  /// Set up listeners for events from the background service.
  void _setupBackgroundListeners() {
    // Listen for events from background service
    _backgroundSubscription?.cancel();
    _backgroundSubscription = BackgroundTimerService.instance.eventStream
        .listen((event) {
          // Try to parse as typed event for type safety
          final stateEvent = TimerStateEvent.fromMap(event);
          if (stateEvent != null) {
            debugPrint('UI: Received state event: $stateEvent');
            _handleStateSync(stateEvent);
            return;
          }

          // Handle timer complete event
          if (TimerCompleteEvent.isCompleteEvent(event)) {
            debugPrint('UI: Received timer complete event');
            _handleBackgroundComplete();
            return;
          }

          // Log unhandled events for debugging
          debugPrint('UI: Received unhandled event: $event');
        });

    // Also listen for notification actions directly (when app is in foreground)
    // These trigger commands to the service (not direct state updates)
    _notificationSubscription?.cancel();
    _notificationSubscription = NotificationService.instance.actionStream
        .listen((action) {
          debugPrint('UI: Notification action received: $action');
          switch (action) {
            case NotificationAction.pause:
              pause();
              break;
            case NotificationAction.resume:
              start();
              break;
            case NotificationAction.stop:
              reset();
              break;
            case NotificationAction.restart:
              // Restart: reset and start fresh
              reset();
              start();
              break;
            case NotificationAction.start:
              // Start: ensures timer begins if in ready state
              start();
              break;
          }
        });
  }

  /// Handle stateSync events from the background service.
  /// Updates local state to match the service.
  void _handleStateSync(TimerStateEvent event) {
    debugPrint(
      'UI: State updated from Service -> ${event.status}, ${event.remainingSeconds}s remaining',
    );

    // Map status to TimerPhase using typed event properties
    TimerPhase phase;
    if (event.isRunning) {
      phase = TimerPhase.running;
    } else if (event.isPaused) {
      phase = TimerPhase.paused;
    } else if (event.isCooldown) {
      phase = TimerPhase.cooldown;
      // Handle cooldown state - play feedback and start delay timer
      _playFeedback();
      _startCooldownDelayTimer();
    } else {
      phase = TimerPhase.ready;
    }

    // Update local state to match service state
    state = state.copyWith(
      remainingSeconds: event.remainingSeconds,
      totalDurationSeconds: event.totalSeconds,
      phase: phase,
    );
  }

  /// Handle timer completion from background.
  void _handleBackgroundComplete() {
    debugPrint('UI: Timer complete event received');
    // Enter "cooldown" phase - background already reset remainingSeconds
    state = state.copyWith(phase: TimerPhase.cooldown);
    _playFeedback();
    _startCooldownDelayTimer();
  }

  // ==========================================================================
  // PUBLIC METHODS - COMMAND SENDERS (NO LOCAL STATE UPDATES)
  // ==========================================================================

  /// Request state sync from background service.
  /// Call this when the app returns to foreground.
  void syncFromBackground() {
    debugPrint('UI: Requesting state sync from service');
    if (BackgroundTimerService.instance.isRunning) {
      BackgroundTimerService.instance.requestState();
    }
  }

  /// Update the default duration when settings change.
  /// Only applies when timer is stopped (ready phase).
  void updateDefaultDuration(int seconds) {
    if (!state.isStopped) return;

    state = state.copyWith(
      totalDurationSeconds: seconds,
      remainingSeconds: seconds,
    );

    // Sync new duration to background service
    BackgroundTimerService.instance.updateDuration(seconds);
  }

  /// Start or resume the timer.
  void start() {
    if (state.isRunning) {
      debugPrint('UI: Already running, ignoring start command');
      return;
    }

    debugPrint('UI: Sending start/resume command to service');

    if (state.isPaused) {
      // Resuming from pause
      BackgroundTimerService.instance.resumeTimer();
    } else {
      // Fresh start (from ready or done phase)
      _doneDelayTimer?.cancel(); // Cancel any pending done delay

      BackgroundTimerService.instance.startService(
        totalSeconds: state.totalDurationSeconds,
        remainingSeconds: state.totalDurationSeconds,
      );
    }

    // IMPORTANT: We do NOT update local state here.
    // State will be updated when service broadcasts stateSync('running').
  }

  /// Pause the countdown.
  void pause() {
    if (!state.isRunning) return;
    BackgroundTimerService.instance.pauseTimer();
  }

  /// Toggle between running and paused states.
  ///
  /// This is what gets called when the user taps the timer circle.
  /// Makes it super easy to pause/resume with one tap.
  void togglePauseResume() {
    if (state.isRunning) {
      pause();
    } else if (state.isPaused) {
      start(); // This will resume
    }
    // If stopped (ready) or done, tapping doesn't do anything.
    // User should use the START button to begin.
  }

  /// Stop and reset the timer.
  void reset() {
    _doneDelayTimer?.cancel();
    BackgroundTimerService.instance.resetTimer();
  }

  /// Set a new duration for the timer.
  ///
  /// This can only be done when the timer is in ready phase.
  /// We update both the total duration and remaining seconds.
  void setDuration(int seconds) {
    if (!state.isStopped) {
      // Can't change duration while running, paused, or in done phase.
      // User must reset first.
      return;
    }

    // Clamp to reasonable values (1 second to 99 minutes 59 seconds)
    final clampedSeconds = seconds.clamp(1, 5999);

    state = state.copyWith(
      totalDurationSeconds: clampedSeconds,
      remainingSeconds: clampedSeconds,
    );

    // Sync new duration to background service
    BackgroundTimerService.instance.updateDuration(clampedSeconds);
  }

  // ==========================================================================
  // INTERNAL METHODS
  // ==========================================================================

  // REMOVED: _startTimer() method - UI no longer runs its own timer

  /// UI-side fallback for the 3-second cooldown transition.
  ///
  /// The Background Service manages its own 3-second timer and will broadcast
  /// a 'ready' state when complete. However, this UI-side timer provides
  /// resilience in case:
  /// - The service's broadcast is delayed due to system throttling
  /// - The app was backgrounded and misses the broadcast
  /// - Edge cases with isolate communication
  ///
  /// If the service's 'ready' event arrives first, this timer becomes a no-op
  /// since the phase will already be 'ready'.
  void _startCooldownDelayTimer() {
    _doneDelayTimer?.cancel();
    _doneDelayTimer = Timer(const Duration(seconds: 3), () {
      // Only transition if we're still in cooldown phase
      // (user might have started a new timer during the delay)
      if (state.phase == TimerPhase.cooldown) {
        debugPrint('UI: Cooldown complete, transitioning to ready');
        state = state.copyWith(phase: TimerPhase.ready);

        // Tell background service to show ready notification (don't stop service)
        if (BackgroundTimerService.instance.isRunning) {
          BackgroundTimerService.instance.showReadyNotification();
        }
      }
    });
  }

  /// Play audio and/or vibration feedback when timer completes.
  void _playFeedback() {
    // Read current settings
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;

    // Use the FeedbackService singleton
    FeedbackService.instance.playTimerEndFeedback(settings);
  }
}
