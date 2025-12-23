// Test helpers and mock services for Gym Rest Timer testing.
//
// This file provides reusable utilities for all test types:
// - Mock implementations that bypass native plugins
// - Fake SharedPreferences setup
// - Test state builders
//
// IMPORTANT: This file avoids importing any library code that uses native
// plugins (audioplayers, flutter_background_service, etc.) to prevent
// test runner crashes.

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

// Only import types that don't have native plugin dependencies
import 'package:gym_rest_timer/core/services/background_events.dart';
import 'package:gym_rest_timer/features/timer/providers/timer_state.dart';

/// Mock implementation of BackgroundTimerService.
///
/// This avoids platform channel calls by simulating background service behavior
/// entirely in Dart. Used for widget and unit tests.
class MockBackgroundTimerService {
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 90;
  String _status = 'ready';
  bool _isInitialized = false;

  /// Stream of events matching the real service's pattern.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// Whether the mock service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Current status for verification.
  String get currentStatus => _status;

  /// Simulate service initialization.
  Future<void> init() async {
    _isInitialized = true;
    _broadcastState();
  }

  /// Simulate starting the timer.
  Future<bool> startService({
    required int totalSeconds,
    required int remainingSeconds,
  }) async {
    _totalSeconds = totalSeconds;
    _remainingSeconds = remainingSeconds;
    _status = 'running';
    _startCountdown();
    _broadcastState();
    return true;
  }

  /// Simulate pausing the timer.
  void pauseTimer() {
    _countdownTimer?.cancel();
    _status = 'paused';
    _broadcastState();
  }

  /// Simulate resuming the timer.
  void resumeTimer() {
    _status = 'running';
    _startCountdown();
    _broadcastState();
  }

  /// Simulate stopping/resetting the timer.
  void resetTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = _totalSeconds;
    _status = 'ready';
    _broadcastState();
  }

  /// Update default duration.
  void updateDuration(int durationSeconds) {
    _totalSeconds = durationSeconds;
    if (_status == 'ready') {
      _remainingSeconds = durationSeconds;
      _broadcastState();
    }
  }

  /// Request current state broadcast.
  void requestState() {
    _broadcastState();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _broadcastState();
      }
      if (_remainingSeconds == 0) {
        timer.cancel();
        _status = 'cooldown';
        _broadcastState();

        // Simulate 3-second cooldown reset
        Timer(const Duration(seconds: 3), () {
          if (_status == 'cooldown') {
            _remainingSeconds = _totalSeconds;
            _status = 'ready';
            _broadcastState();
          }
        });
      }
    });
  }

  void _broadcastState() {
    if (!_eventController.isClosed) {
      _eventController.add({
        'status': _status,
        'remainingSeconds': _remainingSeconds,
        'totalSeconds': _totalSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Clean up resources.
  void dispose() {
    _countdownTimer?.cancel();
    _eventController.close();
  }
}

/// Sets up fake SharedPreferences with optional initial values.
///
/// Call this in setUp() for tests that need SharedPreferences.
Future<void> setupFakeSharedPreferences([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
}

/// Helper to build a testable TimerState.
TimerState createTestTimerState({
  TimerPhase phase = TimerPhase.ready,
  int totalSeconds = 90,
  int remainingSeconds = 90,
}) {
  return TimerState(
    totalDurationSeconds: totalSeconds,
    remainingSeconds: remainingSeconds,
    phase: phase,
  );
}

/// Helper to create a test TimerStateEvent.
TimerStateEvent createTestTimerStateEvent({
  String status = 'ready',
  int remainingSeconds = 90,
  int totalSeconds = 90,
}) {
  return TimerStateEvent(
    status: status,
    remainingSeconds: remainingSeconds,
    totalSeconds: totalSeconds,
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
}
