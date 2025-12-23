// Unit tests for Gym Rest Timer - Pure Logic Testing
//
// These tests verify the core business logic without any native plugin
// dependencies. They focus on:
// - Timer state model and calculations
// - Timer state event parsing
// - Settings model behavior
// - Settings repository with mocked SharedPreferences

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_rest_timer/core/settings.dart';
import 'package:gym_rest_timer/core/settings_repository.dart';
import 'package:gym_rest_timer/core/services/background_events.dart';
import 'package:gym_rest_timer/features/timer/providers/timer_state.dart';

import 'helpers/test_helpers.dart';

void main() {
  // ============================================================================
  // TIMER STATE TESTS
  // ============================================================================

  group('TimerState', () {
    group('initial factory', () {
      test('should create state with 90 seconds duration', () {
        final state = TimerState.initial();

        expect(state.totalDurationSeconds, 90);
        expect(state.remainingSeconds, 90);
        expect(state.phase, TimerPhase.ready);
      });

      test('should be in ready phase initially', () {
        final state = TimerState.initial();

        expect(state.isStopped, isTrue);
        expect(state.isRunning, isFalse);
        expect(state.isPaused, isFalse);
        expect(state.isDone, isFalse);
      });
    });

    group('progress calculation', () {
      test('should return 1.0 when timer is full', () {
        final state = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.ready,
        );

        expect(state.progress, 1.0);
      });

      test('should return 0.0 when timer is empty', () {
        final state = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 0,
          phase: TimerPhase.running,
        );

        expect(state.progress, 0.0);
      });

      test('should return 0.5 when timer is half done', () {
        final state = TimerState(
          totalDurationSeconds: 100,
          remainingSeconds: 50,
          phase: TimerPhase.running,
        );

        expect(state.progress, 0.5);
      });

      test('should return 1.0 during cooldown phase regardless of time', () {
        final state = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 0,
          phase: TimerPhase.cooldown,
        );

        expect(state.progress, 1.0);
      });

      test('should handle zero total duration without division error', () {
        final state = TimerState(
          totalDurationSeconds: 0,
          remainingSeconds: 0,
          phase: TimerPhase.ready,
        );

        expect(state.progress, 1.0);
      });
    });

    group('formattedTime', () {
      test('should format 90 seconds as 01:30', () {
        final state = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.ready,
        );

        expect(state.formattedTime, '01:30');
      });

      test('should format 5 seconds as 00:05', () {
        final state = TimerState(
          totalDurationSeconds: 5,
          remainingSeconds: 5,
          phase: TimerPhase.ready,
        );

        expect(state.formattedTime, '00:05');
      });

      test('should format 0 seconds as 00:00', () {
        final state = TimerState(
          totalDurationSeconds: 0,
          remainingSeconds: 0,
          phase: TimerPhase.ready,
        );

        expect(state.formattedTime, '00:00');
      });

      test('should format 3600 seconds as 60:00', () {
        final state = TimerState(
          totalDurationSeconds: 3600,
          remainingSeconds: 3600,
          phase: TimerPhase.ready,
        );

        expect(state.formattedTime, '60:00');
      });

      test('should format 65 seconds as 01:05', () {
        final state = TimerState(
          totalDurationSeconds: 65,
          remainingSeconds: 65,
          phase: TimerPhase.ready,
        );

        expect(state.formattedTime, '01:05');
      });
    });

    group('phase getters', () {
      test('isRunning should be true only in running phase', () {
        final running = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 45,
          phase: TimerPhase.running,
        );
        final paused = running.copyWith(phase: TimerPhase.paused);
        final ready = running.copyWith(phase: TimerPhase.ready);
        final cooldown = running.copyWith(phase: TimerPhase.cooldown);

        expect(running.isRunning, isTrue);
        expect(paused.isRunning, isFalse);
        expect(ready.isRunning, isFalse);
        expect(cooldown.isRunning, isFalse);
      });

      test('isPaused should be true only in paused phase', () {
        final paused = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 45,
          phase: TimerPhase.paused,
        );

        expect(paused.isPaused, isTrue);
        expect(paused.copyWith(phase: TimerPhase.running).isPaused, isFalse);
      });

      test('isDone should be true only in cooldown phase', () {
        final cooldown = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.cooldown,
        );

        expect(cooldown.isDone, isTrue);
        expect(cooldown.isCompleted, isTrue);
        expect(cooldown.copyWith(phase: TimerPhase.ready).isDone, isFalse);
      });

      test('isStopped should be true only in ready phase', () {
        final ready = TimerState(
          totalDurationSeconds: 90,
          remainingSeconds: 90,
          phase: TimerPhase.ready,
        );

        expect(ready.isStopped, isTrue);
        expect(ready.copyWith(phase: TimerPhase.running).isStopped, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final original = TimerState.initial();
        final copy = original.copyWith(
          totalDurationSeconds: 120,
          remainingSeconds: 60,
          phase: TimerPhase.running,
        );

        expect(copy.totalDurationSeconds, 120);
        expect(copy.remainingSeconds, 60);
        expect(copy.phase, TimerPhase.running);

        // Original should be unchanged (immutability)
        expect(original.totalDurationSeconds, 90);
        expect(original.remainingSeconds, 90);
        expect(original.phase, TimerPhase.ready);
      });

      test('should preserve unchanged fields', () {
        final original = TimerState(
          totalDurationSeconds: 120,
          remainingSeconds: 60,
          phase: TimerPhase.paused,
        );
        final copy = original.copyWith(phase: TimerPhase.running);

        expect(copy.totalDurationSeconds, 120);
        expect(copy.remainingSeconds, 60);
        expect(copy.phase, TimerPhase.running);
      });
    });
  });

  // ============================================================================
  // TIMER STATE EVENT TESTS
  // ============================================================================

  group('TimerStateEvent', () {
    group('fromMap', () {
      test('should parse valid map correctly', () {
        final map = {
          'status': 'running',
          'remainingSeconds': 45,
          'totalSeconds': 90,
          'timestamp': 1234567890,
        };

        final event = TimerStateEvent.fromMap(map);

        expect(event, isNotNull);
        expect(event!.status, 'running');
        expect(event.remainingSeconds, 45);
        expect(event.totalSeconds, 90);
        expect(event.timestamp, 1234567890);
      });

      test('should return null for null map', () {
        final event = TimerStateEvent.fromMap(null);

        expect(event, isNull);
      });

      test('should return null for map without status', () {
        final map = {'remainingSeconds': 45, 'totalSeconds': 90};

        final event = TimerStateEvent.fromMap(map);

        expect(event, isNull);
      });

      test('should use defaults for missing optional fields', () {
        final map = {'status': 'ready'};

        final event = TimerStateEvent.fromMap(map);

        expect(event, isNotNull);
        expect(event!.remainingSeconds, 0);
        expect(event.totalSeconds, 90);
      });
    });

    group('status getters', () {
      test('isRunning should work correctly', () {
        final running = createTestTimerStateEvent(status: 'running');
        final paused = createTestTimerStateEvent(status: 'paused');

        expect(running.isRunning, isTrue);
        expect(paused.isRunning, isFalse);
      });

      test('isPaused should work correctly', () {
        final paused = createTestTimerStateEvent(status: 'paused');
        final running = createTestTimerStateEvent(status: 'running');

        expect(paused.isPaused, isTrue);
        expect(running.isPaused, isFalse);
      });

      test('isReady should work correctly', () {
        final ready = createTestTimerStateEvent(status: 'ready');
        final running = createTestTimerStateEvent(status: 'running');

        expect(ready.isReady, isTrue);
        expect(running.isReady, isFalse);
      });

      test('isCooldown should work correctly', () {
        final cooldown = createTestTimerStateEvent(status: 'cooldown');
        final running = createTestTimerStateEvent(status: 'running');

        expect(cooldown.isCooldown, isTrue);
        expect(running.isCooldown, isFalse);
      });
    });
  });

  // ============================================================================
  // NOTIFICATION ACTION EVENT TESTS
  // ============================================================================

  group('NotificationActionEvent', () {
    group('fromMap', () {
      test('should parse valid action map', () {
        final map = {'action': 'pause', 'remainingSeconds': 45};

        final event = NotificationActionEvent.fromMap(map);

        expect(event, isNotNull);
        expect(event!.action, 'pause');
        expect(event.remainingSeconds, 45);
      });

      test('should return null for null map', () {
        final event = NotificationActionEvent.fromMap(null);
        expect(event, isNull);
      });

      test('should return null for map without action', () {
        final map = {'remainingSeconds': 45};
        final event = NotificationActionEvent.fromMap(map);
        expect(event, isNull);
      });

      test('should handle missing remainingSeconds', () {
        final map = {'action': 'stop'};
        final event = NotificationActionEvent.fromMap(map);

        expect(event, isNotNull);
        expect(event!.remainingSeconds, isNull);
      });
    });
  });

  // ============================================================================
  // TIMER COMPLETE EVENT TESTS
  // ============================================================================

  group('TimerCompleteEvent', () {
    test('isCompleteEvent should return true for complete event', () {
      final map = {'event': 'timerComplete'};
      expect(TimerCompleteEvent.isCompleteEvent(map), isTrue);
    });

    test('isCompleteEvent should return false for other events', () {
      final map = {'event': 'stateSync'};
      expect(TimerCompleteEvent.isCompleteEvent(map), isFalse);
    });

    test('isCompleteEvent should return false for null map', () {
      expect(TimerCompleteEvent.isCompleteEvent(null), isFalse);
    });
  });

  // ============================================================================
  // SETTINGS MODEL TESTS
  // ============================================================================

  group('Settings', () {
    group('initial factory', () {
      test('should create settings with correct defaults', () {
        final settings = Settings.initial();

        expect(settings.defaultDurationSeconds, 90);
        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.accentColor, isNull);
        expect(settings.monochromeAccent, isFalse);
        expect(settings.soundEnabled, isTrue);
        expect(settings.vibrationEnabled, isTrue);
        expect(settings.vibrateInSilentMode, isFalse);
        expect(settings.soundPath, 'default');
        expect(settings.locale, isNull);
      });
    });

    group('formattedDefaultDuration', () {
      test('should format 90 seconds as 01:30', () {
        final settings = Settings.initial();
        expect(settings.formattedDefaultDuration, '01:30');
      });

      test('should format 300 seconds as 05:00', () {
        final settings = Settings(
          defaultDurationSeconds: 300,
          themeMode: AppThemeMode.system,
        );
        expect(settings.formattedDefaultDuration, '05:00');
      });
    });

    group('copyWith', () {
      test('should update specified fields', () {
        final original = Settings.initial();
        final copy = original.copyWith(
          defaultDurationSeconds: 120,
          themeMode: AppThemeMode.dark,
        );

        expect(copy.defaultDurationSeconds, 120);
        expect(copy.themeMode, AppThemeMode.dark);
        expect(copy.soundEnabled, isTrue); // Preserved
      });

      test('should clear accentColor when clearAccentColor is true', () {
        final withColor = Settings(
          defaultDurationSeconds: 90,
          themeMode: AppThemeMode.system,
          accentColor: Colors.red,
        );
        final cleared = withColor.copyWith(clearAccentColor: true);

        expect(cleared.accentColor, isNull);
      });

      test('should clear locale when clearLocale is true', () {
        final withLocale = Settings(
          defaultDurationSeconds: 90,
          themeMode: AppThemeMode.system,
          locale: const Locale('it'),
        );
        final cleared = withLocale.copyWith(clearLocale: true);

        expect(cleared.locale, isNull);
      });
    });

    group('equality', () {
      test('identical settings should be equal', () {
        final a = Settings.initial();
        final b = Settings.initial();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different settings should not be equal', () {
        final a = Settings.initial();
        final b = a.copyWith(defaultDurationSeconds: 120);

        expect(a, isNot(equals(b)));
      });
    });
  });

  // ============================================================================
  // SETTINGS REPOSITORY TESTS (with mocked SharedPreferences)
  // ============================================================================

  group('SettingsRepository', () {
    late SettingsRepository repository;

    setUp(() async {
      await setupFakeSharedPreferences();
      final prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    group('loadSettings', () {
      test('should return defaults when preferences are empty', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.defaultDurationSeconds, 90);
        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.accentColor, isNull);
        expect(settings.soundEnabled, isTrue);
      });

      test('should load stored duration correctly', () async {
        await setupFakeSharedPreferences({'default_duration_seconds': 120});
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.defaultDurationSeconds, 120);
      });

      test('should load stored theme mode correctly', () async {
        await setupFakeSharedPreferences({
          'theme_mode': 2, // AppThemeMode.dark.index
        });
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.themeMode, AppThemeMode.dark);
      });

      test('should load stored accent color correctly', () async {
        const colorValue = 0xFFFF0000; // Red
        await setupFakeSharedPreferences({'accent_color': colorValue});
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.accentColor, isNotNull);
        expect(settings.accentColor!.toARGB32(), colorValue);
      });

      test('should load stored boolean settings correctly', () async {
        await setupFakeSharedPreferences({
          'sound_enabled': false,
          'vibration_enabled': false,
          'vibrate_in_silent_mode': true,
          'monochrome_accent': true,
        });
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.soundEnabled, isFalse);
        expect(settings.vibrationEnabled, isFalse);
        expect(settings.vibrateInSilentMode, isTrue);
        expect(settings.monochromeAccent, isTrue);
      });

      test('should load stored locale correctly', () async {
        await setupFakeSharedPreferences({'locale': 'it'});
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = repository.loadSettings();

        expect(settings.locale, equals(const Locale('it')));
      });
    });

    group('saveSettings', () {
      test('should save all settings to preferences', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        final settings = Settings(
          defaultDurationSeconds: 120,
          themeMode: AppThemeMode.amoled,
          accentColor: Colors.blue,
          monochromeAccent: false,
          soundEnabled: false,
          vibrationEnabled: true,
          vibrateInSilentMode: true,
          soundPath: '/custom/sound.mp3',
          locale: const Locale('en'),
        );

        await repository.saveSettings(settings);

        // Verify by loading back
        final loaded = repository.loadSettings();
        expect(loaded.defaultDurationSeconds, 120);
        expect(loaded.themeMode, AppThemeMode.amoled);
        expect(loaded.accentColor, isNotNull);
        expect(loaded.soundEnabled, isFalse);
        expect(loaded.vibrateInSilentMode, isTrue);
        expect(loaded.soundPath, '/custom/sound.mp3');
        expect(loaded.locale, equals(const Locale('en')));
      });

      test('should remove accent color when null', () async {
        // First save with color
        await setupFakeSharedPreferences({'accent_color': 0xFFFF0000});
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        // Save with null color
        await repository.saveSettings(Settings.initial());

        final loaded = repository.loadSettings();
        expect(loaded.accentColor, isNull);
      });
    });

    group('individual save methods', () {
      test('saveDefaultDuration should update only duration', () async {
        await setupFakeSharedPreferences({
          'default_duration_seconds': 90,
          'sound_enabled': false,
        });
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        await repository.saveDefaultDuration(180);

        final settings = repository.loadSettings();
        expect(settings.defaultDurationSeconds, 180);
        expect(settings.soundEnabled, isFalse); // Other values preserved
      });

      test('saveThemeMode should update only theme mode', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        await repository.saveThemeMode(AppThemeMode.dark);

        final settings = repository.loadSettings();
        expect(settings.themeMode, AppThemeMode.dark);
      });

      test('saveMonochromeAccent should update correctly', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        await repository.saveMonochromeAccent(true);

        final settings = repository.loadSettings();
        expect(settings.monochromeAccent, isTrue);
      });

      test('saveSoundEnabled should update correctly', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        await repository.saveSoundEnabled(false);

        final settings = repository.loadSettings();
        expect(settings.soundEnabled, isFalse);
      });

      test('saveLocale should update and clear correctly', () async {
        await setupFakeSharedPreferences();
        final prefs = await SharedPreferences.getInstance();
        repository = SettingsRepository(prefs);

        // Save locale
        await repository.saveLocale(const Locale('it'));
        var settings = repository.loadSettings();
        expect(settings.locale, equals(const Locale('it')));

        // Clear locale
        await repository.saveLocale(null);
        settings = repository.loadSettings();
        expect(settings.locale, isNull);
      });
    });
  });

  // ============================================================================
  // MOCK BACKGROUND SERVICE TESTS
  // ============================================================================

  group('MockBackgroundTimerService', () {
    late MockBackgroundTimerService mockService;

    setUp(() {
      mockService = MockBackgroundTimerService();
    });

    tearDown(() {
      mockService.dispose();
    });

    test('should initialize correctly', () async {
      expect(mockService.isInitialized, isFalse);

      await mockService.init();

      expect(mockService.isInitialized, isTrue);
      expect(mockService.currentStatus, 'ready');
    });

    test('should start timer and count down', () async {
      await mockService.init();

      final events = <Map<String, dynamic>>[];
      mockService.events.listen(events.add);

      await mockService.startService(totalSeconds: 3, remainingSeconds: 3);

      // Wait for a couple ticks
      await Future.delayed(const Duration(milliseconds: 2500));

      expect(mockService.currentStatus, 'running');
      expect(events.isNotEmpty, isTrue);
      // Should have counted down at least once
      final lastEvent = events.last;
      expect(lastEvent['remainingSeconds'], lessThan(3));
    });

    test('should pause and resume timer', () async {
      await mockService.init();

      await mockService.startService(totalSeconds: 10, remainingSeconds: 10);
      expect(mockService.currentStatus, 'running');

      mockService.pauseTimer();
      expect(mockService.currentStatus, 'paused');

      mockService.resumeTimer();
      expect(mockService.currentStatus, 'running');
    });

    test('should reset timer', () async {
      await mockService.init();

      await mockService.startService(totalSeconds: 10, remainingSeconds: 10);
      mockService.resetTimer();

      expect(mockService.currentStatus, 'ready');
    });

    test('should update duration', () async {
      await mockService.init();

      final events = <Map<String, dynamic>>[];
      mockService.events.listen(events.add);

      mockService.updateDuration(120);

      // Should broadcast new state
      await Future.delayed(const Duration(milliseconds: 100));
      expect(events.isNotEmpty, isTrue);
      expect(events.last['totalSeconds'], 120);
    });
  });

  // ============================================================================
  // SSOT SYNCHRONIZATION TESTS (Critical Path)
  // ============================================================================
  //
  // These tests verify the Single Source of Truth architecture:
  // - Background Service broadcasts state
  // - UI listens and updates accordingly
  // - Commands flow uni-directionally from UI to Service
  // ============================================================================

  group('SSOT State Synchronization', () {
    late MockBackgroundTimerService mockService;

    setUp(() async {
      mockService = MockBackgroundTimerService();
      await mockService.init();
    });

    tearDown(() {
      mockService.dispose();
    });

    test(
      'stateSync(running) should update TimerState to running phase',
      () async {
        // Arrange: collect events from service
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);

        // Act: start the timer (service broadcasts 'running' state)
        await mockService.startService(totalSeconds: 30, remainingSeconds: 30);

        // Assert: verify service broadcasted correct state
        await Future.delayed(const Duration(milliseconds: 100));
        expect(events.isNotEmpty, isTrue);
        final lastEvent = events.last;
        expect(lastEvent['status'], 'running');
        expect(lastEvent['remainingSeconds'], 30);

        // Parse as TimerStateEvent (what TimerNotifier does)
        final stateEvent = TimerStateEvent.fromMap(lastEvent);
        expect(stateEvent, isNotNull);
        expect(stateEvent!.isRunning, isTrue);
        expect(stateEvent.isPaused, isFalse);
      },
    );

    test(
      'stateSync(paused) should update TimerState to paused phase',
      () async {
        // Arrange
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);
        await mockService.startService(totalSeconds: 30, remainingSeconds: 30);
        events.clear();

        // Act: pause the timer
        mockService.pauseTimer();

        // Assert: verify service broadcasted 'paused' state
        await Future.delayed(const Duration(milliseconds: 100));
        expect(events.isNotEmpty, isTrue);
        final lastEvent = events.last;
        expect(lastEvent['status'], 'paused');

        final stateEvent = TimerStateEvent.fromMap(lastEvent);
        expect(stateEvent, isNotNull);
        expect(stateEvent!.isPaused, isTrue);
        expect(stateEvent.isRunning, isFalse);
      },
    );

    test(
      'stateSync(cooldown) should update TimerState to cooldown phase',
      () async {
        // Arrange: start a very short timer (1 second)
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);
        await mockService.startService(totalSeconds: 1, remainingSeconds: 1);

        // Act: wait for timer to complete (enters cooldown)
        await Future.delayed(const Duration(milliseconds: 1500));

        // Assert: verify service broadcasted 'cooldown' state
        final cooldownEvents = events.where((e) => e['status'] == 'cooldown');
        expect(cooldownEvents.isNotEmpty, isTrue);

        final cooldownEvent = cooldownEvents.first;
        final stateEvent = TimerStateEvent.fromMap(cooldownEvent);
        expect(stateEvent, isNotNull);
        expect(stateEvent!.isCooldown, isTrue);
      },
    );

    test(
      'Restart action resets remainingSeconds and broadcasts running',
      () async {
        // Arrange: start timer and let it run for a bit
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);
        await mockService.startService(totalSeconds: 30, remainingSeconds: 20);
        await Future.delayed(const Duration(milliseconds: 500));
        events.clear();

        // Act: reset the timer (simulates restart action)
        mockService.resetTimer();

        // Assert: timer is reset to ready state with full duration
        await Future.delayed(const Duration(milliseconds: 100));
        expect(events.isNotEmpty, isTrue);
        final lastEvent = events.last;
        expect(lastEvent['status'], 'ready');
        expect(lastEvent['remainingSeconds'], 30); // Reset to totalSeconds
      },
    );

    test(
      'Duration update broadcasts new totalSeconds when in ready state',
      () async {
        // Arrange
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);
        await Future.delayed(const Duration(milliseconds: 100));
        events.clear();

        // Act: update duration
        mockService.updateDuration(180);

        // Assert: new duration is broadcasted
        await Future.delayed(const Duration(milliseconds: 100));
        expect(events.isNotEmpty, isTrue);
        final lastEvent = events.last;
        expect(lastEvent['totalSeconds'], 180);
        expect(lastEvent['remainingSeconds'], 180);
      },
    );

    test(
      'Pause command results in paused state (Split Brain prevention)',
      () async {
        // This test verifies the key SSOT invariant:
        // When pause is commanded, the service state becomes 'paused'
        // and the UI should receive this state, NOT continue with 'running'

        // Arrange
        final events = <Map<String, dynamic>>[];
        mockService.events.listen(events.add);
        await mockService.startService(totalSeconds: 60, remainingSeconds: 60);
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify timer is running
        expect(mockService.currentStatus, 'running');
        events.clear();

        // Act: send pause command
        mockService.pauseTimer();

        // Assert: service state is immediately 'paused'
        expect(mockService.currentStatus, 'paused');

        // Assert: pause state was broadcasted
        await Future.delayed(const Duration(milliseconds: 100));
        expect(events.isNotEmpty, isTrue);
        final pauseEvent = events.firstWhere(
          (e) => e['status'] == 'paused',
          orElse: () => <String, dynamic>{},
        );
        expect(pauseEvent.isNotEmpty, isTrue);

        // Verify the event can be parsed correctly
        final stateEvent = TimerStateEvent.fromMap(pauseEvent);
        expect(stateEvent, isNotNull);
        expect(stateEvent!.isPaused, isTrue);
        expect(stateEvent.isRunning, isFalse);
      },
    );
  });

  // ============================================================================
  // TIMER STATE PHASE TRANSITIONS
  // ============================================================================

  group('TimerState Phase Transitions', () {
    test('should transition from ready to running', () {
      final ready = TimerState.initial();
      expect(ready.phase, TimerPhase.ready);
      expect(ready.isStopped, isTrue);

      final running = ready.copyWith(phase: TimerPhase.running);
      expect(running.phase, TimerPhase.running);
      expect(running.isRunning, isTrue);
      expect(running.isStopped, isFalse);
    });

    test('should transition from running to paused', () {
      final running = TimerState(
        totalDurationSeconds: 90,
        remainingSeconds: 45,
        phase: TimerPhase.running,
      );

      final paused = running.copyWith(phase: TimerPhase.paused);
      expect(paused.phase, TimerPhase.paused);
      expect(paused.isPaused, isTrue);
      expect(paused.remainingSeconds, 45); // Preserved
    });

    test('should transition from running to cooldown when timer completes', () {
      // Arrange: timer is running with 1 second left
      final running = TimerState(
        totalDurationSeconds: 90,
        remainingSeconds: 1,
        phase: TimerPhase.running,
      );
      expect(running.isRunning, isTrue); // Verify starting state

      // Timer completes -> goes to cooldown with reset time
      final cooldown = TimerState(
        totalDurationSeconds: 90,
        remainingSeconds: 90, // Reset to full
        phase: TimerPhase.cooldown,
      );

      expect(cooldown.phase, TimerPhase.cooldown);
      expect(cooldown.isDone, isTrue);
      expect(cooldown.isCompleted, isTrue);
      expect(cooldown.remainingSeconds, 90);
    });

    test('should transition from cooldown back to ready', () {
      final cooldown = TimerState(
        totalDurationSeconds: 90,
        remainingSeconds: 90,
        phase: TimerPhase.cooldown,
      );

      final ready = cooldown.copyWith(phase: TimerPhase.ready);
      expect(ready.phase, TimerPhase.ready);
      expect(ready.isStopped, isTrue);
      expect(ready.isDone, isFalse);
    });

    test('should transition from paused back to running', () {
      final paused = TimerState(
        totalDurationSeconds: 90,
        remainingSeconds: 30,
        phase: TimerPhase.paused,
      );

      final running = paused.copyWith(phase: TimerPhase.running);
      expect(running.phase, TimerPhase.running);
      expect(running.isRunning, isTrue);
      expect(running.remainingSeconds, 30); // Preserved
    });
  });

  // ============================================================================
  // NOTIFICATION ACTION EVENT HANDLING
  // ============================================================================

  group('NotificationActionEvent Handling', () {
    test('pause action should be parseable from map', () {
      final map = {'action': 'pause', 'remainingSeconds': 45};
      final event = NotificationActionEvent.fromMap(map);

      expect(event, isNotNull);
      expect(event!.action, 'pause');
      expect(event.remainingSeconds, 45);
    });

    test('resume action should be parseable from map', () {
      final map = {'action': 'resume', 'remainingSeconds': 45};
      final event = NotificationActionEvent.fromMap(map);

      expect(event, isNotNull);
      expect(event!.action, 'resume');
    });

    test('restart action should be parseable from map', () {
      final map = {'action': 'restart', 'remainingSeconds': 90};
      final event = NotificationActionEvent.fromMap(map);

      expect(event, isNotNull);
      expect(event!.action, 'restart');
      expect(event.remainingSeconds, 90);
    });

    test('start action should be parseable from map', () {
      final map = {'action': 'start', 'remainingSeconds': 90};
      final event = NotificationActionEvent.fromMap(map);

      expect(event, isNotNull);
      expect(event!.action, 'start');
    });

    test('stop action should be parseable from map', () {
      final map = {'action': 'stop'};
      final event = NotificationActionEvent.fromMap(map);

      expect(event, isNotNull);
      expect(event!.action, 'stop');
      expect(event.remainingSeconds, isNull);
    });
  });
}
