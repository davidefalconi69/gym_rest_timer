import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gym_rest_timer/l10n/app_localizations.dart';

import 'package:gym_rest_timer/core/theme.dart';

/// Result from the AccentColorPickerDialog.
sealed class AccentColorResult {}

class AccentColorDefault extends AccentColorResult {}

class AccentColorMonochrome extends AccentColorResult {}

class AccentColorCustom extends AccentColorResult {
  final Color color;
  AccentColorCustom(this.color);
}

/// Dialog for picking an accent color using flex_color_picker.
///
/// Shows preset colors, custom color wheel, and specialized modes (Default, Monochrome).
class AccentColorPickerDialog extends StatefulWidget {
  /// Currently selected color (null = default).
  final Color? currentColor;
  final bool isMonochrome;

  const AccentColorPickerDialog({
    super.key,
    this.currentColor,
    this.isMonochrome = false,
  });

  /// Show the dialog and return the result.
  /// Returns null if cancelled.
  static Future<AccentColorResult?> show(
    BuildContext context, {
    Color? currentColor,
    bool isMonochrome = false,
  }) {
    return showDialog<AccentColorResult?>(
      context: context,
      builder: (context) => AccentColorPickerDialog(
        currentColor: currentColor,
        isMonochrome: isMonochrome,
      ),
    );
  }

  @override
  State<AccentColorPickerDialog> createState() =>
      _AccentColorPickerDialogState();
}

class _AccentColorPickerDialogState extends State<AccentColorPickerDialog> {
  late Color _selectedCustomColor;
  late _SelectionMode _mode;

  @override
  void initState() {
    super.initState();
    _selectedCustomColor = widget.currentColor ?? AppTheme.defaultPrimaryColor;

    if (widget.isMonochrome) {
      _mode = _SelectionMode.monochrome;
    } else if (widget.currentColor == null) {
      _mode = _SelectionMode.defaults;
    } else {
      _mode = _SelectionMode.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.accentColor,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selection
            _buildModeOption(
              context,
              mode: _SelectionMode.defaults,
              title: AppLocalizations.of(context)!.accentDefault,
              icon: Icon(Icons.circle, color: AppTheme.defaultPrimaryColor),
            ),
            _buildModeOption(
              context,
              mode: _SelectionMode.monochrome,
              title: AppLocalizations.of(context)!.themeMonochrome,
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.5, 0.5],
                    transform: GradientRotation(3.14 / 4), // 45 degrees
                  ),
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
            _buildModeOption(
              context,
              mode: _SelectionMode.custom,
              title: AppLocalizations.of(context)!.accentCustom,
              icon: const Icon(Icons.palette),
              showEditIcon: true,
            ),

            const Gap(16),

            // Color picker (visible only when custom is selected)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: ColorPicker(
                color: _selectedCustomColor,
                onColorChanged: (Color color) {
                  setState(() {
                    _selectedCustomColor = color;
                    _mode = _SelectionMode.custom; // Ensure mode stays custom
                  });
                },
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.primary: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.wheel: true,
                },
                enableShadesSelection: false,
                width: 40,
                height: 40,
                borderRadius: 20,
                heading: Text(
                  AppLocalizations.of(context)!.dialogTitleSelectColor,
                  style: theme.textTheme.titleSmall,
                ),
                wheelSubheading: Text(
                  AppLocalizations.of(context)!.dialogSubheadingCustomColor,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              crossFadeState: _mode == _SelectionMode.custom
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Returns null (Cancel)
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            switch (_mode) {
              case _SelectionMode.defaults:
                Navigator.of(context).pop(AccentColorDefault());
                break;
              case _SelectionMode.monochrome:
                Navigator.of(context).pop(AccentColorMonochrome());
                break;
              case _SelectionMode.custom:
                Navigator.of(
                  context,
                ).pop(AccentColorCustom(_selectedCustomColor));
                break;
            }
          },
          child: Text(AppLocalizations.of(context)!.actionDone),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required _SelectionMode mode,
    required String title,
    required Widget icon,
    bool showEditIcon = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = _mode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _mode = mode;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            icon,
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected && showEditIcon)
              Icon(Icons.edit, size: 16, color: theme.colorScheme.primary)
            else if (isSelected)
              Icon(Icons.check, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

enum _SelectionMode { defaults, monochrome, custom }
