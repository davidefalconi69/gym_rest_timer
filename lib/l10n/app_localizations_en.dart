// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gym Rest Timer';

  @override
  String get reset => 'Reset';

  @override
  String get actionPause => 'PAUSE';

  @override
  String get actionResume => 'RESUME';

  @override
  String get actionStart => 'START';

  @override
  String get statusDone => 'DONE!';

  @override
  String get statusPaused => 'PAUSED';

  @override
  String get statusRest => 'REST';

  @override
  String get statusReady => 'READY';

  @override
  String get statusResting => 'Resting...';

  @override
  String get settings => 'Settings';

  @override
  String get sectionTimer => 'Timer';

  @override
  String get defaultDuration => 'Default Duration';

  @override
  String get sectionNotification => 'Notification';

  @override
  String get settingSound => 'Sound';

  @override
  String get settingSoundDesc => 'Play sound when timer ends';

  @override
  String get settingVibration => 'Vibration';

  @override
  String get settingVibrationDesc => 'Vibrate when timer ends';

  @override
  String get settingVibrateSilent => 'Vibrate in Silent Mode';

  @override
  String get settingVibrateSilentDesc => 'Vibrate even when device is silenced';

  @override
  String get settingSoundType => 'Sound Type';

  @override
  String get selectSound => 'Select Sound';

  @override
  String get defaultBeep => 'Default Beep';

  @override
  String get defaultBeepDesc => 'Built-in notification sound';

  @override
  String get pickFromDevice => 'Pick from Device...';

  @override
  String get pickFromDeviceDesc => 'Select a custom audio file';

  @override
  String errorPickSound(String error) {
    return 'Failed to pick audio file: $error';
  }

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get accentDefault => 'Default (Teal)';

  @override
  String get accentCustom => 'Custom';

  @override
  String get themeAmoled => 'AMOLED Black';

  @override
  String get themeMonochrome => 'Monochrome';

  @override
  String get dialogTitleSelectColor => 'Select color';

  @override
  String get dialogSubheadingCustomColor => 'Custom color';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDone => 'Done';

  @override
  String get sectionSupport => 'Support';

  @override
  String get licenses => 'Licenses';

  @override
  String get buyMeCoffee => 'Buy me a coffee';

  @override
  String get supportDevelopment => 'Support development';

  @override
  String get sectionOther => 'Other';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'A simple, clean rest timer for your gym workouts.\nFocus on your sets, we handle the rest.';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get notificationTitle => 'Rest Timer';

  @override
  String notificationRest(String time) {
    return 'Rest: $time';
  }

  @override
  String get notificationPause => 'Pause';

  @override
  String get notificationResume => 'Resume';

  @override
  String get notificationStop => 'Stop';

  @override
  String get errorLaunchUrl => 'Could not open the link';

  @override
  String get notificationPermissionWarning =>
      'Notifications are disabled. Enable them to control the timer from any screen.';

  @override
  String get notificationEnableButton => 'Enable';

  @override
  String get setRestTime => 'Set Rest Time';
}
