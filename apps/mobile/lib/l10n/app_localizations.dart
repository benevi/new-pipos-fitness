import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
    Locale('en'),
  ];

  /// Nombre de la app
  ///
  /// In es, this message translates to:
  /// **'Pipos Fitness'**
  String get appTitle;

  /// Texto accesible de la pantalla de arranque
  ///
  /// In es, this message translates to:
  /// **'Cargando tu sesión…'**
  String get splashLoading;

  /// No description provided for @navToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get navToday;

  /// No description provided for @navPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get navProgress;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @offlineBanner.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: mostrando datos guardados'**
  String get offlineBanner;

  /// Series registradas offline que aún no se han enviado
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 serie pendiente de sincronizar} other{{count} series pendientes de sincronizar}}'**
  String pendingSyncCount(int count);

  /// No description provided for @failedSyncCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 serie no se pudo enviar} other{{count} series no se pudieron enviar}}'**
  String failedSyncCount(int count);

  /// No description provided for @syncRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get syncRetry;

  /// No description provided for @syncStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de sincronizar'**
  String get syncStatusPending;

  /// No description provided for @syncStatusSynced.
  ///
  /// In es, this message translates to:
  /// **'Sincronizada'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar'**
  String get syncStatusFailed;

  /// No description provided for @setRejectedInvalid.
  ///
  /// In es, this message translates to:
  /// **'La API no la acepta: el ejercicio o los datos no valen para este hueco.'**
  String get setRejectedInvalid;

  /// No description provided for @setRejectedFinished.
  ///
  /// In es, this message translates to:
  /// **'La API no la acepta: el entrenamiento ya estaba terminado.'**
  String get setRejectedFinished;

  /// No description provided for @setRejectedNotStarted.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar: el entrenamiento no llegó a empezar en el servidor.'**
  String get setRejectedNotStarted;

  /// No description provided for @setRejectedOther.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar ({code}).'**
  String setRejectedOther(String code);

  /// No description provided for @setDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get setDiscard;

  /// No description provided for @setDiscardFor.
  ///
  /// In es, this message translates to:
  /// **'Descartar la serie {number}'**
  String setDiscardFor(int number);

  /// No description provided for @setDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar la serie {number}?'**
  String setDiscardTitle(int number);

  /// No description provided for @setDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Se quitará de este móvil y no contará en el entrenamiento. No se puede deshacer.'**
  String get setDiscardBody;

  /// No description provided for @cachedDataNotice.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Datos guardados el {date}.'**
  String cachedDataNotice(String date);

  /// No description provided for @fieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get fieldConfirmPassword;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In es, this message translates to:
  /// **'Introduce un correo válido'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos {min} caracteres'**
  String validationPasswordTooShort(int min);

  /// No description provided for @validationPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get validationPasswordsDontMatch;

  /// No description provided for @loginSubmit.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginSubmit;

  /// No description provided for @loginGoToRegister.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get loginGoToRegister;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerTitle;

  /// No description provided for @registerSubmit.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerSubmit;

  /// No description provided for @registerGoToLogin.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get registerGoToLogin;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailAlreadyRegistered.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo.'**
  String get authErrorEmailAlreadyRegistered;

  /// No description provided for @authErrorInvalidInput.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos introducidos.'**
  String get authErrorInvalidInput;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a iniciar sesión.'**
  String get authErrorSessionExpired;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión a internet.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La petición ha tardado demasiado. Inténtalo de nuevo.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In es, this message translates to:
  /// **'Error del servidor. Inténtalo más tarde.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a iniciar sesión.'**
  String get errorUnauthorized;

  /// No description provided for @errorBadRequest.
  ///
  /// In es, this message translates to:
  /// **'La solicitud no es válida.'**
  String get errorBadRequest;

  /// No description provided for @errorParse.
  ///
  /// In es, this message translates to:
  /// **'El servidor devolvió una respuesta inesperada.'**
  String get errorParse;

  /// No description provided for @errorUnknown.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error inesperado.'**
  String get errorUnknown;

  /// No description provided for @errorRateLimited.
  ///
  /// In es, this message translates to:
  /// **'Demasiadas peticiones. Espera un momento y vuelve a intentarlo.'**
  String get errorRateLimited;

  /// No description provided for @errorPlanGeneration.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar el plan con estos datos. Revisa el material o los días y vuelve a intentarlo.'**
  String get errorPlanGeneration;

  /// No description provided for @errorConsentRequired.
  ///
  /// In es, this message translates to:
  /// **'Para guardar limitaciones o datos corporales necesitamos tu consentimiento de salud.'**
  String get errorConsentRequired;

  /// No description provided for @errorOfflineAction.
  ///
  /// In es, this message translates to:
  /// **'Necesitas conexión para hacer esto.'**
  String get errorOfflineAction;

  /// No description provided for @actionRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get actionClose;

  /// No description provided for @actionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get actionBack;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionShowMore.
  ///
  /// In es, this message translates to:
  /// **'Por qué'**
  String get actionShowMore;

  /// No description provided for @actionShowLess.
  ///
  /// In es, this message translates to:
  /// **'Ocultar explicación'**
  String get actionShowLess;

  /// No description provided for @configErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración incompleta'**
  String get configErrorTitle;

  /// No description provided for @configErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Esta compilación no define la URL de la API. Vuelve a compilar con --dart-define=API_BASE_URL=https://…'**
  String get configErrorBody;

  /// No description provided for @medicalNotice.
  ///
  /// In es, this message translates to:
  /// **'Pipos Fitness no da consejo médico. Si tienes dolor, una lesión o una condición de salud, consulta a un profesional antes de entrenar.'**
  String get medicalNotice;

  /// No description provided for @screeningNotice.
  ///
  /// In es, this message translates to:
  /// **'Si tienes dolor al entrenar, una lesión reciente o alguna condición médica, consulta a un profesional sanitario antes de empezar. Esta app no diagnostica ni trata lesiones.'**
  String get screeningNotice;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu plan en 3 minutos'**
  String get onboardingTitle;

  /// No description provided for @onboardingStepOf.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quieres conseguir?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingLevelTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánta experiencia tienes con pesas?'**
  String get onboardingLevelTitle;

  /// No description provided for @onboardingScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto tiempo tienes?'**
  String get onboardingScheduleTitle;

  /// No description provided for @onboardingDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días por semana'**
  String get onboardingDaysLabel;

  /// No description provided for @onboardingDaysValue.
  ///
  /// In es, this message translates to:
  /// **'{days, plural, =1{1 día} other{{days} días}}'**
  String onboardingDaysValue(int days);

  /// No description provided for @onboardingMinutesLabel.
  ///
  /// In es, this message translates to:
  /// **'Minutos por sesión'**
  String get onboardingMinutesLabel;

  /// No description provided for @onboardingMinutesValue.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String onboardingMinutesValue(int minutes);

  /// No description provided for @onboardingEquipmentTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Con qué material cuentas?'**
  String get onboardingEquipmentTitle;

  /// No description provided for @onboardingEquipmentHint.
  ///
  /// In es, this message translates to:
  /// **'Marca todo lo que tengas a mano. El plan solo usará ejercicios que puedas hacer.'**
  String get onboardingEquipmentHint;

  /// No description provided for @onboardingEquipmentPresetGym.
  ///
  /// In es, this message translates to:
  /// **'Gimnasio completo'**
  String get onboardingEquipmentPresetGym;

  /// No description provided for @onboardingEquipmentPresetHome.
  ///
  /// In es, this message translates to:
  /// **'Casa con mancuernas'**
  String get onboardingEquipmentPresetHome;

  /// No description provided for @onboardingEquipmentPresetBodyweight.
  ///
  /// In es, this message translates to:
  /// **'Solo peso corporal'**
  String get onboardingEquipmentPresetBodyweight;

  /// No description provided for @onboardingConsentTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de salud (opcional)'**
  String get onboardingConsentTitle;

  /// No description provided for @onboardingConsentIntro.
  ///
  /// In es, this message translates to:
  /// **'Para evitar ejercicios que puedan agravar una molestia, y para calcular tus objetivos de nutrición, necesitamos tratar datos de salud. Es opcional y puedes retirarlo cuando quieras.'**
  String get onboardingConsentIntro;

  /// No description provided for @onboardingConsentVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión del texto: {version}'**
  String onboardingConsentVersion(String version);

  /// No description provided for @onboardingConsentAccept.
  ///
  /// In es, this message translates to:
  /// **'Acepto'**
  String get onboardingConsentAccept;

  /// No description provided for @onboardingConsentSkip.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin datos de salud'**
  String get onboardingConsentSkip;

  /// No description provided for @onboardingConsentSkippedNote.
  ///
  /// In es, this message translates to:
  /// **'Sin este consentimiento tu plan no tendrá en cuenta limitaciones ni datos corporales. Puedes darlo más tarde en Ajustes.'**
  String get onboardingConsentSkippedNote;

  /// No description provided for @healthConsentText.
  ///
  /// In es, this message translates to:
  /// **'Acepto que Pipos Fitness trate mis datos de salud (peso, altura, limitaciones o molestias por zona del cuerpo y medidas corporales: perímetros de cintura, cuello, cadera, pecho, brazo y muslo) con el fin de adaptar mi plan de entrenamiento y mis objetivos nutricionales, y de mostrarme su evolución y estimaciones derivadas (índice de masa corporal y porcentaje de grasa estimado). Puedo retirar este consentimiento en cualquier momento desde Ajustes; al hacerlo se borran esos datos, incluido el registro de medidas, y el plan se regenera sin ellos. Las estimaciones no son un diagnóstico y Pipos Fitness no da consejo médico.'**
  String get healthConsentText;

  /// No description provided for @onboardingLimitationsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Alguna zona con molestias?'**
  String get onboardingLimitationsTitle;

  /// No description provided for @onboardingLimitationsHint.
  ///
  /// In es, this message translates to:
  /// **'El plan evitará los movimientos de riesgo para esas zonas y te propondrá variantes.'**
  String get onboardingLimitationsHint;

  /// No description provided for @onboardingNoLimitations.
  ///
  /// In es, this message translates to:
  /// **'Ninguna'**
  String get onboardingNoLimitations;

  /// No description provided for @onboardingPreferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Preferencias (opcional)'**
  String get onboardingPreferencesTitle;

  /// No description provided for @onboardingPriorityLabel.
  ///
  /// In es, this message translates to:
  /// **'Músculos prioritarios (hasta {max})'**
  String onboardingPriorityLabel(int max);

  /// No description provided for @onboardingFavouritesLabel.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios favoritos'**
  String get onboardingFavouritesLabel;

  /// No description provided for @onboardingBannedLabel.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios que no quieres hacer'**
  String get onboardingBannedLabel;

  /// No description provided for @onboardingAddExercise.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicio'**
  String get onboardingAddExercise;

  /// No description provided for @onboardingRemoveExercise.
  ///
  /// In es, this message translates to:
  /// **'Quitar {name}'**
  String onboardingRemoveExercise(String name);

  /// No description provided for @exercisePickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar ejercicio'**
  String get exercisePickerTitle;

  /// No description provided for @exercisePickerHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del ejercicio'**
  String get exercisePickerHint;

  /// No description provided for @exercisePickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay ejercicios con ese nombre.'**
  String get exercisePickerEmpty;

  /// No description provided for @onboardingBodyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sobre ti (opcional)'**
  String get onboardingBodyTitle;

  /// No description provided for @onboardingBodyHint.
  ///
  /// In es, this message translates to:
  /// **'Solo se usan para calcular tus objetivos de nutrición. Puedes dejarlos en blanco.'**
  String get onboardingBodyHint;

  /// No description provided for @onboardingBodyNeedsConsent.
  ///
  /// In es, this message translates to:
  /// **'El peso y la altura son datos de salud: solo se guardan si das tu consentimiento.'**
  String get onboardingBodyNeedsConsent;

  /// No description provided for @fieldBirthYear.
  ///
  /// In es, this message translates to:
  /// **'Año de nacimiento'**
  String get fieldBirthYear;

  /// No description provided for @fieldSex.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get fieldSex;

  /// No description provided for @fieldWeightKg.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get fieldWeightKg;

  /// No description provided for @fieldHeightCm.
  ///
  /// In es, this message translates to:
  /// **'Altura (cm)'**
  String get fieldHeightCm;

  /// No description provided for @fieldActivityLevel.
  ///
  /// In es, this message translates to:
  /// **'Actividad diaria fuera del gimnasio'**
  String get fieldActivityLevel;

  /// No description provided for @fieldTimezone.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get fieldTimezone;

  /// No description provided for @fieldNotSpecified.
  ///
  /// In es, this message translates to:
  /// **'Prefiero no decirlo'**
  String get fieldNotSpecified;

  /// No description provided for @onboardingTimezoneAuto.
  ///
  /// In es, this message translates to:
  /// **'Detectada en tu dispositivo: {timezone}'**
  String onboardingTimezoneAuto(String timezone);

  /// No description provided for @onboardingReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa y genera tu plan'**
  String get onboardingReviewTitle;

  /// No description provided for @onboardingGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar mi plan'**
  String get onboardingGenerate;

  /// No description provided for @onboardingGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando tu plan…'**
  String get onboardingGenerating;

  /// No description provided for @onboardingSaveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get onboardingSaveChanges;

  /// No description provided for @onboardingNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get onboardingNext;

  /// No description provided for @onboardingResultTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu plan está listo'**
  String get onboardingResultTitle;

  /// No description provided for @onboardingResultStart.
  ///
  /// In es, this message translates to:
  /// **'Ver la sesión de hoy'**
  String get onboardingResultStart;

  /// No description provided for @validationRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige una opción'**
  String get validationRequired;

  /// No description provided for @validationEquipmentRequired.
  ///
  /// In es, this message translates to:
  /// **'Elige al menos un material (o «Peso corporal»)'**
  String get validationEquipmentRequired;

  /// No description provided for @validationRange.
  ///
  /// In es, this message translates to:
  /// **'Debe estar entre {min} y {max}'**
  String validationRange(String min, String max);

  /// No description provided for @validationNumber.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número'**
  String get validationNumber;

  /// No description provided for @validationAdult.
  ///
  /// In es, this message translates to:
  /// **'La app es solo para mayores de {age} años'**
  String validationAdult(int age);

  /// No description provided for @validationPriorityMax.
  ///
  /// In es, this message translates to:
  /// **'Elige como máximo {max}'**
  String validationPriorityMax(int max);

  /// No description provided for @validationBannedFavourite.
  ///
  /// In es, this message translates to:
  /// **'Un ejercicio no puede ser favorito y vetado a la vez'**
  String get validationBannedFavourite;

  /// No description provided for @validationServerField.
  ///
  /// In es, this message translates to:
  /// **'Revisa este campo'**
  String get validationServerField;

  /// No description provided for @validationFixErrors.
  ///
  /// In es, this message translates to:
  /// **'Revisa los campos marcados.'**
  String get validationFixErrors;

  /// No description provided for @todayTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get todayTitle;

  /// No description provided for @todayEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes plan'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Completa el cuestionario para recibir tu plan y tu sesión de hoy.'**
  String get todayEmptyBody;

  /// No description provided for @todayEmptyAction.
  ///
  /// In es, this message translates to:
  /// **'Empezar el cuestionario'**
  String get todayEmptyAction;

  /// No description provided for @todayOfflineNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión y sin datos guardados. Conéctate una vez para descargar tu sesión.'**
  String get todayOfflineNoData;

  /// No description provided for @todaySessionMeta.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min estimados · {count, plural, =1{1 ejercicio} other{{count} ejercicios}}'**
  String todaySessionMeta(int minutes, int count);

  /// No description provided for @todayGeneralWarmup.
  ///
  /// In es, this message translates to:
  /// **'Calentamiento general: {minutes} min de movilidad o cardio suave'**
  String todayGeneralWarmup(int minutes);

  /// No description provided for @todayWarmupSets.
  ///
  /// In es, this message translates to:
  /// **'Series de aproximación'**
  String get todayWarmupSets;

  /// No description provided for @todayWarmupSet.
  ///
  /// In es, this message translates to:
  /// **'{reps} reps · {load}'**
  String todayWarmupSet(int reps, String load);

  /// No description provided for @todayTarget.
  ///
  /// In es, this message translates to:
  /// **'{sets} × {repMin}–{repMax} reps · RIR {rir}'**
  String todayTarget(int sets, int repMin, int repMax, int rir);

  /// No description provided for @todaySuggestedLoad.
  ///
  /// In es, this message translates to:
  /// **'Carga sugerida: {load}'**
  String todaySuggestedLoad(String load);

  /// No description provided for @todayInitialEstimate.
  ///
  /// In es, this message translates to:
  /// **'Estimación inicial'**
  String get todayInitialEstimate;

  /// No description provided for @todayInitialEstimateHelp.
  ///
  /// In es, this message translates to:
  /// **'Aún no conocemos tu carga: elige un peso con el que te queden unas {rir} repeticiones en reserva.'**
  String todayInitialEstimateHelp(int rir);

  /// No description provided for @todayDeload.
  ///
  /// In es, this message translates to:
  /// **'Descarga'**
  String get todayDeload;

  /// No description provided for @todaySubstitutedFrom.
  ///
  /// In es, this message translates to:
  /// **'Sustituye a {name}'**
  String todaySubstitutedFrom(String name);

  /// No description provided for @todayRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso {seconds} s'**
  String todayRest(int seconds);

  /// No description provided for @todayCues.
  ///
  /// In es, this message translates to:
  /// **'Claves técnicas'**
  String get todayCues;

  /// No description provided for @todaySetLabel.
  ///
  /// In es, this message translates to:
  /// **'Serie {index}'**
  String todaySetLabel(int index);

  /// No description provided for @todaySetDone.
  ///
  /// In es, this message translates to:
  /// **'{reps} × {load} · RIR {rir}'**
  String todaySetDone(int reps, String load, String rir);

  /// No description provided for @fieldReps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get fieldReps;

  /// No description provided for @fieldLoad.
  ///
  /// In es, this message translates to:
  /// **'Kg'**
  String get fieldLoad;

  /// No description provided for @fieldRir.
  ///
  /// In es, this message translates to:
  /// **'RIR'**
  String get fieldRir;

  /// No description provided for @rirPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones en reserva (RIR)'**
  String get rirPickerTitle;

  /// No description provided for @rirPickerHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas repeticiones más podrías haber hecho con buena técnica?'**
  String get rirPickerHelp;

  /// No description provided for @rirValue.
  ///
  /// In es, this message translates to:
  /// **'RIR {rir}'**
  String rirValue(int rir);

  /// No description provided for @todayConfirmSet.
  ///
  /// In es, this message translates to:
  /// **'Confirmar serie {index}'**
  String todayConfirmSet(int index);

  /// No description provided for @todayExerciseDone.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio completado'**
  String get todayExerciseDone;

  /// No description provided for @todaySwap.
  ///
  /// In es, this message translates to:
  /// **'Cambiar ejercicio'**
  String get todaySwap;

  /// No description provided for @todayFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar entrenamiento'**
  String get todayFinish;

  /// No description provided for @todayFinishConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Terminar el entrenamiento?'**
  String get todayFinishConfirmTitle;

  /// No description provided for @todayFinishConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Has completado todas las series.} =1{Te queda 1 serie sin registrar.} other{Te quedan {count} series sin registrar.}} Lo registrado se guarda igualmente.'**
  String todayFinishConfirmBody(int count);

  /// No description provided for @todayFinishConfirm.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get todayFinishConfirm;

  /// No description provided for @todayFinishUnsynced.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay 1 serie sin enviar.} other{Hay {count} series sin enviar.}} Se reintentará antes de cerrar el entrenamiento; mientras no se envíe, el cierre queda en espera.'**
  String todayFinishUnsynced(int count);

  /// No description provided for @todayFinishRetryNow.
  ///
  /// In es, this message translates to:
  /// **'Reintentar envío'**
  String get todayFinishRetryNow;

  /// No description provided for @todayStaleSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión guardada del {date}. Sin conexión no podemos saber qué sesión toca hoy; puedes registrarla igualmente y se sincronizará al volver la red.'**
  String todayStaleSession(String date);

  /// No description provided for @todayNoUserOffline.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar la serie: conéctate a internet una vez para verificar tu sesión.'**
  String get todayNoUserOffline;

  /// No description provided for @todayConflictBody.
  ///
  /// In es, this message translates to:
  /// **'Un entrenamiento guardado en este móvil ({count, plural, =1{1 serie} other{{count} series}}) no se pudo empezar en el servidor: ya hay otro en curso en tu cuenta. Termina ese entrenamiento y pulsa «Reintentar», o descarta el de este móvil.'**
  String todayConflictBody(int count);

  /// No description provided for @todayConflictDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get todayConflictDiscard;

  /// No description provided for @todayConflictDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar el entrenamiento de este móvil?'**
  String get todayConflictDiscardTitle;

  /// No description provided for @todayConflictDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se borrará 1 serie que no llegó al servidor.} other{Se borrarán {count} series que no llegaron al servidor.}} No se puede deshacer.'**
  String todayConflictDiscardBody(int count);

  /// No description provided for @todayStartHint.
  ///
  /// In es, this message translates to:
  /// **'El entrenamiento empieza al confirmar la primera serie.'**
  String get todayStartHint;

  /// No description provided for @restTimerLabel.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get restTimerLabel;

  /// No description provided for @restTimerRemaining.
  ///
  /// In es, this message translates to:
  /// **'Descanso: quedan {time}'**
  String restTimerRemaining(String time);

  /// No description provided for @restTimerSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar descanso'**
  String get restTimerSkip;

  /// No description provided for @restTimerAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir 15 segundos'**
  String get restTimerAdd;

  /// No description provided for @restTimerDone.
  ///
  /// In es, this message translates to:
  /// **'Descanso terminado'**
  String get restTimerDone;

  /// No description provided for @swapTitle.
  ///
  /// In es, this message translates to:
  /// **'Alternativas a {name}'**
  String swapTitle(String name);

  /// No description provided for @swapHint.
  ///
  /// In es, this message translates to:
  /// **'Ordenadas por parecido: mismo patrón, músculos y tu material.'**
  String get swapHint;

  /// No description provided for @swapEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay alternativas compatibles con tu material y tus limitaciones.'**
  String get swapEmpty;

  /// No description provided for @swapChoose.
  ///
  /// In es, this message translates to:
  /// **'Usar {name}'**
  String swapChoose(String name);

  /// No description provided for @swapDone.
  ///
  /// In es, this message translates to:
  /// **'Ejercicio cambiado por {name}'**
  String swapDone(String name);

  /// No description provided for @completeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Entrenamiento completado!'**
  String get completeTitle;

  /// No description provided for @completeSummary.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 serie registrada} other{{count} series registradas}} · {volume} kg movidos'**
  String completeSummary(int count, String volume);

  /// No description provided for @completeSynced.
  ///
  /// In es, this message translates to:
  /// **'Todo sincronizado.'**
  String get completeSynced;

  /// No description provided for @completePending.
  ///
  /// In es, this message translates to:
  /// **'Se sincronizará cuando haya conexión. No se perderá nada.'**
  String get completePending;

  /// No description provided for @completeBack.
  ///
  /// In es, this message translates to:
  /// **'Volver a Hoy'**
  String get completeBack;

  /// No description provided for @planTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu plan'**
  String get planTitle;

  /// No description provided for @planVersionLabel.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String planVersionLabel(int version);

  /// No description provided for @planWhySplit.
  ///
  /// In es, this message translates to:
  /// **'Por qué este reparto'**
  String get planWhySplit;

  /// No description provided for @planWarnings.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get planWarnings;

  /// No description provided for @planSessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get planSessions;

  /// No description provided for @planSessionMeta.
  ///
  /// In es, this message translates to:
  /// **'{day} · {minutes} min'**
  String planSessionMeta(String day, int minutes);

  /// No description provided for @planExerciseLine.
  ///
  /// In es, this message translates to:
  /// **'{sets} × {repMin}–{repMax} · RIR {rir} · {rest} s descanso'**
  String planExerciseLine(int sets, int repMin, int repMax, int rir, int rest);

  /// No description provided for @planHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de versiones'**
  String get planHistory;

  /// No description provided for @planHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Solo tienes una versión del plan.'**
  String get planHistoryEmpty;

  /// No description provided for @planHistoryItem.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} · {date}'**
  String planHistoryItem(int version, String date);

  /// No description provided for @planCurrentBadge.
  ///
  /// In es, this message translates to:
  /// **'Actual'**
  String get planCurrentBadge;

  /// No description provided for @planWeeklyVolume.
  ///
  /// In es, this message translates to:
  /// **'Series semanales por grupo'**
  String get planWeeklyVolume;

  /// No description provided for @planVolumeRange.
  ///
  /// In es, this message translates to:
  /// **'{sets} series (objetivo {min}–{max})'**
  String planVolumeRange(String sets, String min, String max);

  /// No description provided for @progressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get progressTitle;

  /// No description provided for @progressE1rmTitle.
  ///
  /// In es, this message translates to:
  /// **'Fuerza estimada (e1RM)'**
  String get progressE1rmTitle;

  /// No description provided for @progressE1rmEmpty.
  ///
  /// In es, this message translates to:
  /// **'Registra tus primeras series con carga para ver tu e1RM.'**
  String get progressE1rmEmpty;

  /// No description provided for @progressE1rmValue.
  ///
  /// In es, this message translates to:
  /// **'{kg} kg'**
  String progressE1rmValue(String kg);

  /// No description provided for @progressE1rmTrend.
  ///
  /// In es, this message translates to:
  /// **'{name}: de {first} a {last} kg entre el {since} y el {until} ({count} sesiones)'**
  String progressE1rmTrend(
    String name,
    String first,
    String last,
    String since,
    String until,
    int count,
  );

  /// No description provided for @progressVolumeTitle.
  ///
  /// In es, this message translates to:
  /// **'Series esta semana por grupo'**
  String get progressVolumeTitle;

  /// No description provided for @progressVolumeEmpty.
  ///
  /// In es, this message translates to:
  /// **'Cuando entrenes esta semana verás aquí tus series frente al rango objetivo.'**
  String get progressVolumeEmpty;

  /// No description provided for @progressVolumeBar.
  ///
  /// In es, this message translates to:
  /// **'{group}: {sets} series, objetivo {min} a {max}, {status}'**
  String progressVolumeBar(
    String group,
    String sets,
    String min,
    String max,
    String status,
  );

  /// No description provided for @progressAdherenceTitle.
  ///
  /// In es, this message translates to:
  /// **'Adherencia'**
  String get progressAdherenceTitle;

  /// No description provided for @progressAdherenceEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay semanas planificadas.'**
  String get progressAdherenceEmpty;

  /// No description provided for @progressAdherenceValue.
  ///
  /// In es, this message translates to:
  /// **'{done} de {planned} sesiones ({percent} %)'**
  String progressAdherenceValue(int done, int planned, int percent);

  /// No description provided for @progressEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso aparecerá aquí'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primera sesión para empezar a ver fuerza, volumen y adherencia.'**
  String get progressEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de entrenamiento'**
  String get settingsProfile;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivo, días, minutos, material y preferencias'**
  String get settingsProfileSubtitle;

  /// No description provided for @settingsHealth.
  ///
  /// In es, this message translates to:
  /// **'Datos de salud y limitaciones'**
  String get settingsHealth;

  /// No description provided for @settingsHealthGranted.
  ///
  /// In es, this message translates to:
  /// **'Consentimiento de salud dado el {date}'**
  String settingsHealthGranted(String date);

  /// No description provided for @settingsHealthNotGranted.
  ///
  /// In es, this message translates to:
  /// **'Sin consentimiento: el plan no usa limitaciones ni datos corporales'**
  String get settingsHealthNotGranted;

  /// No description provided for @settingsHealthGrant.
  ///
  /// In es, this message translates to:
  /// **'Dar consentimiento'**
  String get settingsHealthGrant;

  /// No description provided for @settingsHealthWithdraw.
  ///
  /// In es, this message translates to:
  /// **'Retirar consentimiento'**
  String get settingsHealthWithdraw;

  /// No description provided for @settingsHealthWithdrawTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Retirar el consentimiento?'**
  String get settingsHealthWithdrawTitle;

  /// No description provided for @settingsHealthWithdrawBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán tus limitaciones, peso y altura, y se generará una nueva versión del plan sin ellos.'**
  String get settingsHealthWithdrawBody;

  /// No description provided for @settingsHealthWithdrawn.
  ///
  /// In es, this message translates to:
  /// **'Consentimiento retirado. Tus datos de salud se han borrado.'**
  String get settingsHealthWithdrawn;

  /// No description provided for @settingsNutrition.
  ///
  /// In es, this message translates to:
  /// **'Objetivos de nutrición'**
  String get settingsNutrition;

  /// No description provided for @settingsNutritionKcal.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal al día'**
  String settingsNutritionKcal(String kcal);

  /// No description provided for @settingsNutritionMacros.
  ///
  /// In es, this message translates to:
  /// **'Proteína {protein} g · Grasa {fat} g · Hidratos {carbs} g'**
  String settingsNutritionMacros(String protein, String fat, String carbs);

  /// No description provided for @settingsNutritionIncomplete.
  ///
  /// In es, this message translates to:
  /// **'Completa estos datos para calcularlos:'**
  String get settingsNutritionIncomplete;

  /// No description provided for @settingsNutritionComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar mis datos'**
  String get settingsNutritionComplete;

  /// No description provided for @settingsExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar mis datos'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Descarga un JSON con todo lo que guardamos sobre ti'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsExportDone.
  ///
  /// In es, this message translates to:
  /// **'Exportación lista'**
  String get settingsExportDone;

  /// No description provided for @settingsDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar cuenta'**
  String get settingsDelete;

  /// No description provided for @settingsDeleteSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elimina tu cuenta y todos tus datos para siempre'**
  String get settingsDeleteSubtitle;

  /// No description provided for @settingsDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar tu cuenta?'**
  String get settingsDeleteTitle;

  /// No description provided for @settingsDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán para siempre tu perfil, tus planes, tus entrenamientos y tus datos de salud. No se puede deshacer. Escribe tu contraseña para confirmarlo.'**
  String get settingsDeleteBody;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Borrar mi cuenta'**
  String get settingsDeleteConfirm;

  /// No description provided for @settingsDeleteWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no es correcta.'**
  String get settingsDeleteWrongPassword;

  /// No description provided for @settingsLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán de este móvil tu plan y tus sesiones guardadas. Tus datos siguen en tu cuenta.'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @settingsLogoutUnsent.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay 1 serie sin enviar al servidor.} other{Hay {count} series sin enviar al servidor.}} Si cierras sesión ahora se perderán. Conéctate a internet para enviarlas antes.'**
  String settingsLogoutUnsent(int count);

  /// No description provided for @settingsLegal.
  ///
  /// In es, this message translates to:
  /// **'Aviso legal y médico'**
  String get settingsLegal;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In es, this message translates to:
  /// **'Perfil guardado.'**
  String get settingsProfileSaved;

  /// No description provided for @settingsNewPlanTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva versión del plan'**
  String get settingsNewPlanTitle;

  /// No description provided for @settingsNewPlanBody.
  ///
  /// In es, this message translates to:
  /// **'Tus cambios afectan al plan, así que hemos creado la versión {version}. Tu historial y tu progreso se conservan, y la versión anterior sigue en el historial.'**
  String settingsNewPlanBody(int version);

  /// No description provided for @settingsNewPlanAction.
  ///
  /// In es, this message translates to:
  /// **'Ver el plan'**
  String get settingsNewPlanAction;

  /// No description provided for @fieldNames.
  ///
  /// In es, this message translates to:
  /// **'{field, select, goal{Objetivo} level{Nivel} daysPerWeek{Días por semana} minutesPerSession{Minutos por sesión} equipment{Material} priorityMuscles{Músculos prioritarios} timezone{Zona horaria} activityLevel{Actividad diaria} birthYear{Año de nacimiento} sex{Sexo} bannedExerciseSlugs{Ejercicios vetados} favouriteExerciseSlugs{Ejercicios favoritos} limitations{Limitaciones} weightKg{Peso} heightCm{Altura} other{{field}}}'**
  String fieldNames(String field);

  /// No description provided for @goalLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, strength{Ganar fuerza} hypertrophy{Ganar músculo} general_health{Salud general} fat_loss{Perder grasa} muscular_endurance{Resistencia muscular} other{{value}}}'**
  String goalLabel(String value);

  /// No description provided for @levelLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, beginner{Principiante (menos de 1 año)} intermediate{Intermedio (1–3 años)} advanced{Avanzado (más de 3 años)} other{{value}}}'**
  String levelLabel(String value);

  /// No description provided for @equipmentLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, bodyweight{Peso corporal} barbell{Barra olímpica} ez_bar{Barra Z} trap_bar{Barra hexagonal} dumbbell{Mancuernas} kettlebell{Kettlebell} weight_plate{Discos} bench{Banco} squat_rack{Rack de sentadilla} cable{Poleas} machine{Máquinas} smith_machine{Multipower} pull_up_bar{Barra de dominadas} dip_station{Paralelas} gymnastic_rings{Anillas} suspension_trainer{TRX} resistance_band{Bandas elásticas} medicine_ball{Balón medicinal} plyo_box{Cajón} other{{value}}}'**
  String equipmentLabel(String value);

  /// No description provided for @zoneLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, shoulder{Hombro} elbow{Codo} wrist{Muñeca} lumbar{Zona lumbar} hip{Cadera} knee{Rodilla} ankle{Tobillo} other{{value}}}'**
  String zoneLabel(String value);

  /// No description provided for @muscleLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, chest{Pecho} front_delts{Deltoides anterior} side_delts{Deltoides lateral} rear_delts{Deltoides posterior} lats{Dorsales} upper_back{Espalda alta} traps{Trapecio} biceps{Bíceps} triceps{Tríceps} forearms{Antebrazos} abs{Abdominales} obliques{Oblicuos} lower_back{Lumbares} glutes{Glúteos} quads{Cuádriceps} hamstrings{Isquiotibiales} adductors{Aductores} abductors{Abductores} calves{Gemelos} other{{value}}}'**
  String muscleLabel(String value);

  /// No description provided for @groupLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, chest{Pecho} back{Espalda} shoulders{Hombros} biceps{Bíceps} triceps{Tríceps} quads{Cuádriceps} hamstrings{Isquiotibiales} glutes{Glúteos} calves{Gemelos} core{Core} other{{value}}}'**
  String groupLabel(String value);

  /// No description provided for @sexLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, male{Hombre} female{Mujer} other{Otro}}'**
  String sexLabel(String value);

  /// No description provided for @activityLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, sedentary_light{Sedentaria o ligera} active{Activa (de pie, caminas a diario)} vigorous{Muy activa (trabajo físico)} other{{value}}}'**
  String activityLabel(String value);

  /// No description provided for @splitLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, full_body{Cuerpo completo} upper_lower{Torso / pierna} hybrid_ul_ppl{Torso-pierna + empuje-tirón-pierna} push_pull_legs{Empuje / tirón / pierna} other{{value}}}'**
  String splitLabel(String value);

  /// No description provided for @sessionKindLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, full_body{Cuerpo completo} upper{Torso} lower{Pierna} push{Empuje} pull{Tirón} legs{Pierna} other{{value}}}'**
  String sessionKindLabel(String value);

  /// No description provided for @progressionLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, start{Primera sesión} increase_load{Sube la carga} increase_reps{Sube repeticiones} hold{Mantén} decrease_load{Baja la carga} deload{Semana de descarga} return_after_break{Vuelta tras una pausa} progress_variant{Pasa a una variante más difícil} other{{value}}}'**
  String progressionLabel(String value);

  /// No description provided for @volumeStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, below{por debajo} within{dentro del rango} above{por encima} other{sin objetivo}}'**
  String volumeStatusLabel(String value);

  /// No description provided for @nutritionGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'{value, select, fat_loss{Pérdida de grasa} maintenance{Mantenimiento} muscle_gain{Ganancia muscular} other{{value}}}'**
  String nutritionGoalLabel(String value);

  /// No description provided for @weekdayLabel.
  ///
  /// In es, this message translates to:
  /// **'{day, select, 0{Lunes} 1{Martes} 2{Miércoles} 3{Jueves} 4{Viernes} 5{Sábado} 6{Domingo} other{{day}}}'**
  String weekdayLabel(String day);

  /// No description provided for @loadKgValue.
  ///
  /// In es, this message translates to:
  /// **'{kg} kg'**
  String loadKgValue(String kg);

  /// No description provided for @loadBodyweight.
  ///
  /// In es, this message translates to:
  /// **'Peso corporal'**
  String get loadBodyweight;

  /// No description provided for @loadPctValue.
  ///
  /// In es, this message translates to:
  /// **'{pct} % de la carga'**
  String loadPctValue(String pct);

  /// No description provided for @settingsHealthUpdateBody.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva del texto que añade las medidas corporales (perímetros) y las estimaciones de IMC y % de grasa. Tu consentimiento actual sigue cubriendo peso, altura y limitaciones.'**
  String get settingsHealthUpdateBody;

  /// No description provided for @settingsHealthUpdate.
  ///
  /// In es, this message translates to:
  /// **'Leer y aceptar la versión nueva'**
  String get settingsHealthUpdate;

  /// Notas o medidas guardadas sin conexión que aún no se han enviado
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio pendiente de sincronizar} other{{count} cambios pendientes de sincronizar}}'**
  String pendingChangesCount(int count);

  /// No description provided for @failedChangesCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 cambio no se pudo enviar} other{{count} cambios no se pudieron enviar}}'**
  String failedChangesCount(int count);

  /// No description provided for @loadImplementLabel.
  ///
  /// In es, this message translates to:
  /// **'{implement, select, barbell{Barra} trap_bar{Barra hexagonal} ez_bar{Barra EZ} smith_machine{Multipower} dumbbell{Mancuernas} kettlebell{Kettlebell} machine{Máquina} cable{Polea} weight_plate{Disco} other{{implement}}}'**
  String loadImplementLabel(String implement);

  /// Material y paso real de carga del ejercicio
  ///
  /// In es, this message translates to:
  /// **'{implement} · de {step} en {step}'**
  String todayLoadStep(String implement, String step);

  /// No description provided for @platesButton.
  ///
  /// In es, this message translates to:
  /// **'Discos'**
  String get platesButton;

  /// No description provided for @platesButtonFor.
  ///
  /// In es, this message translates to:
  /// **'Ver discos para {kg}'**
  String platesButtonFor(String kg);

  /// No description provided for @platesTitle.
  ///
  /// In es, this message translates to:
  /// **'Discos para {kg}'**
  String platesTitle(String kg);

  /// No description provided for @platesBar.
  ///
  /// In es, this message translates to:
  /// **'Barra: {kg}'**
  String platesBar(String kg);

  /// No description provided for @platesPerSide.
  ///
  /// In es, this message translates to:
  /// **'Por lado: {plates}'**
  String platesPerSide(String plates);

  /// No description provided for @platesOnlyBar.
  ///
  /// In es, this message translates to:
  /// **'Solo la barra, sin discos.'**
  String get platesOnlyBar;

  /// No description provided for @platesRemainder.
  ///
  /// In es, this message translates to:
  /// **'Faltan {kg} que no se pueden formar con discos estándar: usa el peso más cercano.'**
  String platesRemainder(String kg);

  /// No description provided for @platesBelowBar.
  ///
  /// In es, this message translates to:
  /// **'La carga es menor que la barra vacía ({kg}).'**
  String platesBelowBar(String kg);

  /// No description provided for @platesHelp.
  ///
  /// In es, this message translates to:
  /// **'Discos estándar de 25 a 1,25 kg. Pon los mismos a cada lado.'**
  String get platesHelp;

  /// No description provided for @loadDecrease.
  ///
  /// In es, this message translates to:
  /// **'Bajar {step}'**
  String loadDecrease(String step);

  /// No description provided for @loadIncrease.
  ///
  /// In es, this message translates to:
  /// **'Subir {step}'**
  String loadIncrease(String step);

  /// No description provided for @noteLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu nota'**
  String get noteLabel;

  /// No description provided for @noteAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir nota'**
  String get noteAdd;

  /// No description provided for @noteEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar nota'**
  String get noteEdit;

  /// No description provided for @noteSheetTitle.
  ///
  /// In es, this message translates to:
  /// **'Nota para {exercise}'**
  String noteSheetTitle(String exercise);

  /// No description provided for @noteHint.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de máquina, agarre, altura del asiento… La verás cada vez que toque este ejercicio.'**
  String get noteHint;

  /// No description provided for @noteFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get noteFieldLabel;

  /// No description provided for @notePrivacy.
  ///
  /// In es, this message translates to:
  /// **'Solo la ves tú. Si tienes una molestia, mejor consulta a un profesional que apuntarla aquí.'**
  String get notePrivacy;

  /// No description provided for @noteSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar nota'**
  String get noteSave;

  /// No description provided for @noteDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar nota'**
  String get noteDelete;

  /// No description provided for @noteEmptyError.
  ///
  /// In es, this message translates to:
  /// **'Escribe la nota o bórrala.'**
  String get noteEmptyError;

  /// No description provided for @noteSaved.
  ///
  /// In es, this message translates to:
  /// **'Nota guardada.'**
  String get noteSaved;

  /// No description provided for @noteDeleted.
  ///
  /// In es, this message translates to:
  /// **'Nota borrada.'**
  String get noteDeleted;

  /// No description provided for @swapPinLabel.
  ///
  /// In es, this message translates to:
  /// **'Usar siempre este cambio'**
  String get swapPinLabel;

  /// No description provided for @swapPinHelp.
  ///
  /// In es, this message translates to:
  /// **'Se aplica a todas las sesiones de este plan con este ejercicio y se mantiene en las versiones nuevas mientras siga siendo válido.'**
  String get swapPinHelp;

  /// No description provided for @swapPinnedDone.
  ///
  /// In es, this message translates to:
  /// **'A partir de ahora harás {name} en este plan'**
  String swapPinnedDone(String name);

  /// No description provided for @pinnedBadge.
  ///
  /// In es, this message translates to:
  /// **'Cambio fijado'**
  String get pinnedBadge;

  /// No description provided for @pinnedInsteadOf.
  ///
  /// In es, this message translates to:
  /// **'Cambio fijado: en lugar de {name}'**
  String pinnedInsteadOf(String name);

  /// No description provided for @unpinAction.
  ///
  /// In es, this message translates to:
  /// **'Volver a {name}'**
  String unpinAction(String name);

  /// No description provided for @unpinDone.
  ///
  /// In es, this message translates to:
  /// **'Has vuelto a {name}'**
  String unpinDone(String name);

  /// No description provided for @pinDroppedTitle.
  ///
  /// In es, this message translates to:
  /// **'Un cambio fijado ya no se puede aplicar.'**
  String get pinDroppedTitle;

  /// No description provided for @adjustOpen.
  ///
  /// In es, this message translates to:
  /// **'¿Poco tiempo hoy?'**
  String get adjustOpen;

  /// No description provided for @adjustTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustar la sesión de hoy'**
  String get adjustTitle;

  /// No description provided for @adjustIntro.
  ///
  /// In es, this message translates to:
  /// **'Elige el tiempo que tienes o una versión más ligera. Solo cambia hoy: tu plan sigue igual y no cuenta como bajada de rendimiento.'**
  String get adjustIntro;

  /// No description provided for @adjustMinutesLabel.
  ///
  /// In es, this message translates to:
  /// **'Tiempo disponible'**
  String get adjustMinutesLabel;

  /// No description provided for @adjustMinutesChip.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String adjustMinutesChip(int minutes);

  /// No description provided for @adjustReducedLabel.
  ///
  /// In es, this message translates to:
  /// **'Volumen reducido'**
  String get adjustReducedLabel;

  /// No description provided for @adjustReducedHelp.
  ///
  /// In es, this message translates to:
  /// **'Una serie menos por ejercicio y 1 repetición más en reserva, sin subir carga.'**
  String get adjustReducedHelp;

  /// No description provided for @adjustPreview.
  ///
  /// In es, this message translates to:
  /// **'Ver cómo queda'**
  String get adjustPreview;

  /// No description provided for @adjustPickSomething.
  ///
  /// In es, this message translates to:
  /// **'Elige un tiempo o activa el volumen reducido.'**
  String get adjustPickSomething;

  /// No description provided for @adjustEstimated.
  ///
  /// In es, this message translates to:
  /// **'Duración estimada: {minutes} min'**
  String adjustEstimated(int minutes);

  /// No description provided for @adjustDroppedTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy se quitan:'**
  String get adjustDroppedTitle;

  /// No description provided for @adjustNothingDropped.
  ///
  /// In es, this message translates to:
  /// **'No se quita ningún ejercicio.'**
  String get adjustNothingDropped;

  /// No description provided for @adjustDoesNotFit.
  ///
  /// In es, this message translates to:
  /// **'Ni con lo esencial cabe en ese tiempo: haz lo que puedas, empezando por el principal.'**
  String get adjustDoesNotFit;

  /// No description provided for @adjustApply.
  ///
  /// In es, this message translates to:
  /// **'Empezar con este ajuste'**
  String get adjustApply;

  /// No description provided for @adjustBannerMinutes.
  ///
  /// In es, this message translates to:
  /// **'Sesión ajustada a {minutes} min'**
  String adjustBannerMinutes(int minutes);

  /// No description provided for @adjustBannerReduced.
  ///
  /// In es, this message translates to:
  /// **'Sesión con volumen reducido'**
  String get adjustBannerReduced;

  /// No description provided for @adjustBannerBoth.
  ///
  /// In es, this message translates to:
  /// **'Sesión ajustada a {minutes} min y con volumen reducido'**
  String adjustBannerBoth(int minutes);

  /// No description provided for @adjustBannerDropped.
  ///
  /// In es, this message translates to:
  /// **'Hoy sin: {names}'**
  String adjustBannerDropped(String names);

  /// No description provided for @adjustRemove.
  ///
  /// In es, this message translates to:
  /// **'Volver a la sesión completa'**
  String get adjustRemove;

  /// No description provided for @settingsSchedule.
  ///
  /// In es, this message translates to:
  /// **'Días de entreno, pausas y recordatorio'**
  String get settingsSchedule;

  /// No description provided for @settingsScheduleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Qué días entrenas, vacaciones y aviso en el móvil'**
  String get settingsScheduleSubtitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Días y pausas'**
  String get scheduleTitle;

  /// No description provided for @scheduleDaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Días de entreno'**
  String get scheduleDaysTitle;

  /// No description provided for @scheduleDaysIntro.
  ///
  /// In es, this message translates to:
  /// **'Sirven para el recordatorio y para saber si hoy toca. No cambian tu plan: sigue el orden de tus sesiones.'**
  String get scheduleDaysIntro;

  /// No description provided for @scheduleDaysCount.
  ///
  /// In es, this message translates to:
  /// **'{count} de {max} días elegidos'**
  String scheduleDaysCount(int count, int max);

  /// No description provided for @scheduleDaysDefault.
  ///
  /// In es, this message translates to:
  /// **'Sin días elegidos: se usan los días del plan.'**
  String get scheduleDaysDefault;

  /// No description provided for @scheduleDaysTooMany.
  ///
  /// In es, this message translates to:
  /// **'Tu plan tiene {max} días por semana: elige {max} como mucho.'**
  String scheduleDaysTooMany(int max);

  /// No description provided for @scheduleDaysSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar días'**
  String get scheduleDaysSave;

  /// No description provided for @scheduleDaysSaved.
  ///
  /// In es, this message translates to:
  /// **'Días de entreno guardados.'**
  String get scheduleDaysSaved;

  /// No description provided for @scheduleBreaksTitle.
  ///
  /// In es, this message translates to:
  /// **'Pausas'**
  String get scheduleBreaksTitle;

  /// No description provided for @scheduleBreaksIntro.
  ///
  /// In es, this message translates to:
  /// **'Vacaciones o días sin entrenar (de 1 a 60 días). No cuentan en tu adherencia, no bajan la carga al volver y el recordatorio no suena.'**
  String get scheduleBreaksIntro;

  /// No description provided for @scheduleBreaksEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes pausas planificadas.'**
  String get scheduleBreaksEmpty;

  /// No description provided for @scheduleBreakRange.
  ///
  /// In es, this message translates to:
  /// **'Del {start} al {end}'**
  String scheduleBreakRange(String start, String end);

  /// No description provided for @scheduleBreakDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String scheduleBreakDays(int count);

  /// No description provided for @scheduleBreakAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir pausa'**
  String get scheduleBreakAdd;

  /// No description provided for @scheduleBreakPickerHelp.
  ///
  /// In es, this message translates to:
  /// **'Elige el primer y el último día'**
  String get scheduleBreakPickerHelp;

  /// No description provided for @scheduleBreakTooLong.
  ///
  /// In es, this message translates to:
  /// **'Una pausa dura como mucho 60 días.'**
  String get scheduleBreakTooLong;

  /// No description provided for @scheduleBreakAdded.
  ///
  /// In es, this message translates to:
  /// **'Pausa añadida.'**
  String get scheduleBreakAdded;

  /// No description provided for @scheduleBreakDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar pausa'**
  String get scheduleBreakDelete;

  /// No description provided for @scheduleBreakDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar esta pausa?'**
  String get scheduleBreakDeleteTitle;

  /// No description provided for @scheduleBreakDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Esos días volverán a contar en tu adherencia.'**
  String get scheduleBreakDeleteBody;

  /// No description provided for @scheduleBreakDeleted.
  ///
  /// In es, this message translates to:
  /// **'Pausa borrada.'**
  String get scheduleBreakDeleted;

  /// No description provided for @scheduleReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio'**
  String get scheduleReminderTitle;

  /// No description provided for @scheduleReminderToggle.
  ///
  /// In es, this message translates to:
  /// **'Recordarme los días de entreno'**
  String get scheduleReminderToggle;

  /// No description provided for @scheduleReminderHelp.
  ///
  /// In es, this message translates to:
  /// **'Un aviso en este móvil, sin pasar por nuestro servidor. No suena en las pausas.'**
  String get scheduleReminderHelp;

  /// No description provided for @scheduleReminderTime.
  ///
  /// In es, this message translates to:
  /// **'Hora: {time}'**
  String scheduleReminderTime(String time);

  /// No description provided for @scheduleReminderTimeEdit.
  ///
  /// In es, this message translates to:
  /// **'Cambiar la hora del recordatorio'**
  String get scheduleReminderTimeEdit;

  /// No description provided for @scheduleReminderPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Te avisamos?'**
  String get scheduleReminderPermissionTitle;

  /// No description provided for @scheduleReminderPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Para avisarte los días de entreno, Android te pedirá permiso para mostrar notificaciones. Solo usamos este permiso para el recordatorio.'**
  String get scheduleReminderPermissionBody;

  /// No description provided for @scheduleReminderPermissionContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get scheduleReminderPermissionContinue;

  /// No description provided for @scheduleReminderPermissionLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get scheduleReminderPermissionLater;

  /// No description provided for @scheduleReminderDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso no podemos avisarte. Puedes activarlo en los ajustes del sistema.'**
  String get scheduleReminderDenied;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy toca entrenar'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión te espera en Pipos Fitness.'**
  String get reminderNotificationBody;

  /// No description provided for @todayBreakNotice.
  ///
  /// In es, this message translates to:
  /// **'Estás en pausa hasta el {date}. Si te apetece, puedes entrenar igualmente.'**
  String todayBreakNotice(String date);

  /// No description provided for @todayRestDayNotice.
  ///
  /// In es, this message translates to:
  /// **'Hoy no es uno de tus días de entreno. Puedes descansar o entrenar igualmente.'**
  String get todayRestDayNotice;

  /// No description provided for @progressAdherenceBreakDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día en pausa: no cuenta} other{{count} días en pausa: no cuentan}}'**
  String progressAdherenceBreakDays(int count);

  /// No description provided for @progressTabTraining.
  ///
  /// In es, this message translates to:
  /// **'Entreno'**
  String get progressTabTraining;

  /// No description provided for @progressTabBody.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo'**
  String get progressTabBody;

  /// No description provided for @bodyConsentNeededTitle.
  ///
  /// In es, this message translates to:
  /// **'Tus medidas son datos de salud'**
  String get bodyConsentNeededTitle;

  /// No description provided for @bodyConsentNeededBody.
  ///
  /// In es, this message translates to:
  /// **'Para registrar peso y perímetros y ver su evolución necesitamos tu consentimiento. Puedes retirarlo cuando quieras y se borran.'**
  String get bodyConsentNeededBody;

  /// No description provided for @bodyConsentUpgradeBody.
  ///
  /// In es, this message translates to:
  /// **'Tu consentimiento cubre el peso. Para perímetros, IMC y % de grasa estimado acepta la versión nueva del texto.'**
  String get bodyConsentUpgradeBody;

  /// No description provided for @bodyConsentReview.
  ///
  /// In es, this message translates to:
  /// **'Leer y aceptar'**
  String get bodyConsentReview;

  /// No description provided for @bodyAddMeasurement.
  ///
  /// In es, this message translates to:
  /// **'Añadir medidas'**
  String get bodyAddMeasurement;

  /// No description provided for @bodyEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has registrado medidas. Pésate y mide siempre en condiciones parecidas (por ejemplo, por la mañana).'**
  String get bodyEmpty;

  /// No description provided for @bodyWeightTitle.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get bodyWeightTitle;

  /// No description provided for @bodyWeightLatest.
  ///
  /// In es, this message translates to:
  /// **'Último: {kg} ({date})'**
  String bodyWeightLatest(String kg, String date);

  /// No description provided for @bodyTrendStatus.
  ///
  /// In es, this message translates to:
  /// **'{status, select, on_track{Vas a buen ritmo} too_fast{Vas demasiado rápido} too_slow{Vas más lento de lo previsto} wrong_direction{Vas en sentido contrario a tu objetivo} no_target{Tu objetivo no fija un ritmo} insufficient_data{Faltan datos para ver el ritmo} other{{status}}}'**
  String bodyTrendStatus(String status);

  /// No description provided for @bodyTrendRate.
  ///
  /// In es, this message translates to:
  /// **'{rate} % por semana'**
  String bodyTrendRate(String rate);

  /// No description provided for @bodyTrendTarget.
  ///
  /// In es, this message translates to:
  /// **'{direction, select, loss{Objetivo: perder entre el {min} y el {max} % por semana} gain{Objetivo: ganar entre el {min} y el {max} % por semana} other{}}'**
  String bodyTrendTarget(String direction, String min, String max);

  /// No description provided for @bodyChartLabel.
  ///
  /// In es, this message translates to:
  /// **'Peso: de {first} a {last} kg en {period}'**
  String bodyChartLabel(String first, String last, String period);

  /// No description provided for @bodyChartTitle.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg): media móvil de 7 días en cada pesada'**
  String get bodyChartTitle;

  /// No description provided for @bodyEstimateLabel.
  ///
  /// In es, this message translates to:
  /// **'Estimación — no es un diagnóstico'**
  String get bodyEstimateLabel;

  /// No description provided for @bodyBmiTitle.
  ///
  /// In es, this message translates to:
  /// **'Índice de masa corporal (IMC)'**
  String get bodyBmiTitle;

  /// No description provided for @bmiCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'{category, select, underweight{Bajo peso} normal{Peso normal} pre_obese{Sobrepeso (preobesidad)} obese_class_1{Obesidad de clase I} obese_class_2{Obesidad de clase II} obese_class_3{Obesidad de clase III} other{{category}}}'**
  String bmiCategoryLabel(String category);

  /// No description provided for @bodyBmiWhoNote.
  ///
  /// In es, this message translates to:
  /// **'Categorías de la OMS para adultos.'**
  String get bodyBmiWhoNote;

  /// No description provided for @bodyFatTitle.
  ///
  /// In es, this message translates to:
  /// **'% de grasa estimado'**
  String get bodyFatTitle;

  /// No description provided for @bodyFatValue.
  ///
  /// In es, this message translates to:
  /// **'{value} %'**
  String bodyFatValue(String value);

  /// No description provided for @bodyNotApplicable.
  ///
  /// In es, this message translates to:
  /// **'No aplica'**
  String get bodyNotApplicable;

  /// No description provided for @bodyEstimateStatus.
  ///
  /// In es, this message translates to:
  /// **'{status, select, insufficient_data{Faltan datos para calcularlo.} consent_required{Requiere aceptar la versión nueva del consentimiento de salud.} invalid_input{Revisa las medidas: no se puede calcular.} other{}}'**
  String bodyEstimateStatus(String status);

  /// No description provided for @bodyBmiMissing.
  ///
  /// In es, this message translates to:
  /// **'Necesita tu peso y tu altura (perfil).'**
  String get bodyBmiMissing;

  /// No description provided for @bodyFatMissing.
  ///
  /// In es, this message translates to:
  /// **'Necesita cintura, cuello y, en mujeres, cadera del mismo día, y tu altura.'**
  String get bodyFatMissing;

  /// No description provided for @bodyMeasuredOn.
  ///
  /// In es, this message translates to:
  /// **'Medido el {date}'**
  String bodyMeasuredOn(String date);

  /// No description provided for @bodyCircumferencesTitle.
  ///
  /// In es, this message translates to:
  /// **'Perímetros'**
  String get bodyCircumferencesTitle;

  /// No description provided for @bodyCircumferencesNote.
  ///
  /// In es, this message translates to:
  /// **'Pecho, brazo y muslo son solo de seguimiento.'**
  String get bodyCircumferencesNote;

  /// No description provided for @bodyFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'{field, select, weightKg{Peso} waistCm{Cintura} neckCm{Cuello} hipCm{Cadera} chestCm{Pecho} armCm{Brazo} thighCm{Muslo} other{{field}}}'**
  String bodyFieldLabel(String field);

  /// No description provided for @bodyFieldHelp.
  ///
  /// In es, this message translates to:
  /// **'{field, select, weightKg{Por la mañana, tras ir al baño y antes de comer.} waistCm{Hombres: a la altura del ombligo. Mujeres: en la parte más estrecha de la cintura. Al final de una espiración normal.} neckCm{Justo por debajo de la nuez (laringe).} hipCm{En la parte más ancha de los glúteos.} chestCm{A la altura de los pezones, al final de una espiración normal.} armCm{Brazo relajado, en el punto medio entre el hombro y el codo.} thighCm{En el punto medio entre la ingle y la rótula.} other{}}'**
  String bodyFieldHelp(String field);

  /// No description provided for @bodyCm.
  ///
  /// In es, this message translates to:
  /// **'{value} cm'**
  String bodyCm(String value);

  /// No description provided for @bodyLatestValue.
  ///
  /// In es, this message translates to:
  /// **'{value} ({date})'**
  String bodyLatestValue(String value, String date);

  /// No description provided for @bodyChange.
  ///
  /// In es, this message translates to:
  /// **'{weeks, select, w4{Δ 4 sem: {change}} w12{Δ 12 sem: {change}} other{}}'**
  String bodyChange(String weeks, String change);

  /// No description provided for @bodyNoValue.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get bodyNoValue;

  /// No description provided for @bodyHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get bodyHistoryTitle;

  /// No description provided for @bodyHistoryDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar las medidas del {date}'**
  String bodyHistoryDelete(String date);

  /// No description provided for @bodyHistoryDeleted.
  ///
  /// In es, this message translates to:
  /// **'Medidas borradas.'**
  String get bodyHistoryDeleted;

  /// No description provided for @measureTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir medidas'**
  String get measureTitle;

  /// No description provided for @measureIntro.
  ///
  /// In es, this message translates to:
  /// **'Todas son opcionales: rellena al menos una. Mide siempre igual y en condiciones parecidas.'**
  String get measureIntro;

  /// No description provided for @measureDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha: {date}'**
  String measureDate(String date);

  /// No description provided for @measureDateEdit.
  ///
  /// In es, this message translates to:
  /// **'Cambiar la fecha'**
  String get measureDateEdit;

  /// No description provided for @measureAtLeastOne.
  ///
  /// In es, this message translates to:
  /// **'Introduce al menos una medida.'**
  String get measureAtLeastOne;

  /// No description provided for @measureNeedsConsent.
  ///
  /// In es, this message translates to:
  /// **'Los perímetros requieren aceptar la versión nueva del consentimiento de salud.'**
  String get measureNeedsConsent;

  /// No description provided for @measureSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar medidas'**
  String get measureSave;

  /// No description provided for @measureSaved.
  ///
  /// In es, this message translates to:
  /// **'Medidas guardadas.'**
  String get measureSaved;

  /// No description provided for @measureUnitKg.
  ///
  /// In es, this message translates to:
  /// **'kg'**
  String get measureUnitKg;

  /// No description provided for @measureUnitCm.
  ///
  /// In es, this message translates to:
  /// **'cm'**
  String get measureUnitCm;

  /// No description provided for @chartPeriodWeeks.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 semana} other{{count} semanas}}'**
  String chartPeriodWeeks(int count);

  /// No description provided for @chartPeriodDays.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día} other{{count} días}}'**
  String chartPeriodDays(int count);

  /// No description provided for @progressVolumeSets.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{sets} serie} other{{sets} series}}'**
  String progressVolumeSets(num count, String sets);

  /// No description provided for @progressVolumeTarget.
  ///
  /// In es, this message translates to:
  /// **'objetivo {min}–{max}'**
  String progressVolumeTarget(String min, String max);

  /// No description provided for @progressVolumeLegendBelow.
  ///
  /// In es, this message translates to:
  /// **'Por debajo del rango'**
  String get progressVolumeLegendBelow;

  /// No description provided for @progressVolumeLegendWithin.
  ///
  /// In es, this message translates to:
  /// **'Dentro del rango'**
  String get progressVolumeLegendWithin;

  /// No description provided for @progressVolumeLegendAbove.
  ///
  /// In es, this message translates to:
  /// **'Por encima del rango'**
  String get progressVolumeLegendAbove;

  /// No description provided for @progressVolumeLegendBand.
  ///
  /// In es, this message translates to:
  /// **'La franja marca el rango objetivo de series efectivas.'**
  String get progressVolumeLegendBand;

  /// No description provided for @settingsHealthGrantedNoDate.
  ///
  /// In es, this message translates to:
  /// **'Consentimiento de salud dado'**
  String get settingsHealthGrantedNoDate;

  /// No description provided for @settingsLegalConsentVersion.
  ///
  /// In es, this message translates to:
  /// **'Tu consentimiento de salud: versión {version} del texto, aceptada el {date}.'**
  String settingsLegalConsentVersion(String version, String date);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
