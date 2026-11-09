// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pipos Fitness';

  @override
  String get splashLoading => 'Cargando tu sesión…';

  @override
  String get navToday => 'Hoy';

  @override
  String get navPlan => 'Plan';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get offlineBanner => 'Sin conexión: mostrando datos guardados';

  @override
  String pendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series pendientes de sincronizar',
      one: '1 serie pendiente de sincronizar',
    );
    return '$_temp0';
  }

  @override
  String failedSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series no se pudieron enviar',
      one: '1 serie no se pudo enviar',
    );
    return '$_temp0';
  }

  @override
  String get syncRetry => 'Reintentar';

  @override
  String get syncStatusPending => 'Pendiente de sincronizar';

  @override
  String get syncStatusSynced => 'Sincronizada';

  @override
  String get syncStatusFailed => 'No se pudo enviar';

  @override
  String get setRejectedInvalid =>
      'La API no la acepta: el ejercicio o los datos no valen para este hueco.';

  @override
  String get setRejectedFinished =>
      'La API no la acepta: el entrenamiento ya estaba terminado.';

  @override
  String get setRejectedNotStarted =>
      'No se pudo enviar: el entrenamiento no llegó a empezar en el servidor.';

  @override
  String setRejectedOther(String code) {
    return 'No se pudo enviar ($code).';
  }

  @override
  String get setDiscard => 'Descartar';

  @override
  String setDiscardFor(int number) {
    return 'Descartar la serie $number';
  }

  @override
  String setDiscardTitle(int number) {
    return '¿Descartar la serie $number?';
  }

  @override
  String get setDiscardBody =>
      'Se quitará de este móvil y no contará en el entrenamiento. No se puede deshacer.';

  @override
  String setActionsFor(int number) {
    return 'Opciones de la serie $number';
  }

  @override
  String get setEdit => 'Editar';

  @override
  String setEditTitle(int number) {
    return 'Corregir la serie $number';
  }

  @override
  String get setEditHint =>
      'Se guarda en este móvil y se envía cuando haya conexión.';

  @override
  String get setEditSave => 'Guardar cambios';

  @override
  String get setDelete => 'Borrar';

  @override
  String setDeleteTitle(int number) {
    return '¿Borrar la serie $number?';
  }

  @override
  String get setDeleteBody =>
      'Dejará de contar en el entrenamiento y en tu progreso. No se puede deshacer.';

  @override
  String cachedDataNotice(String date) {
    return 'Sin conexión. Datos guardados el $date.';
  }

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldConfirmPassword => 'Confirmar contraseña';

  @override
  String get validationEmailInvalid => 'Introduce un correo válido';

  @override
  String get validationPasswordRequired => 'Introduce tu contraseña';

  @override
  String validationPasswordTooShort(int min) {
    return 'La contraseña debe tener al menos $min caracteres';
  }

  @override
  String get validationPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginGoToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubmit => 'Crear cuenta';

  @override
  String get registerGoToLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'Ya existe una cuenta con este correo.';

  @override
  String get authErrorInvalidInput => 'Revisa los datos introducidos.';

  @override
  String get authErrorSessionExpired =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorNetwork => 'Sin conexión a internet.';

  @override
  String get errorTimeout =>
      'La petición ha tardado demasiado. Inténtalo de nuevo.';

  @override
  String get errorServer => 'Error del servidor. Inténtalo más tarde.';

  @override
  String get errorUnauthorized =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorBadRequest => 'La solicitud no es válida.';

  @override
  String get errorParse => 'El servidor devolvió una respuesta inesperada.';

  @override
  String get errorUnknown => 'Ha ocurrido un error inesperado.';

  @override
  String get errorRateLimited =>
      'Demasiadas peticiones. Espera un momento y vuelve a intentarlo.';

  @override
  String get errorPlanGeneration =>
      'No hemos podido generar el plan con estos datos. Revisa el material o los días y vuelve a intentarlo.';

  @override
  String get errorConsentRequired =>
      'Para guardar limitaciones o datos corporales necesitamos tu consentimiento de salud.';

  @override
  String get errorOfflineAction => 'Necesitas conexión para hacer esto.';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionShowMore => 'Por qué';

  @override
  String get actionShowLess => 'Ocultar explicación';

  @override
  String get configErrorTitle => 'Configuración incompleta';

  @override
  String get configErrorBody =>
      'Esta compilación no define la URL de la API. Vuelve a compilar con --dart-define=API_BASE_URL=https://…';

  @override
  String get medicalNotice =>
      'Pipos Fitness no da consejo médico. Si tienes dolor, una lesión o una condición de salud, consulta a un profesional antes de entrenar.';

  @override
  String get screeningNotice =>
      'Si tienes dolor al entrenar, una lesión reciente o alguna condición médica, consulta a un profesional sanitario antes de empezar. Esta app no diagnostica ni trata lesiones.';

  @override
  String get onboardingTitle => 'Tu plan en 3 minutos';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingGoalTitle => '¿Qué quieres conseguir?';

  @override
  String get onboardingLevelTitle => '¿Cuánta experiencia tienes con pesas?';

  @override
  String get onboardingScheduleTitle => '¿Cuánto tiempo tienes?';

  @override
  String get onboardingDaysLabel => 'Días por semana';

  @override
  String onboardingDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get onboardingMinutesLabel => 'Minutos por sesión';

  @override
  String onboardingMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get onboardingEquipmentTitle => '¿Con qué material cuentas?';

  @override
  String get onboardingEquipmentHint =>
      'Marca todo lo que tengas a mano. El plan solo usará ejercicios que puedas hacer.';

  @override
  String get onboardingEquipmentPresetGym => 'Gimnasio completo';

  @override
  String get onboardingEquipmentPresetHome => 'Casa con mancuernas';

  @override
  String get onboardingEquipmentPresetBodyweight => 'Solo peso corporal';

  @override
  String get onboardingConsentTitle => 'Datos de salud (opcional)';

  @override
  String get onboardingConsentIntro =>
      'Para evitar ejercicios que puedan agravar una molestia, y para calcular tus objetivos de nutrición, necesitamos tratar datos de salud. Es opcional y puedes retirarlo cuando quieras.';

  @override
  String onboardingConsentVersion(String version) {
    return 'Versión del texto: $version';
  }

  @override
  String get onboardingConsentAccept => 'Acepto';

  @override
  String get onboardingConsentSkip => 'Continuar sin datos de salud';

  @override
  String get onboardingConsentSkippedNote =>
      'Sin este consentimiento tu plan no tendrá en cuenta limitaciones ni datos corporales. Puedes darlo más tarde en Ajustes.';

  @override
  String get healthConsentText =>
      'Acepto que Pipos Fitness trate mis datos de salud (peso, altura, limitaciones o molestias por zona del cuerpo y medidas corporales: perímetros de cintura, cuello, cadera, pecho, brazo y muslo) con el fin de adaptar mi plan de entrenamiento y mis objetivos nutricionales, y de mostrarme su evolución y estimaciones derivadas (índice de masa corporal y porcentaje de grasa estimado). Puedo retirar este consentimiento en cualquier momento desde Ajustes; al hacerlo se borran esos datos, incluido el registro de medidas, y el plan se regenera sin ellos. Las estimaciones no son un diagnóstico y Pipos Fitness no da consejo médico.';

  @override
  String get onboardingLimitationsTitle => '¿Alguna zona con molestias?';

  @override
  String get onboardingLimitationsHint =>
      'El plan evitará los movimientos de riesgo para esas zonas y te propondrá variantes.';

  @override
  String get onboardingNoLimitations => 'Ninguna';

  @override
  String get onboardingPreferencesTitle => 'Preferencias (opcional)';

  @override
  String onboardingPriorityLabel(int max) {
    return 'Músculos prioritarios (hasta $max)';
  }

  @override
  String get onboardingFavouritesLabel => 'Ejercicios favoritos';

  @override
  String get onboardingBannedLabel => 'Ejercicios que no quieres hacer';

  @override
  String get onboardingAddExercise => 'Añadir ejercicio';

  @override
  String onboardingRemoveExercise(String name) {
    return 'Quitar $name';
  }

  @override
  String get exercisePickerTitle => 'Buscar ejercicio';

  @override
  String get exercisePickerHint => 'Nombre del ejercicio';

  @override
  String get exercisePickerEmpty => 'No hay ejercicios con ese nombre.';

  @override
  String get onboardingBodyTitle => 'Sobre ti (opcional)';

  @override
  String get onboardingBodyHint =>
      'Solo se usan para calcular tus objetivos de nutrición. Puedes dejarlos en blanco.';

  @override
  String get onboardingBodyNeedsConsent =>
      'El peso y la altura son datos de salud: solo se guardan si das tu consentimiento.';

  @override
  String get fieldBirthYear => 'Año de nacimiento';

  @override
  String get fieldSex => 'Sexo';

  @override
  String get fieldWeightKg => 'Peso (kg)';

  @override
  String get fieldHeightCm => 'Altura (cm)';

  @override
  String get fieldActivityLevel => 'Actividad diaria fuera del gimnasio';

  @override
  String get fieldTimezone => 'Zona horaria';

  @override
  String get fieldNotSpecified => 'Prefiero no decirlo';

  @override
  String onboardingTimezoneAuto(String timezone) {
    return 'Detectada en tu dispositivo: $timezone';
  }

  @override
  String get onboardingReviewTitle => 'Revisa y genera tu plan';

  @override
  String get onboardingGenerate => 'Generar mi plan';

  @override
  String get onboardingGenerating => 'Generando tu plan…';

  @override
  String get onboardingSaveChanges => 'Guardar cambios';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingResultTitle => 'Tu plan está listo';

  @override
  String get onboardingResultStart => 'Ver la sesión de hoy';

  @override
  String get validationRequired => 'Elige una opción';

  @override
  String get validationEquipmentRequired =>
      'Elige al menos un material (o «Peso corporal»)';

  @override
  String validationRange(String min, String max) {
    return 'Debe estar entre $min y $max';
  }

  @override
  String get validationNumber => 'Introduce un número';

  @override
  String validationAdult(int age) {
    return 'La app es solo para mayores de $age años';
  }

  @override
  String validationPriorityMax(int max) {
    return 'Elige como máximo $max';
  }

  @override
  String get validationBannedFavourite =>
      'Un ejercicio no puede ser favorito y vetado a la vez';

  @override
  String get validationServerField => 'Revisa este campo';

  @override
  String get validationFixErrors => 'Revisa los campos marcados.';

  @override
  String get todayTitle => 'Hoy';

  @override
  String get todayEmptyTitle => 'Aún no tienes plan';

  @override
  String get todayEmptyBody =>
      'Completa el cuestionario para recibir tu plan y tu sesión de hoy.';

  @override
  String get todayEmptyAction => 'Empezar el cuestionario';

  @override
  String get todayOfflineNoData =>
      'Sin conexión y sin datos guardados. Conéctate una vez para descargar tu sesión.';

  @override
  String todaySessionMeta(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
    );
    return '$minutes min estimados · $_temp0';
  }

  @override
  String todayGeneralWarmup(int minutes) {
    return 'Calentamiento general: $minutes min de movilidad o cardio suave';
  }

  @override
  String get todayWarmupSets => 'Series de aproximación';

  @override
  String todayWarmupSet(int reps, String load) {
    return '$reps reps · $load';
  }

  @override
  String todayTarget(int sets, int repMin, int repMax, int rir) {
    return '$sets × $repMin–$repMax reps · RIR $rir';
  }

  @override
  String todaySuggestedLoad(String load) {
    return 'Carga sugerida: $load';
  }

  @override
  String get todayInitialEstimate => 'Estimación inicial';

  @override
  String todayInitialEstimateHelp(int rir) {
    return 'Aún no conocemos tu carga: elige un peso con el que te queden unas $rir repeticiones en reserva.';
  }

  @override
  String get todayDeload => 'Descarga';

  @override
  String todaySubstitutedFrom(String name) {
    return 'Sustituye a $name';
  }

  @override
  String todayRest(int seconds) {
    return 'Descanso $seconds s';
  }

  @override
  String get todayCues => 'Claves técnicas';

  @override
  String todaySetLabel(int index) {
    return 'Serie $index';
  }

  @override
  String todaySetDone(int reps, String load, String rir) {
    return '$reps × $load · RIR $rir';
  }

  @override
  String get fieldReps => 'Reps';

  @override
  String get fieldLoad => 'Kg';

  @override
  String get fieldRir => 'RIR';

  @override
  String get rirPickerTitle => 'Repeticiones en reserva (RIR)';

  @override
  String get rirPickerHelp =>
      '¿Cuántas repeticiones más podrías haber hecho con buena técnica?';

  @override
  String rirValue(int rir) {
    return 'RIR $rir';
  }

  @override
  String todayConfirmSet(int index) {
    return 'Confirmar serie $index';
  }

  @override
  String get todayExerciseDone => 'Ejercicio completado';

  @override
  String get todaySwap => 'Cambiar ejercicio';

  @override
  String get todayFinish => 'Terminar entrenamiento';

  @override
  String get todayAbandon => 'Abandonar entrenamiento';

  @override
  String get todayAbandonTitle => '¿Abandonar el entrenamiento?';

  @override
  String get todayAbandonBody =>
      'Lo registrado se conserva pero no contará en tu progreso ni en la adherencia, y no podrás añadir más series. Se enviará aunque ahora no tengas conexión.';

  @override
  String get todayAbandoned => 'Entrenamiento abandonado.';

  @override
  String todayClosedRemotely(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series no llegaron a subirse.',
      one: '1 serie no llegó a subirse.',
      zero: 'No quedó nada sin subir.',
    );
    return 'Tu entrenamiento anterior se cerró en el servidor (p. ej., se abandonó solo tras 12 h sin actividad). $_temp0';
  }

  @override
  String get actionUnderstood => 'Entendido';

  @override
  String get todayFinishConfirmTitle => '¿Terminar el entrenamiento?';

  @override
  String todayFinishConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Te quedan $count series sin registrar.',
      one: 'Te queda 1 serie sin registrar.',
      zero: 'Has completado todas las series.',
    );
    return '$_temp0 Lo registrado se guarda igualmente.';
  }

  @override
  String get todayFinishConfirm => 'Terminar';

  @override
  String todayFinishUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count series sin enviar.',
      one: 'Hay 1 serie sin enviar.',
    );
    return '$_temp0 Se reintentará antes de cerrar el entrenamiento; mientras no se envíe, el cierre queda en espera.';
  }

  @override
  String get todayFinishRetryNow => 'Reintentar envío';

  @override
  String todayStaleSession(String date) {
    return 'Sesión guardada del $date. Sin conexión no podemos saber qué sesión toca hoy; puedes registrarla igualmente y se sincronizará al volver la red.';
  }

  @override
  String get todayNoUserOffline =>
      'No se pudo registrar la serie: conéctate a internet una vez para verificar tu sesión.';

  @override
  String todayConflictBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return 'Un entrenamiento guardado en este móvil ($_temp0) no se pudo empezar en el servidor: ya hay otro en curso en tu cuenta. Termina ese entrenamiento y pulsa «Reintentar», o descarta el de este móvil.';
  }

  @override
  String todayPlanOutdatedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return 'Tu plan cambió mientras entrenabas sin conexión: este entrenamiento guardado en el móvil ($_temp0) es de la sesión anterior y no se puede subir. Se conserva aquí hasta que lo descartes.';
  }

  @override
  String get setRejectedPlanOutdated =>
      'Tu plan cambió: esta serie es de la sesión anterior y no se puede subir.';

  @override
  String get todayConflictDiscard => 'Descartar';

  @override
  String get todayConflictDiscardTitle =>
      '¿Descartar el entrenamiento de este móvil?';

  @override
  String todayConflictDiscardBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se borrarán $count series que no llegaron al servidor.',
      one: 'Se borrará 1 serie que no llegó al servidor.',
    );
    return '$_temp0 No se puede deshacer.';
  }

  @override
  String get todayStartHint =>
      'El entrenamiento empieza al confirmar la primera serie.';

  @override
  String get restTimerLabel => 'Descanso';

  @override
  String restTimerRemaining(String time) {
    return 'Descanso: quedan $time';
  }

  @override
  String get restTimerSkip => 'Saltar descanso';

  @override
  String get restTimerAdd => 'Añadir 15 segundos';

  @override
  String get restTimerDone => 'Descanso terminado';

  @override
  String get restNotificationTitle => 'Descanso terminado';

  @override
  String get restNotificationBody => 'Toca para seguir con la siguiente serie.';

  @override
  String swapTitle(String name) {
    return 'Alternativas a $name';
  }

  @override
  String get swapHint =>
      'Ordenadas por parecido: mismo patrón, músculos y tu material.';

  @override
  String get swapEmpty =>
      'No hay alternativas compatibles con tu material y tus limitaciones.';

  @override
  String swapChoose(String name) {
    return 'Usar $name';
  }

  @override
  String swapDone(String name) {
    return 'Ejercicio cambiado por $name';
  }

  @override
  String swapQueued(String name) {
    return 'Cambio a $name guardado. Se enviará al recuperar la conexión.';
  }

  @override
  String get swapOfflineNotice =>
      'Sin conexión: alternativas guardadas hoy. El cambio de hoy se enviará al volver la red; fijarlo en el plan necesita conexión.';

  @override
  String get swapPinNeedsNetwork =>
      'Fijar el cambio en el plan necesita conexión. Sin red puedes cambiarlo solo para hoy.';

  @override
  String get swapPendingBadge => 'Cambio pendiente de enviar';

  @override
  String get completeTitle => '¡Entrenamiento completado!';

  @override
  String completeSummary(int count, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series registradas',
      one: '1 serie registrada',
    );
    return '$_temp0 · $volume kg movidos';
  }

  @override
  String get completeSynced => 'Todo sincronizado.';

  @override
  String get completePending =>
      'Se sincronizará cuando haya conexión. No se perderá nada.';

  @override
  String get completeBack => 'Volver a Hoy';

  @override
  String get planTitle => 'Tu plan';

  @override
  String planVersionLabel(int version) {
    return 'Versión $version';
  }

  @override
  String get planWhySplit => 'Por qué este reparto';

  @override
  String get planWarnings => 'Avisos';

  @override
  String get planSessions => 'Sesiones';

  @override
  String planSessionMeta(String day, int minutes) {
    return '$day · $minutes min';
  }

  @override
  String planExerciseLine(int sets, int repMin, int repMax, int rir, int rest) {
    return '$sets × $repMin–$repMax · RIR $rir · $rest s descanso';
  }

  @override
  String get planHistory => 'Historial de versiones';

  @override
  String get planHistoryEmpty => 'Solo tienes una versión del plan.';

  @override
  String planHistoryItem(int version, String date) {
    return 'Versión $version · $date';
  }

  @override
  String get planCurrentBadge => 'Actual';

  @override
  String get planWeeklyVolume => 'Series semanales por grupo';

  @override
  String planVolumeRange(String sets, String min, String max) {
    return '$sets series (objetivo $min–$max)';
  }

  @override
  String get progressTitle => 'Progreso';

  @override
  String get progressE1rmTitle => 'Fuerza estimada (e1RM)';

  @override
  String get progressE1rmEmpty =>
      'Registra tus primeras series con carga para ver tu e1RM.';

  @override
  String progressE1rmValue(String kg) {
    return '$kg kg';
  }

  @override
  String progressE1rmTrend(
    String name,
    String first,
    String last,
    String since,
    String until,
    int count,
  ) {
    return '$name: de $first a $last kg entre el $since y el $until ($count sesiones)';
  }

  @override
  String get progressVolumeTitle => 'Series esta semana por grupo';

  @override
  String get progressVolumeEmpty =>
      'Cuando entrenes esta semana verás aquí tus series frente al rango objetivo.';

  @override
  String progressVolumeBar(
    String group,
    String sets,
    String min,
    String max,
    String status,
  ) {
    return '$group: $sets series, objetivo $min a $max, $status';
  }

  @override
  String get progressAdherenceTitle => 'Adherencia';

  @override
  String get progressAdherenceEmpty => 'Aún no hay semanas planificadas.';

  @override
  String progressAdherenceValue(int done, int planned, int percent) {
    return '$done de $planned sesiones ($percent %)';
  }

  @override
  String get progressEmptyTitle => 'Tu progreso aparecerá aquí';

  @override
  String get progressEmptyBody =>
      'Completa tu primera sesión para empezar a ver fuerza, volumen y adherencia.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsEmailOffline =>
      'Sin conexión: tu correo aparecerá al recuperar la red.';

  @override
  String get settingsProfile => 'Perfil de entrenamiento';

  @override
  String get settingsProfileSubtitle =>
      'Objetivo, días, minutos, material y preferencias';

  @override
  String get settingsHealth => 'Datos de salud y limitaciones';

  @override
  String settingsHealthGranted(String date) {
    return 'Consentimiento de salud dado el $date';
  }

  @override
  String get settingsHealthNotGranted =>
      'Sin consentimiento: el plan no usa limitaciones ni datos corporales';

  @override
  String get settingsHealthGrant => 'Dar consentimiento';

  @override
  String get settingsHealthWithdraw => 'Retirar consentimiento';

  @override
  String get settingsHealthWithdrawTitle => '¿Retirar el consentimiento?';

  @override
  String get settingsHealthWithdrawBody =>
      'Se borrarán tus limitaciones, peso y altura, y se generará una nueva versión del plan sin ellos.';

  @override
  String get settingsHealthWithdrawn =>
      'Consentimiento retirado. Tus datos de salud se han borrado.';

  @override
  String get settingsNutrition => 'Objetivos de nutrición';

  @override
  String settingsNutritionKcal(String kcal) {
    return '$kcal kcal al día';
  }

  @override
  String settingsNutritionMacros(String protein, String fat, String carbs) {
    return 'Proteína $protein g · Grasa $fat g · Hidratos $carbs g';
  }

  @override
  String get settingsNutritionIncomplete =>
      'Completa estos datos para calcularlos:';

  @override
  String get settingsNutritionComplete => 'Completar mis datos';

  @override
  String get settingsExport => 'Exportar mis datos';

  @override
  String get settingsExportSubtitle =>
      'Descarga un JSON con todo lo que guardamos sobre ti';

  @override
  String get settingsExportDone => 'Exportación lista';

  @override
  String get settingsDelete => 'Borrar cuenta';

  @override
  String get settingsDeleteSubtitle =>
      'Elimina tu cuenta y todos tus datos para siempre';

  @override
  String get settingsDeleteTitle => '¿Borrar tu cuenta?';

  @override
  String get settingsDeleteBody =>
      'Se borrarán para siempre tu perfil, tus planes, tus entrenamientos y tus datos de salud. No se puede deshacer. Escribe tu contraseña para confirmarlo.';

  @override
  String get settingsDeleteConfirm => 'Borrar mi cuenta';

  @override
  String get settingsDeleteWrongPassword => 'La contraseña no es correcta.';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get settingsLogoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get settingsLogoutConfirmBody =>
      'Se borrarán de este móvil tu plan y tus sesiones guardadas. Tus datos siguen en tu cuenta.';

  @override
  String settingsLogoutUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hay $count series sin enviar al servidor.',
      one: 'Hay 1 serie sin enviar al servidor.',
    );
    return '$_temp0 Si cierras sesión ahora se perderán. Conéctate a internet para enviarlas antes.';
  }

  @override
  String get settingsLegal => 'Aviso legal y médico';

  @override
  String get settingsProfileSaved => 'Perfil guardado.';

  @override
  String get settingsNewPlanTitle => 'Nueva versión del plan';

  @override
  String settingsNewPlanBody(int version) {
    return 'Tus cambios afectan al plan, así que hemos creado la versión $version. Tu historial y tu progreso se conservan, y la versión anterior sigue en el historial.';
  }

  @override
  String get settingsNewPlanAction => 'Ver el plan';

  @override
  String fieldNames(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'goal': 'Objetivo',
      'level': 'Nivel',
      'daysPerWeek': 'Días por semana',
      'minutesPerSession': 'Minutos por sesión',
      'equipment': 'Material',
      'priorityMuscles': 'Músculos prioritarios',
      'timezone': 'Zona horaria',
      'activityLevel': 'Actividad diaria',
      'birthYear': 'Año de nacimiento',
      'sex': 'Sexo',
      'bannedExerciseSlugs': 'Ejercicios vetados',
      'favouriteExerciseSlugs': 'Ejercicios favoritos',
      'limitations': 'Limitaciones',
      'weightKg': 'Peso',
      'heightCm': 'Altura',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'strength': 'Ganar fuerza',
      'hypertrophy': 'Ganar músculo',
      'general_health': 'Salud general',
      'fat_loss': 'Perder grasa',
      'muscular_endurance': 'Resistencia muscular',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String levelLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'beginner': 'Principiante (menos de 1 año)',
      'intermediate': 'Intermedio (1–3 años)',
      'advanced': 'Avanzado (más de 3 años)',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String equipmentLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'bodyweight': 'Peso corporal',
      'barbell': 'Barra olímpica',
      'ez_bar': 'Barra Z',
      'trap_bar': 'Barra hexagonal',
      'dumbbell': 'Mancuernas',
      'kettlebell': 'Kettlebell',
      'weight_plate': 'Discos',
      'bench': 'Banco',
      'squat_rack': 'Rack de sentadilla',
      'cable': 'Poleas',
      'machine': 'Máquinas',
      'smith_machine': 'Multipower',
      'pull_up_bar': 'Barra de dominadas',
      'dip_station': 'Paralelas',
      'gymnastic_rings': 'Anillas',
      'suspension_trainer': 'TRX',
      'resistance_band': 'Bandas elásticas',
      'medicine_ball': 'Balón medicinal',
      'plyo_box': 'Cajón',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String zoneLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'shoulder': 'Hombro',
      'elbow': 'Codo',
      'wrist': 'Muñeca',
      'lumbar': 'Zona lumbar',
      'hip': 'Cadera',
      'knee': 'Rodilla',
      'ankle': 'Tobillo',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String muscleLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'chest': 'Pecho',
      'front_delts': 'Deltoides anterior',
      'side_delts': 'Deltoides lateral',
      'rear_delts': 'Deltoides posterior',
      'lats': 'Dorsales',
      'upper_back': 'Espalda alta',
      'traps': 'Trapecio',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'forearms': 'Antebrazos',
      'abs': 'Abdominales',
      'obliques': 'Oblicuos',
      'lower_back': 'Lumbares',
      'glutes': 'Glúteos',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiotibiales',
      'adductors': 'Aductores',
      'abductors': 'Abductores',
      'calves': 'Gemelos',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String groupLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'chest': 'Pecho',
      'back': 'Espalda',
      'shoulders': 'Hombros',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quads': 'Cuádriceps',
      'hamstrings': 'Isquiotibiales',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'core': 'Core',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String sexLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'male': 'Hombre',
      'female': 'Mujer',
      'other': 'Otro',
    });
    return '$_temp0';
  }

  @override
  String activityLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sedentary_light': 'Sedentaria o ligera',
      'active': 'Activa (de pie, caminas a diario)',
      'vigorous': 'Muy activa (trabajo físico)',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String splitLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'full_body': 'Cuerpo completo',
      'upper_lower': 'Torso / pierna',
      'hybrid_ul_ppl': 'Torso-pierna + empuje-tirón-pierna',
      'push_pull_legs': 'Empuje / tirón / pierna',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String sessionKindLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'full_body': 'Cuerpo completo',
      'upper': 'Torso',
      'lower': 'Pierna',
      'push': 'Empuje',
      'pull': 'Tirón',
      'legs': 'Pierna',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String progressionLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'start': 'Primera sesión',
      'increase_load': 'Sube la carga',
      'increase_reps': 'Sube repeticiones',
      'hold': 'Mantén',
      'decrease_load': 'Baja la carga',
      'deload': 'Semana de descarga',
      'return_after_break': 'Vuelta tras una pausa',
      'progress_variant': 'Pasa a una variante más difícil',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String volumeStatusLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'below': 'por debajo',
      'within': 'dentro del rango',
      'above': 'por encima',
      'other': 'sin objetivo',
    });
    return '$_temp0';
  }

  @override
  String nutritionGoalLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'fat_loss': 'Pérdida de grasa',
      'maintenance': 'Mantenimiento',
      'muscle_gain': 'Ganancia muscular',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String weekdayLabel(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '0': 'Lunes',
      '1': 'Martes',
      '2': 'Miércoles',
      '3': 'Jueves',
      '4': 'Viernes',
      '5': 'Sábado',
      '6': 'Domingo',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String loadKgValue(String kg) {
    return '$kg kg';
  }

  @override
  String get loadBodyweight => 'Peso corporal';

  @override
  String loadPctValue(String pct) {
    return '$pct % de la carga';
  }

  @override
  String get settingsHealthUpdateBody =>
      'Hay una versión nueva del texto que añade las medidas corporales (perímetros) y las estimaciones de IMC y % de grasa. Tu consentimiento actual sigue cubriendo peso, altura y limitaciones.';

  @override
  String get settingsHealthUpdate => 'Leer y aceptar la versión nueva';

  @override
  String pendingChangesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios pendientes de sincronizar',
      one: '1 cambio pendiente de sincronizar',
    );
    return '$_temp0';
  }

  @override
  String failedChangesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cambios no se pudieron enviar',
      one: '1 cambio no se pudo enviar',
    );
    return '$_temp0';
  }

  @override
  String loadImplementLabel(String implement) {
    String _temp0 = intl.Intl.selectLogic(implement, {
      'barbell': 'Barra',
      'trap_bar': 'Barra hexagonal',
      'ez_bar': 'Barra EZ',
      'smith_machine': 'Multipower',
      'dumbbell': 'Mancuernas',
      'kettlebell': 'Kettlebell',
      'machine': 'Máquina',
      'cable': 'Polea',
      'weight_plate': 'Disco',
      'other': '$implement',
    });
    return '$_temp0';
  }

  @override
  String todayLoadStep(String implement, String step) {
    return '$implement · de $step en $step';
  }

  @override
  String get platesButton => 'Discos';

  @override
  String platesButtonFor(String kg) {
    return 'Ver discos para $kg';
  }

  @override
  String platesTitle(String kg) {
    return 'Discos para $kg';
  }

  @override
  String platesBar(String kg) {
    return 'Barra: $kg';
  }

  @override
  String platesPerSide(String plates) {
    return 'Por lado: $plates';
  }

  @override
  String get platesOnlyBar => 'Solo la barra, sin discos.';

  @override
  String platesRemainder(String kg) {
    return 'Faltan $kg que no se pueden formar con discos estándar: usa el peso más cercano.';
  }

  @override
  String platesBelowBar(String kg) {
    return 'La carga es menor que la barra vacía ($kg).';
  }

  @override
  String get platesHelp =>
      'Discos estándar de 25 a 1,25 kg. Pon los mismos a cada lado.';

  @override
  String loadDecrease(String step) {
    return 'Bajar $step';
  }

  @override
  String loadIncrease(String step) {
    return 'Subir $step';
  }

  @override
  String get noteLabel => 'Tu nota';

  @override
  String get noteAdd => 'Añadir nota';

  @override
  String get noteEdit => 'Editar nota';

  @override
  String noteSheetTitle(String exercise) {
    return 'Nota para $exercise';
  }

  @override
  String get noteHint =>
      'Ajustes de máquina, agarre, altura del asiento… La verás cada vez que toque este ejercicio.';

  @override
  String get noteFieldLabel => 'Nota';

  @override
  String get notePrivacy =>
      'Solo la ves tú. Si tienes una molestia, mejor consulta a un profesional que apuntarla aquí.';

  @override
  String get noteSave => 'Guardar nota';

  @override
  String get noteDelete => 'Borrar nota';

  @override
  String get noteEmptyError => 'Escribe la nota o bórrala.';

  @override
  String get noteSaved => 'Nota guardada.';

  @override
  String get noteDeleted => 'Nota borrada.';

  @override
  String get swapPinLabel => 'Usar siempre este cambio';

  @override
  String get swapPinHelp =>
      'Se aplica a todas las sesiones de este plan con este ejercicio y se mantiene en las versiones nuevas mientras siga siendo válido.';

  @override
  String swapPinnedDone(String name) {
    return 'A partir de ahora harás $name en este plan';
  }

  @override
  String get pinnedBadge => 'Cambio fijado';

  @override
  String pinnedInsteadOf(String name) {
    return 'Cambio fijado: en lugar de $name';
  }

  @override
  String unpinAction(String name) {
    return 'Volver a $name';
  }

  @override
  String unpinDone(String name) {
    return 'Has vuelto a $name';
  }

  @override
  String get pinDroppedTitle => 'Un cambio fijado ya no se puede aplicar.';

  @override
  String get adjustOpen => '¿Poco tiempo hoy?';

  @override
  String get adjustTitle => 'Ajustar la sesión de hoy';

  @override
  String get adjustIntro =>
      'Elige el tiempo que tienes o una versión más ligera. Solo cambia hoy: tu plan sigue igual y no cuenta como bajada de rendimiento.';

  @override
  String get adjustMinutesLabel => 'Tiempo disponible';

  @override
  String adjustMinutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get adjustReducedLabel => 'Volumen reducido';

  @override
  String get adjustReducedHelp =>
      'Una serie menos por ejercicio y 1 repetición más en reserva, sin subir carga.';

  @override
  String get adjustPreview => 'Ver cómo queda';

  @override
  String get adjustPickSomething =>
      'Elige un tiempo o activa el volumen reducido.';

  @override
  String adjustEstimated(int minutes) {
    return 'Duración estimada: $minutes min';
  }

  @override
  String get adjustDroppedTitle => 'Hoy se quitan:';

  @override
  String get adjustNothingDropped => 'No se quita ningún ejercicio.';

  @override
  String get adjustDoesNotFit =>
      'Ni con lo esencial cabe en ese tiempo: haz lo que puedas, empezando por el principal.';

  @override
  String get adjustApply => 'Empezar con este ajuste';

  @override
  String adjustBannerMinutes(int minutes) {
    return 'Sesión ajustada a $minutes min';
  }

  @override
  String get adjustBannerReduced => 'Sesión con volumen reducido';

  @override
  String adjustBannerBoth(int minutes) {
    return 'Sesión ajustada a $minutes min y con volumen reducido';
  }

  @override
  String adjustBannerDropped(String names) {
    return 'Hoy sin: $names';
  }

  @override
  String get adjustRemove => 'Volver a la sesión completa';

  @override
  String get settingsSchedule => 'Días de entreno, pausas y recordatorio';

  @override
  String get settingsScheduleSubtitle =>
      'Qué días entrenas, vacaciones y aviso en el móvil';

  @override
  String get scheduleTitle => 'Días y pausas';

  @override
  String get scheduleDaysTitle => 'Días de entreno';

  @override
  String get scheduleDaysIntro =>
      'Sirven para el recordatorio y para saber si hoy toca. No cambian tu plan: sigue el orden de tus sesiones.';

  @override
  String scheduleDaysCount(int count, int max) {
    return '$count de $max días elegidos';
  }

  @override
  String get scheduleDaysDefault =>
      'Sin días elegidos: se usan los días del plan.';

  @override
  String scheduleDaysTooMany(int max) {
    return 'Tu plan tiene $max días por semana: elige $max como mucho.';
  }

  @override
  String get scheduleDaysSave => 'Guardar días';

  @override
  String get scheduleDaysSaved => 'Días de entreno guardados.';

  @override
  String get scheduleBreaksTitle => 'Pausas';

  @override
  String get scheduleBreaksIntro =>
      'Vacaciones o días sin entrenar (de 1 a 60 días). No cuentan en tu adherencia, no bajan la carga al volver y el recordatorio no suena.';

  @override
  String get scheduleBreaksEmpty => 'No tienes pausas planificadas.';

  @override
  String scheduleBreakRange(String start, String end) {
    return 'Del $start al $end';
  }

  @override
  String scheduleBreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get scheduleBreakAdd => 'Añadir pausa';

  @override
  String get scheduleBreakPickerHelp => 'Elige el primer y el último día';

  @override
  String get scheduleBreakTooLong => 'Una pausa dura como mucho 60 días.';

  @override
  String get scheduleBreakAdded => 'Pausa añadida.';

  @override
  String get scheduleBreakDelete => 'Borrar pausa';

  @override
  String get scheduleBreakDeleteTitle => '¿Borrar esta pausa?';

  @override
  String get scheduleBreakDeleteBody =>
      'Esos días volverán a contar en tu adherencia.';

  @override
  String get scheduleBreakDeleted => 'Pausa borrada.';

  @override
  String get scheduleReminderTitle => 'Recordatorio';

  @override
  String get scheduleReminderToggle => 'Recordarme los días de entreno';

  @override
  String get scheduleReminderHelp =>
      'Un aviso en este móvil, sin pasar por nuestro servidor. No suena en las pausas.';

  @override
  String scheduleReminderTime(String time) {
    return 'Hora: $time';
  }

  @override
  String get scheduleReminderTimeEdit => 'Cambiar la hora del recordatorio';

  @override
  String get scheduleReminderPermissionTitle => '¿Te avisamos?';

  @override
  String get scheduleReminderPermissionBody =>
      'Para avisarte los días de entreno, Android te pedirá permiso para mostrar notificaciones. Solo usamos este permiso para el recordatorio.';

  @override
  String get scheduleReminderPermissionContinue => 'Continuar';

  @override
  String get scheduleReminderPermissionLater => 'Ahora no';

  @override
  String get scheduleReminderDenied =>
      'Sin permiso no podemos avisarte. Puedes activarlo en los ajustes del sistema.';

  @override
  String get reminderNotificationTitle => 'Hoy toca entrenar';

  @override
  String get reminderNotificationBody =>
      'Tu sesión te espera en Pipos Fitness.';

  @override
  String todayBreakNotice(String date) {
    return 'Estás en pausa hasta el $date. Si te apetece, puedes entrenar igualmente.';
  }

  @override
  String get todayRestDayNotice =>
      'Hoy no es uno de tus días de entreno. Puedes descansar o entrenar igualmente.';

  @override
  String progressAdherenceBreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días en pausa: no cuentan',
      one: '1 día en pausa: no cuenta',
    );
    return '$_temp0';
  }

  @override
  String get progressTabTraining => 'Entreno';

  @override
  String get progressTabBody => 'Cuerpo';

  @override
  String get bodyConsentNeededTitle => 'Tus medidas son datos de salud';

  @override
  String get bodyConsentNeededBody =>
      'Para registrar peso y perímetros y ver su evolución necesitamos tu consentimiento. Puedes retirarlo cuando quieras y se borran.';

  @override
  String get bodyConsentUpgradeBody =>
      'Tu consentimiento cubre el peso. Para perímetros, IMC y % de grasa estimado acepta la versión nueva del texto.';

  @override
  String get bodyConsentReview => 'Leer y aceptar';

  @override
  String get bodyAddMeasurement => 'Añadir medidas';

  @override
  String get bodyEmpty =>
      'Aún no has registrado medidas. Pésate y mide siempre en condiciones parecidas (por ejemplo, por la mañana).';

  @override
  String get bodyWeightTitle => 'Peso';

  @override
  String bodyWeightLatest(String kg, String date) {
    return 'Último: $kg ($date)';
  }

  @override
  String bodyTrendStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'on_track': 'Vas a buen ritmo',
      'too_fast': 'Vas demasiado rápido',
      'too_slow': 'Vas más lento de lo previsto',
      'wrong_direction': 'Vas en sentido contrario a tu objetivo',
      'no_target': 'Tu objetivo no fija un ritmo',
      'insufficient_data': 'Faltan datos para ver el ritmo',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String bodyTrendRate(String rate) {
    return '$rate % por semana';
  }

  @override
  String bodyTrendTarget(String direction, String min, String max) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'loss': 'Objetivo: perder entre el $min y el $max % por semana',
      'gain': 'Objetivo: ganar entre el $min y el $max % por semana',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String bodyChartLabel(String first, String last, String period) {
    return 'Peso: de $first a $last kg en $period';
  }

  @override
  String get bodyChartTitle =>
      'Peso (kg): media móvil de 7 días en cada pesada';

  @override
  String get bodyEstimateLabel => 'Estimación — no es un diagnóstico';

  @override
  String get bodyBmiTitle => 'Índice de masa corporal (IMC)';

  @override
  String bmiCategoryLabel(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'underweight': 'Bajo peso',
      'normal': 'Peso normal',
      'pre_obese': 'Sobrepeso (preobesidad)',
      'obese_class_1': 'Obesidad de clase I',
      'obese_class_2': 'Obesidad de clase II',
      'obese_class_3': 'Obesidad de clase III',
      'other': '$category',
    });
    return '$_temp0';
  }

  @override
  String get bodyBmiWhoNote => 'Categorías de la OMS para adultos.';

  @override
  String get bodyFatTitle => '% de grasa estimado';

  @override
  String bodyFatValue(String value) {
    return '$value %';
  }

  @override
  String get bodyNotApplicable => 'No aplica';

  @override
  String bodyEstimateStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'insufficient_data': 'Faltan datos para calcularlo.',
      'consent_required':
          'Requiere aceptar la versión nueva del consentimiento de salud.',
      'invalid_input': 'Revisa las medidas: no se puede calcular.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get bodyBmiMissing => 'Necesita tu peso y tu altura (perfil).';

  @override
  String get bodyFatMissing =>
      'Necesita cintura, cuello y, en mujeres, cadera del mismo día, y tu altura.';

  @override
  String bodyMeasuredOn(String date) {
    return 'Medido el $date';
  }

  @override
  String get bodyCircumferencesTitle => 'Perímetros';

  @override
  String get bodyCircumferencesNote =>
      'Pecho, brazo y muslo son solo de seguimiento.';

  @override
  String bodyFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weightKg': 'Peso',
      'waistCm': 'Cintura',
      'neckCm': 'Cuello',
      'hipCm': 'Cadera',
      'chestCm': 'Pecho',
      'armCm': 'Brazo',
      'thighCm': 'Muslo',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String bodyFieldHelp(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weightKg': 'Por la mañana, tras ir al baño y antes de comer.',
      'waistCm':
          'Hombres: a la altura del ombligo. Mujeres: en la parte más estrecha de la cintura. Al final de una espiración normal.',
      'neckCm': 'Justo por debajo de la nuez (laringe).',
      'hipCm': 'En la parte más ancha de los glúteos.',
      'chestCm':
          'A la altura de los pezones, al final de una espiración normal.',
      'armCm': 'Brazo relajado, en el punto medio entre el hombro y el codo.',
      'thighCm': 'En el punto medio entre la ingle y la rótula.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String bodyCm(String value) {
    return '$value cm';
  }

  @override
  String bodyLatestValue(String value, String date) {
    return '$value ($date)';
  }

  @override
  String bodyChange(String weeks, String change) {
    String _temp0 = intl.Intl.selectLogic(weeks, {
      'w4': 'Δ 4 sem: $change',
      'w12': 'Δ 12 sem: $change',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get bodyNoValue => 'Sin datos';

  @override
  String get bodyHistoryTitle => 'Registros';

  @override
  String bodyHistoryDelete(String date) {
    return 'Borrar las medidas del $date';
  }

  @override
  String get bodyHistoryDeleted => 'Medidas borradas.';

  @override
  String get measureTitle => 'Añadir medidas';

  @override
  String get measureIntro =>
      'Todas son opcionales: rellena al menos una. Mide siempre igual y en condiciones parecidas.';

  @override
  String measureDate(String date) {
    return 'Fecha: $date';
  }

  @override
  String get measureDateEdit => 'Cambiar la fecha';

  @override
  String get measureAtLeastOne => 'Introduce al menos una medida.';

  @override
  String get measureNeedsConsent =>
      'Los perímetros requieren aceptar la versión nueva del consentimiento de salud.';

  @override
  String get measureSave => 'Guardar medidas';

  @override
  String get measureSaved => 'Medidas guardadas.';

  @override
  String get measureUnitKg => 'kg';

  @override
  String get measureUnitCm => 'cm';

  @override
  String chartPeriodWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String chartPeriodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String progressVolumeSets(num count, String sets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sets series',
      one: '$sets serie',
    );
    return '$_temp0';
  }

  @override
  String progressVolumeTarget(String min, String max) {
    return 'objetivo $min–$max';
  }

  @override
  String get progressVolumeLegendBelow => 'Por debajo del rango';

  @override
  String get progressVolumeLegendWithin => 'Dentro del rango';

  @override
  String get progressVolumeLegendAbove => 'Por encima del rango';

  @override
  String get progressVolumeLegendBand =>
      'La franja marca el rango objetivo de series efectivas.';

  @override
  String get settingsHealthGrantedNoDate => 'Consentimiento de salud dado';

  @override
  String settingsLegalConsentVersion(String version, String date) {
    return 'Tu consentimiento de salud: versión $version del texto, aceptada el $date.';
  }
}
