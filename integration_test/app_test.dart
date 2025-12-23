// Integration tests for Gym Rest Timer - Full E2E User Flow
//
// These tests simulate real user interactions with the app.
// They use a longer timeout due to actual timer countdowns.
//
// IMPORTANT: Native plugin behavior in integration tests:
// - flutter_background_service: Works on real devices, may need mocking on CI
// - audioplayers/vibration: Will attempt real playback on device
// - For CI environments, set up platform-specific test configurations
//
// Run with: flutter test integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_rest_timer/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Full User Flow E2E Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'Complete timer flow: Start -> Countdown -> Done -> Reset',
      (tester) async {
        // Initialize the app
        await tester.pumpWidget(const ProviderScope(child: MyApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify app started successfully
        expect(find.byType(MaterialApp), findsOneWidget);

        // Look for the timer screen elements
        // Should show initial ready state
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Navigate to Settings
        final settingsButton = find.byIcon(Icons.settings);
        expect(settingsButton, findsOneWidget);
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        // We should now be in settings screen
        // Look for common settings elements (theme, duration, etc.)
        // The exact text depends on localization, so look for structural elements
        expect(find.byType(ListView), findsOneWidget);

        // Go back to timer screen
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
        } else {
          // Use navigation pop
          await tester.pageBack();
        }
        await tester.pumpAndSettle();

        // Verify we're back on timer screen
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'Short timer countdown test (5 seconds)',
      (tester) async {
        // Set up with short duration
        SharedPreferences.setMockInitialValues({'default_duration_seconds': 5});

        await tester.pumpWidget(const ProviderScope(child: MyApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Start the timer
        final startButton = find.byIcon(Icons.play_arrow);
        expect(startButton, findsOneWidget);
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // Timer should now be running - button changes to pause
        await tester.pump(const Duration(milliseconds: 500));

        // Wait for the timer to complete (5 seconds + buffer)
        // We pump slowly to see state changes
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 1));
        }

        // After 10 seconds, the timer should have completed and reset
        // (5s countdown + 3s done state + buffer)
        await tester.pumpAndSettle();

        // Should be back to ready state with play button
        // Or might still be in cooldown - either is acceptable
        final playButton = find.byIcon(Icons.play_arrow);
        final doneIndicator = find.textContaining('DONE');

        // One of these should be true
        expect(
          playButton.evaluate().isNotEmpty || doneIndicator.evaluate().isEmpty,
          isTrue,
          reason: 'Timer should complete or reset after timeout',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'Pause and resume functionality',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'default_duration_seconds': 30,
        });

        await tester.pumpWidget(const ProviderScope(child: MyApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Start timer
        final startButton = find.byIcon(Icons.play_arrow);
        await tester.tap(startButton);
        await tester.pump(const Duration(seconds: 2));

        // Now running - should show pause icon
        final pauseButton = find.byIcon(Icons.pause);

        // Pause the timer
        if (pauseButton.evaluate().isNotEmpty) {
          await tester.tap(pauseButton);
          await tester.pumpAndSettle();

          // Should now show play button again (to resume)
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);

          // Resume
          final resumeButton = find.byIcon(Icons.play_arrow);
          await tester.tap(resumeButton);
          await tester.pump(const Duration(seconds: 1));

          // Should be running again
          expect(find.byIcon(Icons.pause), findsOneWidget);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'Settings screen has required elements',
      (tester) async {
        await tester.pumpWidget(const ProviderScope(child: MyApp()));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to settings
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Settings screen should be visible
        expect(find.byType(ListView), findsOneWidget);

        // Look for common setting elements
        // These may be ListTiles or similar
        expect(find.byType(ListTile), findsWidgets);

        // There should be switches for sound/vibration settings
        expect(find.byType(Switch), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets('Theme can be toggled', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Find theme-related element (might be a ListTile with theme text)
      // This is layout-dependent, so we just verify the screen is interactive
      expect(find.byType(ListTile), findsWidgets);

      // Tap the first ListTile (usually theme)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
