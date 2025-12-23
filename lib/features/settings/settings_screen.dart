import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gym_rest_timer/l10n/app_localizations.dart';

import '../../core/notification_permission_provider.dart';
import '../../core/settings.dart';
import '../../core/settings_provider.dart';
import '../../core/theme.dart';
import '../timer/widgets/time_picker_dialog.dart';
import 'widgets/accent_color_picker_dialog.dart';

/// Settings screen with clean list layout.
///
/// Options:
/// - Timer Duration (opens time picker)
/// - Notification (Sound, Vibration, Silent Mode, Sound Type)
/// - Appearance (Theme Mode selector, Accent Color picker)
/// - Donations (Buy me a coffee link)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  // Ko-fi link
  static const String _kofiUrl = 'https://ko-fi.com/davidefalconi';

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check permission when app resumes (user might have changed it in settings)
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationPermissionProvider.notifier).checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch settings for reactive UI
    final settingsAsync = ref.watch(settingsProvider);

    // Watch notification permission status
    final permissionStatus = ref.watch(notificationPermissionProvider);
    final showPermissionWarning =
        permissionStatus.isDenied || permissionStatus.isPermanentlyDenied;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading settings: $error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Notification Permission Warning Card
            if (showPermissionWarning)
              _buildPermissionWarningCard(context, permissionStatus),

            // Timer Section
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sectionTimer,
            ),
            _buildTimerDurationTile(context, ref, settings),

            const Gap(16),

            // Notification Section
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sectionNotification,
            ),
            _buildSoundToggleTile(context, ref, settings),
            _buildVibrationToggleTile(context, ref, settings),
            _buildVibrateInSilentTile(context, ref, settings),
            _buildSoundTypeTile(context, ref, settings),

            const Gap(16),

            // Appearance Section
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sectionAppearance,
            ),
            _buildThemeModeTile(context, ref, settings),
            _buildAccentColorTile(context, ref, settings),

            const Gap(16),

            // Other Section (Language)
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sectionOther,
            ),
            _buildLanguageTile(context, ref, settings),

            const Gap(16),

            // Support Section
            _buildSectionHeader(
              context,
              AppLocalizations.of(context)!.sectionSupport,
            ),
            _buildDonationTile(context),
            _buildLicensesTile(context),
            _buildAboutTile(context),
          ],
        ),
      ),
    );
  }

  /// Builds the notification permission warning card.
  ///
  /// Shows when notifications are disabled, asking the user to enable them.
  Widget _buildPermissionWarningCard(
    BuildContext context,
    PermissionStatus status,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: theme.colorScheme.onErrorContainer,
            ),
            const Gap(16),
            Expanded(
              child: Text(
                loc.notificationPermissionWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const Gap(8),
            FilledButton.tonal(
              onPressed: () {
                ref
                    .read(notificationPermissionProvider.notifier)
                    .requestPermission();
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              child: Text(loc.notificationEnableButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTimerDurationTile(
    BuildContext context,
    WidgetRef ref,
    settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: Text(AppLocalizations.of(context)!.defaultDuration),
      subtitle: Text(settings.formattedDefaultDuration),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final selectedSeconds = await RestTimePickerDialog.show(
          context,
          initialSeconds: settings.defaultDurationSeconds,
        );

        if (selectedSeconds != null) {
          ref
              .read(settingsProvider.notifier)
              .setDefaultDuration(selectedSeconds);
        }
      },
    );
  }

  // --- Notification Settings ---

  Widget _buildSoundToggleTile(BuildContext context, WidgetRef ref, settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.volume_up_outlined),
      title: Text(AppLocalizations.of(context)!.settingSound),
      subtitle: Text(AppLocalizations.of(context)!.settingSoundDesc),
      value: settings.soundEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setSoundEnabled(value);
      },
    );
  }

  Widget _buildVibrationToggleTile(
    BuildContext context,
    WidgetRef ref,
    settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.vibration),
      title: Text(AppLocalizations.of(context)!.settingVibration),
      subtitle: Text(AppLocalizations.of(context)!.settingVibrationDesc),
      value: settings.vibrationEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setVibrationEnabled(value);
      },
    );
  }

  Widget _buildVibrateInSilentTile(
    BuildContext context,
    WidgetRef ref,
    settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.do_not_disturb_on_outlined),
      title: Text(AppLocalizations.of(context)!.settingVibrateSilent),
      subtitle: Text(AppLocalizations.of(context)!.settingVibrateSilentDesc),
      value: settings.vibrateInSilentMode,
      onChanged: settings.vibrationEnabled
          ? (value) {
              ref.read(settingsProvider.notifier).setVibrateInSilentMode(value);
            }
          : null, // Disabled if vibration is off
    );
  }

  Widget _buildSoundTypeTile(BuildContext context, WidgetRef ref, settings) {
    return ListTile(
      leading: const Icon(Icons.music_note_outlined),
      title: Text(AppLocalizations.of(context)!.settingSoundType),
      subtitle: Text(_getSoundPathLabel(context, settings.soundPath)),
      trailing: const Icon(Icons.chevron_right),
      enabled: settings.soundEnabled, // Disabled if sound is off
      onTap: settings.soundEnabled
          ? () => _showSoundSelectionSheet(context, ref, settings.soundPath)
          : null,
    );
  }

  void _showSoundSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    String currentSoundPath,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppLocalizations.of(context)!.selectSound,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

            // Default Beep option
            ListTile(
              leading: const Icon(Icons.music_note),
              title: Text(AppLocalizations.of(context)!.defaultBeep),
              subtitle: Text(AppLocalizations.of(context)!.defaultBeepDesc),
              trailing: currentSoundPath == 'default'
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setSoundPath('default');
                Navigator.pop(context);
              },
            ),

            // Pick from device option
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(AppLocalizations.of(context)!.pickFromDevice),
              subtitle: Text(AppLocalizations.of(context)!.pickFromDeviceDesc),
              onTap: () async {
                Navigator.pop(context);
                await _pickCustomSound(context, ref);
              },
            ),

            const Gap(8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomSound(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        ref.read(settingsProvider.notifier).setSoundPath(path);
      }
    } catch (e) {
      // Show error snackbar if file picking fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorPickSound(e.toString()),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getSoundPathLabel(BuildContext context, String soundPath) {
    if (soundPath == 'default') {
      return AppLocalizations.of(context)!.defaultBeep;
    }
    // Extract filename from path
    return p.basename(soundPath);
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, settings) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(AppLocalizations.of(context)!.language),
      subtitle: Text(_getLanguageLabel(context, settings.locale)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageSelectionSheet(context, ref, settings.locale),
    );
  }

  void _showLanguageSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                loc.language,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

            // System Default
            ListTile(
              leading: const Icon(Icons.settings_system_daydream),
              title: Text(loc.systemDefault),
              trailing: currentLocale == null
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(null);
                Navigator.pop(context);
              },
            ),

            // English
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: currentLocale?.languageCode == 'en'
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),

            // Italian
            ListTile(
              leading: const Text('🇮🇹', style: TextStyle(fontSize: 24)),
              title: const Text('Italiano'),
              trailing: currentLocale?.languageCode == 'it'
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setLocale(const Locale('it'));
                Navigator.pop(context);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  String _getLanguageLabel(BuildContext context, Locale? locale) {
    if (locale == null) return AppLocalizations.of(context)!.systemDefault;
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'it':
        return 'Italiano';
      default:
        return locale.languageCode;
    }
  }

  // --- Appearance Settings ---

  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref, settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: Text(AppLocalizations.of(context)!.theme),
      subtitle: Text(_themeModeLabel(context, settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeSelectionDialog(context, ref, settings.themeMode),
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode currentMode,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                loc.theme,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

            // Wrap options in RadioGroup
            RadioGroup<AppThemeMode>(
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // System Default
                  RadioListTile<AppThemeMode>(
                    title: Text(loc.themeSystem),
                    secondary: const Icon(Icons.brightness_auto),
                    value: AppThemeMode.system,
                  ),

                  // Light
                  RadioListTile<AppThemeMode>(
                    title: Text(loc.themeLight),
                    secondary: const Icon(Icons.light_mode),
                    value: AppThemeMode.light,
                  ),

                  // Dark
                  RadioListTile<AppThemeMode>(
                    title: Text(loc.themeDark),
                    secondary: const Icon(Icons.dark_mode),
                    value: AppThemeMode.dark,
                  ),

                  // AMOLED
                  RadioListTile<AppThemeMode>(
                    title: Text(loc.themeAmoled),
                    secondary: const Icon(Icons.contrast),
                    value: AppThemeMode.amoled,
                  ),
                ],
              ),
            ),

            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentColorTile(BuildContext context, WidgetRef ref, settings) {
    final accentColor = settings.accentColor ?? AppTheme.defaultPrimaryColor;
    final isMonochrome = settings.monochromeAccent;

    String subtitleText;
    if (isMonochrome) {
      subtitleText = AppLocalizations.of(context)!.themeMonochrome;
    } else if (settings.accentColor == null) {
      subtitleText = AppLocalizations.of(context)!.accentDefault;
    } else {
      subtitleText = AppLocalizations.of(context)!.accentCustom;
    }

    // Visual representation of monochrome
    final colorPreview = isMonochrome
        ? Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.5, 0.5],
                transform: GradientRotation(3.14 / 4), // 45 degrees
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
          )
        : Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
          );

    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: Text(AppLocalizations.of(context)!.accentColor),
      subtitle: Text(subtitleText),
      trailing: colorPreview,
      onTap: () async {
        final result = await AccentColorPickerDialog.show(
          context,
          currentColor: settings.accentColor,
          isMonochrome: settings.monochromeAccent,
        );

        // Handle result
        final notifier = ref.read(settingsProvider.notifier);
        if (result is AccentColorCustom) {
          notifier.setAccentColor(result.color);
        } else if (result is AccentColorDefault) {
          notifier.setAccentColor(null); // Clear accent color
        } else if (result is AccentColorMonochrome) {
          notifier.setMonochromeAccent(true);
        }
        // If result is null (cancelled), do nothing!
      },
    );
  }

  // --- Support Settings ---

  Widget _buildDonationTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.coffee_outlined),
      title: Text(AppLocalizations.of(context)!.buyMeCoffee),
      subtitle: Text(AppLocalizations.of(context)!.supportDevelopment),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.parse(_kofiUrl);
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorLaunchUrl),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.errorLaunchUrl),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(
        AppLocalizations.of(context)!.about,
      ), // Ensure this key exists or fallback
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showAboutDialog(context),
    );
  }

  Widget _buildLicensesTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.policy_outlined),
      title: Text(AppLocalizations.of(context)!.licenses),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showLicensePage(
        context: context,
        applicationName: AppLocalizations.of(context)!.appTitle,
        applicationLegalese: '© 2025 Davide Falconi',
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    showAboutDialog(
      context: context,
      applicationName: packageInfo.appName,
      applicationVersion:
          'v${packageInfo.version} (${packageInfo.buildNumber})',
      applicationLegalese: '© 2025 Davide Falconi',
      children: [
        const Gap(16),
        Text(AppLocalizations.of(context)!.aboutDescription),
      ],
    );
  }

  String _themeModeLabel(BuildContext context, AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return AppLocalizations.of(context)!.themeSystem;
      case AppThemeMode.light:
        return AppLocalizations.of(context)!.themeLight;
      case AppThemeMode.dark:
        return AppLocalizations.of(context)!.themeDark;
      case AppThemeMode.amoled:
        return AppLocalizations.of(context)!.themeAmoled;
    }
  }
}
