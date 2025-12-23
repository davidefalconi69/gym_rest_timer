import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_service.dart';

/// Provider for the FeedbackService singleton.
///
/// The service is lazily initialized when first accessed.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final service = FeedbackService.instance;

  // Clean up when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
