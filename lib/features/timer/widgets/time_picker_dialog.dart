import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gym_rest_timer/l10n/app_localizations.dart';

/// A Cupertino-style time picker dialog for selecting rest duration.
///
/// This dialog shows two scrollable pickers: one for minutes, one for seconds.
/// The user can spin through values and tap "Done" to confirm their selection.
///
/// We use Cupertino pickers because they feel intuitive for time selection -
/// that familiar iOS-style wheel that users love.
///
/// Named "RestTimePickerDialog" to avoid collision with Flutter's built-in TimePickerDialog.
class RestTimePickerDialog extends StatefulWidget {
  /// The initial duration to show when the dialog opens.
  final int initialSeconds;

  /// Maximum minutes allowed (default 99 for "99:59" max).
  final int maxMinutes;

  const RestTimePickerDialog({
    super.key,
    required this.initialSeconds,
    this.maxMinutes = 99,
  });

  /// Convenience method to show the dialog and get the result.
  ///
  /// Returns the selected duration in seconds, or null if cancelled.
  static Future<int?> show(
    BuildContext context, {
    required int initialSeconds,
  }) {
    return showDialog<int>(
      context: context,
      builder: (context) =>
          RestTimePickerDialog(initialSeconds: initialSeconds),
    );
  }

  @override
  State<RestTimePickerDialog> createState() => _RestTimePickerDialogState();
}

class _RestTimePickerDialogState extends State<RestTimePickerDialog> {
  late int _selectedMinutes;
  late int _selectedSeconds;

  // Controllers for the picker wheels - needed to set initial scroll position.
  late FixedExtentScrollController _minutesController;
  late FixedExtentScrollController _secondsController;

  @override
  void initState() {
    super.initState();

    // Convert initial seconds to minutes:seconds format.
    _selectedMinutes = widget.initialSeconds ~/ 60;
    _selectedSeconds = widget.initialSeconds % 60;

    // Create controllers starting at the correct positions.
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes,
    );
    _secondsController = FixedExtentScrollController(
      initialItem: _selectedSeconds,
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.setRestTime,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minutes picker
            _buildPicker(
              controller: _minutesController,
              itemCount: widget.maxMinutes + 1, // 0 to maxMinutes
              label: 'min',
              onChanged: (value) => _selectedMinutes = value,
              theme: theme,
            ),

            // Colon separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // Seconds picker
            _buildPicker(
              controller: _secondsController,
              itemCount: 60, // 0 to 59
              label: 'sec',
              onChanged: (value) => _selectedSeconds = value,
              theme: theme,
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button - returns null
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context)!.actionCancel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),

        // Done button - returns the selected duration
        FilledButton(
          onPressed: () {
            // Convert back to total seconds
            final totalSeconds = (_selectedMinutes * 60) + _selectedSeconds;

            // Ensure at least 1 second is selected
            final validSeconds = totalSeconds < 1 ? 1 : totalSeconds;

            Navigator.of(context).pop(validSeconds);
          },
          child: Text(AppLocalizations.of(context)!.actionDone),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
    );
  }

  /// Builds a single Cupertino-style picker column.
  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String label,
    required ValueChanged<int> onChanged,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The label above the picker
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // The scrollable picker wheel
        SizedBox(
          height: 150,
          width: 70,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 40,
            diameterRatio: 1.2,
            squeeze: 1.0,
            onSelectedItemChanged: onChanged,
            selectionOverlay: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
            ),
            children: List.generate(
              itemCount,
              (index) => Center(
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
