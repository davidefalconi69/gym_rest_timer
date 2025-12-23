// Typed event classes for background service communication.
//
// These provide type-safe alternatives to raw `Map<String, dynamic>` events,
// improving code readability, IDE support, and reducing runtime errors.

/// Represents a timer state update from the background service.
///
/// This is the primary event type for SSOT communication.
/// The background service broadcasts this on every state change.
class TimerStateEvent {
  /// Remaining seconds in the countdown.
  final int remainingSeconds;

  /// Total timer duration in seconds.
  final int totalSeconds;

  /// Current timer status: 'running', 'paused', 'ready', 'cooldown'.
  final String status;

  /// Timestamp when the event was created (milliseconds since epoch).
  final int timestamp;

  const TimerStateEvent({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.status,
    required this.timestamp,
  });

  /// Parse from a raw Map event.
  /// Returns null if the map doesn't contain required fields.
  static TimerStateEvent? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    final status = map['status'] as String?;
    if (status == null) return null;

    return TimerStateEvent(
      remainingSeconds: map['remainingSeconds'] as int? ?? 0,
      totalSeconds: map['totalSeconds'] as int? ?? 90,
      status: status,
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if this is a running state.
  bool get isRunning => status == 'running';

  /// Check if this is a paused state.
  bool get isPaused => status == 'paused';

  /// Check if this is a ready state.
  bool get isReady => status == 'ready';

  /// Check if this is in cooldown (just finished).
  bool get isCooldown => status == 'cooldown';

  @override
  String toString() =>
      'TimerStateEvent(status: $status, remaining: ${remainingSeconds}s)';
}

/// Represents a notification action from the background service.
class NotificationActionEvent {
  /// The action identifier: 'pause', 'resume', 'stop', 'start', 'restart'.
  final String action;

  /// Remaining seconds at time of action (optional).
  final int? remainingSeconds;

  const NotificationActionEvent({required this.action, this.remainingSeconds});

  /// Parse from a raw Map event.
  /// Returns null if the map doesn't contain an action.
  static NotificationActionEvent? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    final action = map['action'] as String?;
    if (action == null) return null;

    return NotificationActionEvent(
      action: action,
      remainingSeconds: map['remainingSeconds'] as int?,
    );
  }

  @override
  String toString() => 'NotificationActionEvent(action: $action)';
}

/// Represents a timer completion event.
class TimerCompleteEvent {
  const TimerCompleteEvent();

  /// Check if a raw map represents a timer complete event.
  static bool isCompleteEvent(Map<String, dynamic>? map) {
    if (map == null) return false;
    return map['event'] == 'timerComplete';
  }
}
