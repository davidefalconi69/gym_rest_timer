// Timer state representation for the Gym Rest Timer app.
//
// This immutable class holds all the data needed to represent the current
// state of the countdown timer. We keep it simple and focused:
// - How long is the rest period?
// - How much time is left?
// - What phase is the timer in?

/// The lifecycle phases of the timer.
///
/// - [ready]: Initial state, waiting for user to start.
/// - [running]: Timer is active and counting down.
/// - [paused]: Timer is paused.
/// - [cooldown]: Timer finished; short "DONE!" state before resetting.
enum TimerPhase { ready, running, paused, cooldown }

/// Immutable timer state class.
class TimerState {
  /// The total duration the user has set for their rest period (in seconds).
  /// This is the "default" time that gets reset to when starting fresh.
  final int totalDurationSeconds;

  /// How many seconds are left in the current countdown.
  /// When the timer starts, this equals totalDurationSeconds and ticks down.
  final int remainingSeconds;

  /// The current phase of the timer lifecycle.
  /// Replaces the old isRunning/isPaused booleans with a cleaner state machine.
  final TimerPhase phase;

  const TimerState({
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.phase,
  });

  /// Factory for the initial state - 90 seconds is a common gym rest time.
  factory TimerState.initial() {
    return const TimerState(
      totalDurationSeconds: 90,
      remainingSeconds: 90,
      phase: TimerPhase.ready,
    );
  }

  /// Progress value from 0.0 to 1.0 for the circular indicator.
  /// 1.0 means full (just started), 0.0 means empty (time's up).
  /// During "done" phase, progress is always 1.0 (full ring).
  double get progress {
    if (phase == TimerPhase.cooldown) return 1.0;
    if (totalDurationSeconds == 0) return 1.0;
    return remainingSeconds / totalDurationSeconds;
  }

  /// Convenience getter: timer is running.
  bool get isRunning => phase == TimerPhase.running;

  /// Convenience getter: timer is paused.
  bool get isPaused => phase == TimerPhase.paused;

  /// Convenience getter: timer is in "cooldown" phase (showing DONE! for 3s).
  bool get isDone => phase == TimerPhase.cooldown;

  /// Convenience getter: timer is "stopped" (ready phase).
  /// This is when the user can edit the time.
  bool get isStopped => phase == TimerPhase.ready;

  /// Convenience getter: timer has finished counting down.
  /// Note: In the new flow, this is true during the "cooldown" phase.
  bool get isCompleted => phase == TimerPhase.cooldown;

  /// Format the remaining time as MM:SS for display.
  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Create a copy with some fields changed - immutability pattern.
  TimerState copyWith({
    int? totalDurationSeconds,
    int? remainingSeconds,
    TimerPhase? phase,
  }) {
    return TimerState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phase: phase ?? this.phase,
    );
  }
}
