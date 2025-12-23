import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_rest_timer/l10n/app_localizations.dart';
import 'package:gym_rest_timer/core/services/background_service.dart';

import 'providers/timer_provider.dart';
import 'providers/timer_state.dart';

/// The main timer screen - the heart of the Gym Rest Timer app.
///
/// This screen displays:
/// - A circular progress indicator that shrinks as time passes
/// - The remaining time in MM:SS format (tappable to edit when stopped)
/// - A play/pause button that changes based on timer state
/// - A settings button for future navigation
///
/// We use ConsumerWidget to access Riverpod providers.
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the timer state - rebuilds when any value changes.
    final timerState = ref.watch(timerProvider);

    // Get the notifier to call methods (start, pause, etc.)
    final timerNotifier = ref.read(timerProvider.notifier);

    // Accessing the theme to use our defined colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen for service errors and show SnackBar
    ref.listen<AsyncValue<ServiceError?>>(serviceErrorProvider, (_, next) {
      next.whenData((error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer to push content towards center but allow settings at bottom
              const Spacer(),

              // Circular Timer with Progress Indicator
              // Using FadeInDown for a nice entry animation
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Semantics(
                  button: true,
                  label: _getButtonLabel(context, timerState),
                  child: GestureDetector(
                    // Tap the circle to pause/resume while running
                    onTap: () {
                      if (timerState.isRunning || timerState.isPaused) {
                        timerNotifier.togglePauseResume();
                      }
                    },
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background ring (the faded part)
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: CircularProgressIndicator(
                              value: 1.0, // Always full for background
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ),

                          // Progress ring (shrinks as time passes)
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: TweenAnimationBuilder<double>(
                              // Animate smoothly when progress changes
                              tween: Tween(
                                begin: timerState.progress,
                                end: timerState.progress,
                              ),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 12,
                                  strokeCap: StrokeCap.round,
                                  color: _getProgressColor(colorScheme, value),
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),
                          ),

                          // Center content: time and label
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                timerState.formattedTime,
                                semanticsLabel:
                                    "${AppLocalizations.of(context)!.sectionTimer}: ${timerState.formattedTime}",
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: 80,
                                  letterSpacing: -2,
                                ),
                              ),

                              // Status label - shows current state
                              Text(
                                _getStatusLabel(context, timerState),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  letterSpacing: 4,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Gap(60),

              // Main Action Button (Start/Pause/Resume)
              // Using FadeInUp to animate up from below
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 350),
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _handleMainButtonPress(timerNotifier, timerState),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(_getButtonIcon(timerState), size: 28),
                    label: Text(
                      _getButtonLabel(context, timerState),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),

              const Gap(16),
              // Reset button - always present (invisible) to prevent layout shift
              AnimatedOpacity(
                opacity: timerState.isPaused ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !timerState.isPaused,
                  child: TextButton.icon(
                    onPressed: () => timerNotifier.reset(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context)!.reset),
                  ),
                ),
              ),

              const Spacer(),

              // Settings Button at the bottom right
              // Using FadeInRight for subtle entry
              Align(
                alignment: Alignment.centerRight,
                child: FadeInRight(
                  delay: const Duration(milliseconds: 150),
                  duration: const Duration(milliseconds: 300),
                  child: IconButton.filled(
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: AppLocalizations.of(context)!.settings,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles the main button press based on current state.
  void _handleMainButtonPress(TimerNotifier notifier, TimerState timerState) {
    if (timerState.isRunning) {
      // Running -> Pause
      notifier.pause();
    } else if (timerState.isPaused) {
      // Paused -> Resume
      notifier.start();
    } else if (timerState.isDone) {
      // Cooldown phase -> Start immediately (cancels the 3s delay)
      notifier.start();
    } else {
      // Ready -> Start fresh
      notifier.start();
    }
  }

  /// Gets the appropriate icon for the main button.
  IconData _getButtonIcon(TimerState timerState) {
    if (timerState.isRunning) {
      return Icons.pause_rounded;
    }
    // Show play icon for ready, paused, AND cooldown phases
    return Icons.play_arrow_rounded;
  }

  /// Gets the appropriate label for the main button.
  String _getButtonLabel(BuildContext context, TimerState timerState) {
    if (timerState.isRunning) {
      return AppLocalizations.of(context)!.actionPause;
    } else if (timerState.isPaused) {
      return AppLocalizations.of(context)!.actionResume;
    }
    // Show "START" for ready AND cooldown phases
    return AppLocalizations.of(context)!.actionStart;
  }

  /// Gets the status label based on timer state.
  String _getStatusLabel(BuildContext context, TimerState timerState) {
    if (timerState.isCompleted) {
      return AppLocalizations.of(context)!.statusDone;
    } else if (timerState.isPaused) {
      return AppLocalizations.of(context)!.statusPaused;
    } else if (timerState.isRunning) {
      return AppLocalizations.of(context)!.statusRest;
    }
    return AppLocalizations.of(context)!.statusReady;
  }

  /// Gets the progress color - changes as time runs out.
  Color _getProgressColor(ColorScheme colorScheme, double progress) {
    // Full -> Primary, Running low -> Warning colors
    if (progress > 0.3) {
      return colorScheme.primary;
    } else if (progress > 0.1) {
      return colorScheme.tertiary; // Orange-ish warning
    }
    return colorScheme.error; // Red when almost done
  }
}
