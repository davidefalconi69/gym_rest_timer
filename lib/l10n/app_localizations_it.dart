// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Gym Rest Timer';

  @override
  String get reset => 'Resetta';

  @override
  String get actionPause => 'PAUSA';

  @override
  String get actionResume => 'RIPRENDI';

  @override
  String get actionStart => 'AVVIA';

  @override
  String get statusDone => 'FINITO!';

  @override
  String get statusPaused => 'IN PAUSA';

  @override
  String get statusRest => 'RIPOSO';

  @override
  String get statusReady => 'PRONTO';

  @override
  String get statusResting => 'In riposo...';

  @override
  String get settings => 'Impostazioni';

  @override
  String get sectionTimer => 'Timer';

  @override
  String get defaultDuration => 'Durata Predefinita';

  @override
  String get sectionNotification => 'Notifiche';

  @override
  String get settingSound => 'Suono';

  @override
  String get settingSoundDesc => 'Riproduci suono al termine';

  @override
  String get settingVibration => 'Vibrazione';

  @override
  String get settingVibrationDesc => 'Vibra al termine';

  @override
  String get settingVibrateSilent => 'Vibra in Silenzioso';

  @override
  String get settingVibrateSilentDesc =>
      'Vibra anche se il dispositivo è silenzioso';

  @override
  String get settingSoundType => 'Tipo di Suono';

  @override
  String get selectSound => 'Seleziona Suono';

  @override
  String get defaultBeep => 'Beep Predefinito';

  @override
  String get defaultBeepDesc => 'Suono di notifica integrato';

  @override
  String get pickFromDevice => 'Scegli dal Dispositivo...';

  @override
  String get pickFromDeviceDesc => 'Seleziona un file audio personalizzato';

  @override
  String errorPickSound(String error) {
    return 'Impossibile selezionare il file audio: $error';
  }

  @override
  String get sectionAppearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get accentColor => 'Colore Accento';

  @override
  String get accentDefault => 'Predefinito (Teal)';

  @override
  String get accentCustom => 'Personalizzato';

  @override
  String get themeAmoled => 'Nero AMOLED';

  @override
  String get themeMonochrome => 'Monocromatico';

  @override
  String get dialogTitleSelectColor => 'Seleziona colore';

  @override
  String get dialogSubheadingCustomColor => 'Colore personalizzato';

  @override
  String get actionCancel => 'Annulla';

  @override
  String get actionDone => 'Fatto';

  @override
  String get sectionSupport => 'Supporto';

  @override
  String get licenses => 'Licenze';

  @override
  String get buyMeCoffee => 'Offrimi un caffè';

  @override
  String get supportDevelopment => 'Supporta lo sviluppo';

  @override
  String get sectionOther => 'Altro';

  @override
  String get about => 'Informazioni';

  @override
  String get aboutDescription =>
      'Un timer semplice e pulito per i tuoi allenamenti.\nConcentrati sulle serie, al resto pensiamo noi.';

  @override
  String get language => 'Lingua';

  @override
  String get systemDefault => 'Default di Sistema';

  @override
  String get notificationTitle => 'Timer Riposo';

  @override
  String notificationRest(String time) {
    return 'Riposo: $time';
  }

  @override
  String get notificationPause => 'Pausa';

  @override
  String get notificationResume => 'Riprendi';

  @override
  String get notificationStop => 'Ferma';

  @override
  String get errorLaunchUrl => 'Impossibile aprire il link';

  @override
  String get notificationPermissionWarning =>
      'Le notifiche sono disattivate. Attivale per controllare il timer da qualsiasi schermata.';

  @override
  String get notificationEnableButton => 'Attiva';

  @override
  String get setRestTime => 'Imposta Tempo di Riposo';
}
