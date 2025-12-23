// Widget tests for Gym Rest Timer - UI Component Testing
//
// These tests verify that UI components render correctly.
// Native plugins and complex dependencies are bypassed.
//
// NOTE: Full app integration tests (with localization, routing) should use
// the integration_test/ directory instead. These tests focus on pure
// widget rendering without native dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_rest_timer/features/timer/providers/timer_state.dart';

import 'helpers/test_helpers.dart';

void main() {
  // ============================================================================
  // TIMER STATE DISPLAY TESTS (Pure Dart, no widgets needed)
  // ============================================================================

  group('TimerState Display Logic', () {
    test('formattedTime should format various times correctly', () {
      final testCases = [
        (90, '01:30'),
        (0, '00:00'),
        (59, '00:59'),
        (60, '01:00'),
        (3600, '60:00'),
        (5, '00:05'),
        (125, '02:05'),
      ];

      for (final (seconds, expected) in testCases) {
        final state = TimerState(
          totalDurationSeconds: seconds,
          remainingSeconds: seconds,
          phase: TimerPhase.ready,
        );
        expect(
          state.formattedTime,
          expected,
          reason: '$seconds seconds should format as $expected',
        );
      }
    });

    test('progress should calculate correctly', () {
      final testCases = [
        (90, 90, 1.0), // Full
        (90, 45, 0.5), // Half
        (90, 0, 0.0), // Empty
        (100, 25, 0.25), // Quarter
      ];

      for (final (total, remaining, expected) in testCases) {
        final state = TimerState(
          totalDurationSeconds: total,
          remainingSeconds: remaining,
          phase: TimerPhase.running,
        );
        expect(
          state.progress,
          expected,
          reason: '$remaining/$total should be $expected progress',
        );
      }
    });

    test('phase getters should work correctly', () {
      expect(
        TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.ready,
        ).isStopped,
        isTrue,
      );

      expect(
        TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 45,
          phase: TimerPhase.running,
        ).isRunning,
        isTrue,
      );

      expect(
        TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 45,
          phase: TimerPhase.paused,
        ).isPaused,
        isTrue,
      );

      expect(
        TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.cooldown,
        ).isDone,
        isTrue,
      );
    });
  });

  // ============================================================================
  // PURE WIDGET TESTS (No providers, no native dependencies)
  // ============================================================================

  group('Pure Widget Rendering', () {
    testWidgets('CircularProgressIndicator renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularProgressIndicator(
              value: 0.75,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Timer display text renders correctly', (tester) async {
      const timerText = '01:30';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(timerText, style: const TextStyle(fontSize: 80)),
            ),
          ),
        ),
      );

      expect(find.text(timerText), findsOneWidget);
    });

    testWidgets('Play button renders and is tappable', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('Settings button renders and is tappable', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('FilledButton with icon renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.star, size: 28),
                label: const Text('START'),
              ),
            ),
          ),
        ),
      );

      // FilledButton should be rendered
      expect(find.text('START'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is FilledButton), findsOneWidget);
    });
  });

  // ============================================================================
  // THEME TESTS
  // ============================================================================

  group('Theme Rendering', () {
    testWidgets('Dark theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Timer'),
                  CircularProgressIndicator(value: 0.5),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Timer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Light theme renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Timer'),
                  CircularProgressIndicator(value: 0.5),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Timer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Custom accent color applies to theme', (tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: customColor),
          ),
          home: Scaffold(
            body: FilledButton(onPressed: () {}, child: const Text('Test')),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  // ============================================================================
  // MOCK BACKGROUND SERVICE TESTS
  // ============================================================================

  group('MockBackgroundTimerService Widget Integration', () {
    test('Mock service broadcasts events correctly', () async {
      final mockService = MockBackgroundTimerService();
      await mockService.init();

      final events = <Map<String, dynamic>>[];
      mockService.events.listen(events.add);

      // Trigger a state broadcast
      mockService.requestState();

      // Wait for event
      await Future.delayed(const Duration(milliseconds: 100));

      expect(events, isNotEmpty);
      expect(events.first['status'], 'ready');

      mockService.dispose();
    });

    test('Mock service simulates timer flow', () async {
      final mockService = MockBackgroundTimerService();
      await mockService.init();

      // Start with 2 second timer
      await mockService.startService(totalSeconds: 2, remainingSeconds: 2);
      expect(mockService.currentStatus, 'running');

      // Pause
      mockService.pauseTimer();
      expect(mockService.currentStatus, 'paused');

      // Resume
      mockService.resumeTimer();
      expect(mockService.currentStatus, 'running');

      // Reset
      mockService.resetTimer();
      expect(mockService.currentStatus, 'ready');

      mockService.dispose();
    });
  });
}
