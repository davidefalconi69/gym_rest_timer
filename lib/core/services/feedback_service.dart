import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:vibration/vibration.dart';

import '../settings.dart';

/// Service responsible for playing sound and vibration feedback when timer ends.
///
/// This service handles:
/// - Audio playback with proper AudioContext configuration
/// - Vibration with custom patterns
/// - Silent/DND mode detection and respect
/// - Audio ducking (lowers other audio instead of stopping it)
class FeedbackService {
  // Singleton instance
  static FeedbackService? _instance;
  static FeedbackService get instance => _instance ??= FeedbackService._();

  FeedbackService._();

  /// The audio player instance - lazily initialized.
  AudioPlayer? _audioPlayer;

  /// Initialize the audio player with proper configuration.
  Future<void> init() async {
    _audioPlayer = AudioPlayer();

    // Configure audio context for proper mixing with other audio sources.
    // This ensures our beep ducks (lowers volume of) Spotify instead of stopping it.
    await _audioPlayer!.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  /// Play feedback (sound and/or vibration) when timer completes.
  ///
  /// Respects user settings and device silent/DND mode:
  /// - If NOT in silent mode: plays sound (if enabled) and vibrates (if enabled)
  /// - If IN silent mode: no sound, vibrates only if vibrateInSilentMode is true
  Future<void> playTimerEndFeedback(Settings settings) async {
    final isInSilentMode = await _checkSilentMode();

    if (isInSilentMode) {
      // In silent/DND mode
      debugPrint('FeedbackService: Device is in silent mode');
      if (settings.vibrateInSilentMode && settings.vibrationEnabled) {
        await _vibrate();
      }
    } else {
      // Normal mode - play sound and vibrate based on settings
      if (settings.soundEnabled) {
        await _playSound(settings.soundPath);
      }
      if (settings.vibrationEnabled) {
        await _vibrate();
      }
    }
  }

  /// Check if device is in silent or DND mode.
  Future<bool> _checkSilentMode() async {
    try {
      final ringerStatus = await SoundMode.ringerModeStatus;
      // Silent or Vibrate mode both count as "silent" for our purposes
      return ringerStatus == RingerModeStatus.silent ||
          ringerStatus == RingerModeStatus.vibrate;
    } catch (e) {
      // If we can't check, assume normal mode (play sound)
      debugPrint('FeedbackService: Could not check ringer mode: $e');
      return false;
    }
  }

  /// Play the timer end sound.
  ///
  /// If [soundPath] is 'default', plays the bundled beep.mp3 asset.
  /// Otherwise, attempts to play the custom file at [soundPath].
  /// If custom file playback fails (deleted/corrupted), falls back to default.
  Future<void> _playSound(String soundPath) async {
    try {
      // Ensure player is initialized
      if (_audioPlayer == null) {
        await init();
      }

      // Set volume to max (1.0) for reliable timer notification
      await _audioPlayer!.setVolume(1.0);

      if (soundPath == 'default') {
        // Play bundled asset
        await _audioPlayer!.play(AssetSource('sounds/beep.mp3'));
        debugPrint('FeedbackService: Playing default beep');
      } else {
        // Play custom file from device storage
        try {
          await _audioPlayer!.play(DeviceFileSource(soundPath));
          debugPrint('FeedbackService: Playing custom sound: $soundPath');
        } catch (e) {
          // Custom file failed (deleted, corrupted, etc.) - fallback to default
          debugPrint(
            'FeedbackService: Custom sound failed ($e), falling back to default',
          );
          await _audioPlayer!.play(AssetSource('sounds/beep.mp3'));
        }
      }
    } catch (e) {
      debugPrint('FeedbackService: Error playing sound: $e');
    }
  }

  /// Trigger vibration feedback.
  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        debugPrint('FeedbackService: Device does not have vibrator');
        return;
      }

      // Check if device supports custom vibration patterns
      final hasAmplitudeControl = await Vibration.hasAmplitudeControl();

      if (hasAmplitudeControl) {
        // Custom pattern: two quick bursts
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200],
          intensities: [0, 255, 0, 255],
        );
      } else {
        // Fallback: simple vibration
        await Vibration.vibrate(duration: 500);
      }
      debugPrint('FeedbackService: Vibration triggered');
    } catch (e) {
      debugPrint('FeedbackService: Error triggering vibration: $e');
    }
  }

  /// Dispose of resources.
  Future<void> dispose() async {
    await _audioPlayer?.dispose();
    _audioPlayer = null;
    _instance = null;
  }
}
