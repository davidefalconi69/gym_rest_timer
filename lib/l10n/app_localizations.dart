import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym Rest Timer'**
  String get appTitle;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get actionResume;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get actionStart;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'DONE!'**
  String get statusDone;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get statusPaused;

  /// No description provided for @statusRest.
  ///
  /// In en, this message translates to:
  /// **'REST'**
  String get statusRest;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get statusReady;

  /// No description provided for @statusResting.
  ///
  /// In en, this message translates to:
  /// **'Resting...'**
  String get statusResting;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sectionTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get sectionTimer;

  /// No description provided for @defaultDuration.
  ///
  /// In en, this message translates to:
  /// **'Default Duration'**
  String get defaultDuration;

  /// No description provided for @sectionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get sectionNotification;

  /// No description provided for @settingSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingSound;

  /// No description provided for @settingSoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Play sound when timer ends'**
  String get settingSoundDesc;

  /// No description provided for @settingVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingVibration;

  /// No description provided for @settingVibrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when timer ends'**
  String get settingVibrationDesc;

  /// No description provided for @settingVibrateSilent.
  ///
  /// In en, this message translates to:
  /// **'Vibrate in Silent Mode'**
  String get settingVibrateSilent;

  /// No description provided for @settingVibrateSilentDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate even when device is silenced'**
  String get settingVibrateSilentDesc;

  /// No description provided for @settingSoundType.
  ///
  /// In en, this message translates to:
  /// **'Sound Type'**
  String get settingSoundType;

  /// No description provided for @selectSound.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get selectSound;

  /// No description provided for @defaultBeep.
  ///
  /// In en, this message translates to:
  /// **'Default Beep'**
  String get defaultBeep;

  /// No description provided for @defaultBeepDesc.
  ///
  /// In en, this message translates to:
  /// **'Built-in notification sound'**
  String get defaultBeepDesc;

  /// No description provided for @pickFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Pick from Device...'**
  String get pickFromDevice;

  /// No description provided for @pickFromDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a custom audio file'**
  String get pickFromDeviceDesc;

  /// No description provided for @errorPickSound.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick audio file: {error}'**
  String errorPickSound(String error);

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (Teal)'**
  String get accentDefault;

  /// No description provided for @accentCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get accentCustom;

  /// No description provided for @themeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Black'**
  String get themeAmoled;

  /// No description provided for @themeMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get themeMonochrome;

  /// No description provided for @dialogTitleSelectColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get dialogTitleSelectColor;

  /// No description provided for @dialogSubheadingCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get dialogSubheadingCustomColor;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @buyMeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeCoffee;

  /// No description provided for @supportDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Support development'**
  String get supportDevelopment;

  /// No description provided for @sectionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sectionOther;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple, clean rest timer for your gym workouts.\nFocus on your sets, we handle the rest.'**
  String get aboutDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get notificationTitle;

  /// No description provided for @notificationRest.
  ///
  /// In en, this message translates to:
  /// **'Rest: {time}'**
  String notificationRest(String time);

  /// No description provided for @notificationPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get notificationPause;

  /// No description provided for @notificationResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get notificationResume;

  /// No description provided for @notificationStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get notificationStop;

  /// No description provided for @errorLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get errorLaunchUrl;

  /// No description provided for @notificationPermissionWarning.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Enable them to control the timer from any screen.'**
  String get notificationPermissionWarning;

  /// No description provided for @notificationEnableButton.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationEnableButton;

  /// No description provided for @setRestTime.
  ///
  /// In en, this message translates to:
  /// **'Set Rest Time'**
  String get setRestTime;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
