import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provider for notification permission status.
///
/// This provider tracks the current notification permission status and provides
/// methods to check and request the permission. It's used by SettingsScreen to
/// show a warning when notifications are disabled.
final notificationPermissionProvider =
    NotifierProvider<NotificationPermissionNotifier, PermissionStatus>(
      NotificationPermissionNotifier.new,
    );

/// Notifier that manages notification permission state.
class NotificationPermissionNotifier extends Notifier<PermissionStatus> {
  @override
  PermissionStatus build() {
    // Check status on initialization (async, so we start with granted and update)
    _checkStatusAsync();
    return PermissionStatus.granted;
  }

  /// Check status asynchronously and update state.
  Future<void> _checkStatusAsync() async {
    final status = await Permission.notification.status;
    state = status;
  }

  /// Check the current notification permission status.
  ///
  /// This should be called:
  /// - On initialization
  /// - When the app resumes from background (user might have changed settings)
  Future<void> checkStatus() async {
    final status = await Permission.notification.status;
    state = status;
  }

  /// Request notification permission or open app settings.
  ///
  /// On Android 13+, after the first denial, the system won't show
  /// the permission dialog again. We must open app settings instead.
  ///
  /// Returns the new permission status after the request.
  Future<PermissionStatus> requestPermission() async {
    // First, get the current actual status
    final currentStatus = await Permission.notification.status;

    if (currentStatus.isGranted) {
      // Already granted, just update state
      state = currentStatus;
      return currentStatus;
    }

    if (currentStatus.isPermanentlyDenied || currentStatus.isDenied) {
      // On Android 13+, once denied, we can't show the dialog again.
      // Try requesting first - if it fails silently, open settings.
      final newStatus = await Permission.notification.request();

      if (newStatus == currentStatus) {
        // Request didn't change anything (dialog wasn't shown)
        // Open app settings instead
        await openAppSettings();
        // Re-check status after returning from settings
        await checkStatus();
        return state;
      } else {
        state = newStatus;
        return newStatus;
      }
    }

    // For any other status, try requesting normally
    final newStatus = await Permission.notification.request();
    state = newStatus;
    return newStatus;
  }
}
