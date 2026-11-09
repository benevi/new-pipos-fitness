// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pipos Fitness';

  @override
  String get splashLoading => 'Loading your session…';

  @override
  String get navToday => 'Today';

  @override
  String get navPlan => 'Plan';

  @override
  String get navProgress => 'Progress';

  @override
  String get navSettings => 'Settings';

  @override
  String get offlineBanner => 'Offline: showing saved data';

  @override
  String pendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets waiting to sync',
      one: '1 set waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String failedSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets could not be sent',
      one: '1 set could not be sent',
    );
    return '$_temp0';
  }

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncStatusPending => 'Waiting to sync';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusFailed => 'Could not be sent';

  @override
  String get setRejectedInvalid =>
      'The server won\'t accept it: the exercise or the values aren\'t valid for this slot.';

  @override
  String get setRejectedFinished =>
      'The server won\'t accept it: the workout was already finished.';

  @override
  String get setRejectedNotStarted =>
      'Couldn\'t be sent: the workout never started on the server.';

  @override
  String setRejectedOther(String code) {
    return 'Couldn\'t be sent ($code).';
  }

  @override
  String get setDiscard => 'Discard';

  @override
  String setDiscardFor(int number) {
    return 'Discard set $number';
  }

  @override
  String setDiscardTitle(int number) {
    return 'Discard set $number?';
  }

  @override
  String get setDiscardBody =>
      'It will be removed from this phone and won\'t count in the workout. This can\'t be undone.';

  @override
  String setActionsFor(int number) {
    return 'Options for set $number';
  }

  @override
  String get setEdit => 'Edit';

  @override
  String setEditTitle(int number) {
    return 'Fix set $number';
  }

  @override
  String get setEditHint => 'Saved on this phone and sent when you\'re online.';

  @override
  String get setEditSave => 'Save changes';

  @override
  String get setDelete => 'Delete';

  @override
  String setDeleteTitle(int number) {
    return 'Delete set $number?';
  }

  @override
  String get setDeleteBody =>
      'It will no longer count in the workout or in your progress. This can\'t be undone.';

  @override
  String cachedDataNotice(String date) {
    return 'Offline. Data saved on $date.';
  }

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String validationPasswordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get validationPasswordsDontMatch => 'Passwords don\'t match';

  @override
  String get loginSubmit => 'Log in';

  @override
  String get loginGoToRegister => 'No account? Sign up';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerGoToLogin => 'Already have an account? Log in';

  @override
  String get authErrorInvalidCredentials => 'Wrong email or password.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'An account with this email already exists.';

  @override
  String get authErrorInvalidInput => 'Check the details you entered.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please log in again.';

  @override
  String get errorBadRequest => 'The request is not valid.';

  @override
  String get errorParse => 'The server sent an unexpected response.';

  @override
  String get errorUnknown => 'Something unexpected went wrong.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorPlanGeneration =>
      'We couldn\'t build a plan with these details. Check your equipment or days and try again.';

  @override
  String get errorConsentRequired =>
      'We need your health-data consent to save limitations or body data.';

  @override
  String get errorOfflineAction => 'You need a connection to do this.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSave => 'Save';

  @override
  String get actionShowMore => 'Why';

  @override
  String get actionShowLess => 'Hide explanation';

  @override
  String get configErrorTitle => 'Incomplete configuration';

  @override
  String get configErrorBody =>
      'This build doesn\'t define the API URL. Rebuild with --dart-define=API_BASE_URL=https://…';

  @override
  String get medicalNotice =>
      'Pipos Fitness does not give medical advice. If you have pain, an injury or a health condition, talk to a professional before training.';

  @override
  String get screeningNotice =>
      'If you feel pain when training, have a recent injury or a medical condition, see a healthcare professional before you start. This app does not diagnose or treat injuries.';

  @override
  String get onboardingTitle => 'Your plan in 3 minutes';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingGoalTitle => 'What do you want to achieve?';

  @override
  String get onboardingLevelTitle => 'How much lifting experience do you have?';

  @override
  String get onboardingScheduleTitle => 'How much time do you have?';

  @override
  String get onboardingDaysLabel => 'Days per week';

  @override
  String onboardingDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get onboardingMinutesLabel => 'Minutes per session';

  @override
  String onboardingMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get onboardingEquipmentTitle => 'What equipment do you have?';

  @override
  String get onboardingEquipmentHint =>
      'Tick everything you can use. The plan will only include exercises you can do.';

  @override
  String get onboardingEquipmentPresetGym => 'Full gym';

  @override
  String get onboardingEquipmentPresetHome => 'Home with dumbbells';

  @override
  String get onboardingEquipmentPresetBodyweight => 'Bodyweight only';

  @override
  String get onboardingConsentTitle => 'Health data (optional)';

  @override
  String get onboardingConsentIntro =>
      'To avoid exercises that could aggravate a niggle, and to work out your nutrition targets, we need to process health data. It\'s optional and you can withdraw it at any time.';

  @override
  String onboardingConsentVersion(String version) {
    return 'Text version: $version';
  }

  @override
  String get onboardingConsentAccept => 'I agree';

  @override
  String get onboardingConsentSkip => 'Continue without health data';

  @override
  String get onboardingConsentSkippedNote =>
      'Without this consent your plan won\'t take limitations or body data into account. You can give it later in Settings.';

  @override
  String get healthConsentText =>
      'I agree that Pipos Fitness may process my health data (weight, height, limitations or discomfort by body area and body measurements: waist, neck, hip, chest, arm and thigh circumferences) to adapt my training plan and my nutrition targets, and to show me how they change and derived estimates (body mass index and estimated body-fat percentage). I can withdraw this consent at any time from Settings; doing so deletes that data, including the measurement log, and regenerates the plan without it. The estimates are not a diagnosis and Pipos Fitness does not give medical advice.';

  @override
  String get onboardingLimitationsTitle => 'Any area with discomfort?';

  @override
  String get onboardingLimitationsHint =>
      'The plan will avoid risky movements for those areas and suggest alternatives.';

  @override
  String get onboardingNoLimitations => 'None';

  @override
  String get onboardingPreferencesTitle => 'Preferences (optional)';

  @override
  String onboardingPriorityLabel(int max) {
    return 'Priority muscles (up to $max)';
  }

  @override
  String get onboardingFavouritesLabel => 'Favourite exercises';

  @override
  String get onboardingBannedLabel => 'Exercises you don\'t want to do';

  @override
  String get onboardingAddExercise => 'Add exercise';

  @override
  String onboardingRemoveExercise(String name) {
    return 'Remove $name';
  }

  @override
  String get exercisePickerTitle => 'Find an exercise';

  @override
  String get exercisePickerHint => 'Exercise name';

  @override
  String get exercisePickerEmpty => 'No exercises match that name.';

  @override
  String get onboardingBodyTitle => 'About you (optional)';

  @override
  String get onboardingBodyHint =>
      'Only used to work out your nutrition targets. You can leave them blank.';

  @override
  String get onboardingBodyNeedsConsent =>
      'Weight and height are health data: they\'re only saved if you give your consent.';

  @override
  String get fieldBirthYear => 'Year of birth';

  @override
  String get fieldSex => 'Sex';

  @override
  String get fieldWeightKg => 'Weight (kg)';

  @override
  String get fieldHeightCm => 'Height (cm)';

  @override
  String get fieldActivityLevel => 'Daily activity outside the gym';

  @override
  String get fieldTimezone => 'Time zone';

  @override
  String get fieldNotSpecified => 'Prefer not to say';

  @override
  String onboardingTimezoneAuto(String timezone) {
    return 'Detected on your device: $timezone';
  }

  @override
  String get onboardingReviewTitle => 'Review and build your plan';

  @override
  String get onboardingGenerate => 'Build my plan';

  @override
  String get onboardingGenerating => 'Building your plan…';

  @override
  String get onboardingSaveChanges => 'Save changes';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingResultTitle => 'Your plan is ready';

  @override
  String get onboardingResultStart => 'See today\'s session';

  @override
  String get validationRequired => 'Choose an option';

  @override
  String get validationEquipmentRequired =>
      'Choose at least one item (or “Bodyweight”)';

  @override
  String validationRange(String min, String max) {
    return 'Must be between $min and $max';
  }

  @override
  String get validationNumber => 'Enter a number';

  @override
  String validationAdult(int age) {
    return 'The app is only for people aged $age or over';
  }

  @override
  String validationPriorityMax(int max) {
    return 'Choose $max at most';
  }

  @override
  String get validationBannedFavourite =>
      'An exercise can\'t be both a favourite and banned';

  @override
  String get validationServerField => 'Check this field';

  @override
  String get validationFixErrors => 'Check the highlighted fields.';

  @override
  String get todayTitle => 'Today';

  @override
  String get todayEmptyTitle => 'You don\'t have a plan yet';

  @override
  String get todayEmptyBody =>
      'Complete the questionnaire to get your plan and today\'s session.';

  @override
  String get todayEmptyAction => 'Start the questionnaire';

  @override
  String get todayOfflineNoData =>
      'Offline and nothing saved yet. Connect once to download your session.';

  @override
  String todaySessionMeta(int minutes, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$minutes min estimated · $_temp0';
  }

  @override
  String todayGeneralWarmup(int minutes) {
    return 'General warm-up: $minutes min of mobility or easy cardio';
  }

  @override
  String get todayWarmupSets => 'Warm-up sets';

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
    return 'Suggested load: $load';
  }

  @override
  String get todayInitialEstimate => 'Initial estimate';

  @override
  String todayInitialEstimateHelp(int rir) {
    return 'We don\'t know your load yet: pick a weight that leaves about $rir reps in reserve.';
  }

  @override
  String get todayDeload => 'Deload';

  @override
  String todaySubstitutedFrom(String name) {
    return 'Replaces $name';
  }

  @override
  String todayRest(int seconds) {
    return 'Rest $seconds s';
  }

  @override
  String get todayCues => 'Technique cues';

  @override
  String todaySetLabel(int index) {
    return 'Set $index';
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
  String get rirPickerTitle => 'Reps in reserve (RIR)';

  @override
  String get rirPickerHelp =>
      'How many more reps could you have done with good form?';

  @override
  String rirValue(int rir) {
    return 'RIR $rir';
  }

  @override
  String todayConfirmSet(int index) {
    return 'Confirm set $index';
  }

  @override
  String get todayExerciseDone => 'Exercise complete';

  @override
  String get todaySwap => 'Swap exercise';

  @override
  String get todayFinish => 'Finish workout';

  @override
  String get todayFinishConfirmTitle => 'Finish the workout?';

  @override
  String todayFinishConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets are still unlogged.',
      one: '1 set is still unlogged.',
      zero: 'You\'ve completed every set.',
    );
    return '$_temp0 Everything you logged is kept.';
  }

  @override
  String get todayFinishConfirm => 'Finish';

  @override
  String todayFinishUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets haven\'t been sent.',
      one: '1 set hasn\'t been sent.',
    );
    return '$_temp0 They\'ll be retried before closing the workout; until they\'re sent, closing stays on hold.';
  }

  @override
  String get todayFinishRetryNow => 'Retry sending';

  @override
  String todayStaleSession(String date) {
    return 'Session saved on $date. Offline we can\'t tell which session is due today; you can still log it and it will sync when you\'re back online.';
  }

  @override
  String get todayNoUserOffline =>
      'Couldn\'t log the set: connect to the internet once to verify your session.';

  @override
  String todayConflictBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return 'A workout saved on this phone ($_temp0) couldn\'t be started on the server: another workout is in progress on your account. Finish that workout and tap “Retry”, or discard the one on this phone.';
  }

  @override
  String get todayConflictDiscard => 'Discard';

  @override
  String get todayConflictDiscardTitle => 'Discard the workout on this phone?';

  @override
  String todayConflictDiscardBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets that never reached the server will be deleted.',
      one: '1 set that never reached the server will be deleted.',
    );
    return '$_temp0 This can\'t be undone.';
  }

  @override
  String get todayStartHint =>
      'The workout starts when you confirm the first set.';

  @override
  String get restTimerLabel => 'Rest';

  @override
  String restTimerRemaining(String time) {
    return 'Rest: $time left';
  }

  @override
  String get restTimerSkip => 'Skip rest';

  @override
  String get restTimerAdd => 'Add 15 seconds';

  @override
  String get restTimerDone => 'Rest finished';

  @override
  String swapTitle(String name) {
    return 'Alternatives to $name';
  }

  @override
  String get swapHint =>
      'Ranked by similarity: same pattern, muscles and your equipment.';

  @override
  String get swapEmpty => 'No alternatives fit your equipment and limitations.';

  @override
  String swapChoose(String name) {
    return 'Use $name';
  }

  @override
  String swapDone(String name) {
    return 'Exercise swapped for $name';
  }

  @override
  String get completeTitle => 'Workout complete!';

  @override
  String completeSummary(int count, String volume) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets logged',
      one: '1 set logged',
    );
    return '$_temp0 · $volume kg lifted';
  }

  @override
  String get completeSynced => 'Everything is synced.';

  @override
  String get completePending =>
      'It will sync when you\'re back online. Nothing will be lost.';

  @override
  String get completeBack => 'Back to Today';

  @override
  String get planTitle => 'Your plan';

  @override
  String planVersionLabel(int version) {
    return 'Version $version';
  }

  @override
  String get planWhySplit => 'Why this split';

  @override
  String get planWarnings => 'Warnings';

  @override
  String get planSessions => 'Sessions';

  @override
  String planSessionMeta(String day, int minutes) {
    return '$day · $minutes min';
  }

  @override
  String planExerciseLine(int sets, int repMin, int repMax, int rir, int rest) {
    return '$sets × $repMin–$repMax · RIR $rir · $rest s rest';
  }

  @override
  String get planHistory => 'Version history';

  @override
  String get planHistoryEmpty => 'You only have one version of the plan.';

  @override
  String planHistoryItem(int version, String date) {
    return 'Version $version · $date';
  }

  @override
  String get planCurrentBadge => 'Current';

  @override
  String get planWeeklyVolume => 'Weekly sets per group';

  @override
  String planVolumeRange(String sets, String min, String max) {
    return '$sets sets (target $min–$max)';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressE1rmTitle => 'Estimated strength (e1RM)';

  @override
  String get progressE1rmEmpty =>
      'Log your first weighted sets to see your e1RM.';

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
    return '$name: from $first to $last kg between $since and $until ($count sessions)';
  }

  @override
  String get progressVolumeTitle => 'Sets this week by group';

  @override
  String get progressVolumeEmpty =>
      'Once you train this week you\'ll see your sets against the target range here.';

  @override
  String progressVolumeBar(
    String group,
    String sets,
    String min,
    String max,
    String status,
  ) {
    return '$group: $sets sets, target $min to $max, $status';
  }

  @override
  String get progressAdherenceTitle => 'Adherence';

  @override
  String get progressAdherenceEmpty => 'No planned weeks yet.';

  @override
  String progressAdherenceValue(int done, int planned, int percent) {
    return '$done of $planned sessions ($percent%)';
  }

  @override
  String get progressEmptyTitle => 'Your progress will show up here';

  @override
  String get progressEmptyBody =>
      'Complete your first session to start seeing strength, volume and adherence.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEmailOffline =>
      'Offline: your email will show up once you\'re back online.';

  @override
  String get settingsProfile => 'Training profile';

  @override
  String get settingsProfileSubtitle =>
      'Goal, days, minutes, equipment and preferences';

  @override
  String get settingsHealth => 'Health data and limitations';

  @override
  String settingsHealthGranted(String date) {
    return 'Health consent given on $date';
  }

  @override
  String get settingsHealthNotGranted =>
      'No consent: the plan doesn\'t use limitations or body data';

  @override
  String get settingsHealthGrant => 'Give consent';

  @override
  String get settingsHealthWithdraw => 'Withdraw consent';

  @override
  String get settingsHealthWithdrawTitle => 'Withdraw consent?';

  @override
  String get settingsHealthWithdrawBody =>
      'Your limitations, weight and height will be deleted and a new version of the plan will be built without them.';

  @override
  String get settingsHealthWithdrawn =>
      'Consent withdrawn. Your health data has been deleted.';

  @override
  String get settingsNutrition => 'Nutrition targets';

  @override
  String settingsNutritionKcal(String kcal) {
    return '$kcal kcal a day';
  }

  @override
  String settingsNutritionMacros(String protein, String fat, String carbs) {
    return 'Protein $protein g · Fat $fat g · Carbs $carbs g';
  }

  @override
  String get settingsNutritionIncomplete =>
      'Complete these details to calculate them:';

  @override
  String get settingsNutritionComplete => 'Complete my details';

  @override
  String get settingsExport => 'Export my data';

  @override
  String get settingsExportSubtitle =>
      'Download a JSON file with everything we store about you';

  @override
  String get settingsExportDone => 'Export ready';

  @override
  String get settingsDelete => 'Delete account';

  @override
  String get settingsDeleteSubtitle =>
      'Permanently delete your account and all your data';

  @override
  String get settingsDeleteTitle => 'Delete your account?';

  @override
  String get settingsDeleteBody =>
      'Your profile, plans, workouts and health data will be deleted forever. This can\'t be undone. Enter your password to confirm.';

  @override
  String get settingsDeleteConfirm => 'Delete my account';

  @override
  String get settingsDeleteWrongPassword => 'That password isn\'t correct.';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutConfirmTitle => 'Sign out?';

  @override
  String get settingsLogoutConfirmBody =>
      'Your plan and saved sessions will be removed from this phone. Your data stays in your account.';

  @override
  String settingsLogoutUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets haven\'t been sent to the server.',
      one: '1 set hasn\'t been sent to the server.',
    );
    return '$_temp0 If you sign out now they\'ll be lost. Connect to the internet to send them first.';
  }

  @override
  String get settingsLegal => 'Legal and medical notice';

  @override
  String get settingsProfileSaved => 'Profile saved.';

  @override
  String get settingsNewPlanTitle => 'New plan version';

  @override
  String settingsNewPlanBody(int version) {
    return 'Your changes affect the plan, so we\'ve created version $version. Your history and progress are kept, and the previous version stays in the history.';
  }

  @override
  String get settingsNewPlanAction => 'See the plan';

  @override
  String fieldNames(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'goal': 'Goal',
      'level': 'Level',
      'daysPerWeek': 'Days per week',
      'minutesPerSession': 'Minutes per session',
      'equipment': 'Equipment',
      'priorityMuscles': 'Priority muscles',
      'timezone': 'Time zone',
      'activityLevel': 'Daily activity',
      'birthYear': 'Year of birth',
      'sex': 'Sex',
      'bannedExerciseSlugs': 'Banned exercises',
      'favouriteExerciseSlugs': 'Favourite exercises',
      'limitations': 'Limitations',
      'weightKg': 'Weight',
      'heightCm': 'Height',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String goalLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'strength': 'Get stronger',
      'hypertrophy': 'Build muscle',
      'general_health': 'General health',
      'fat_loss': 'Lose fat',
      'muscular_endurance': 'Muscular endurance',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String levelLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'beginner': 'Beginner (under 1 year)',
      'intermediate': 'Intermediate (1–3 years)',
      'advanced': 'Advanced (over 3 years)',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String equipmentLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'bodyweight': 'Bodyweight',
      'barbell': 'Barbell',
      'ez_bar': 'EZ bar',
      'trap_bar': 'Trap bar',
      'dumbbell': 'Dumbbells',
      'kettlebell': 'Kettlebell',
      'weight_plate': 'Weight plates',
      'bench': 'Bench',
      'squat_rack': 'Squat rack',
      'cable': 'Cables',
      'machine': 'Machines',
      'smith_machine': 'Smith machine',
      'pull_up_bar': 'Pull-up bar',
      'dip_station': 'Dip station',
      'gymnastic_rings': 'Rings',
      'suspension_trainer': 'Suspension trainer',
      'resistance_band': 'Resistance bands',
      'medicine_ball': 'Medicine ball',
      'plyo_box': 'Plyo box',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String zoneLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'shoulder': 'Shoulder',
      'elbow': 'Elbow',
      'wrist': 'Wrist',
      'lumbar': 'Lower back',
      'hip': 'Hip',
      'knee': 'Knee',
      'ankle': 'Ankle',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String muscleLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'chest': 'Chest',
      'front_delts': 'Front delts',
      'side_delts': 'Side delts',
      'rear_delts': 'Rear delts',
      'lats': 'Lats',
      'upper_back': 'Upper back',
      'traps': 'Traps',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'forearms': 'Forearms',
      'abs': 'Abs',
      'obliques': 'Obliques',
      'lower_back': 'Lower back',
      'glutes': 'Glutes',
      'quads': 'Quads',
      'hamstrings': 'Hamstrings',
      'adductors': 'Adductors',
      'abductors': 'Abductors',
      'calves': 'Calves',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String groupLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'chest': 'Chest',
      'back': 'Back',
      'shoulders': 'Shoulders',
      'biceps': 'Biceps',
      'triceps': 'Triceps',
      'quads': 'Quads',
      'hamstrings': 'Hamstrings',
      'glutes': 'Glutes',
      'calves': 'Calves',
      'core': 'Core',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String sexLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String activityLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'sedentary_light': 'Sedentary or light',
      'active': 'Active (on your feet, walk daily)',
      'vigorous': 'Very active (physical job)',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String splitLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'full_body': 'Full body',
      'upper_lower': 'Upper / lower',
      'hybrid_ul_ppl': 'Upper-lower + push-pull-legs',
      'push_pull_legs': 'Push / pull / legs',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String sessionKindLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'full_body': 'Full body',
      'upper': 'Upper',
      'lower': 'Lower',
      'push': 'Push',
      'pull': 'Pull',
      'legs': 'Legs',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String progressionLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'start': 'First session',
      'increase_load': 'Add load',
      'increase_reps': 'Add reps',
      'hold': 'Hold',
      'decrease_load': 'Reduce load',
      'deload': 'Deload week',
      'return_after_break': 'Coming back after a break',
      'progress_variant': 'Move to a harder variant',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String volumeStatusLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'below': 'below',
      'within': 'within range',
      'above': 'above',
      'other': 'no target',
    });
    return '$_temp0';
  }

  @override
  String nutritionGoalLabel(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'fat_loss': 'Fat loss',
      'maintenance': 'Maintenance',
      'muscle_gain': 'Muscle gain',
      'other': '$value',
    });
    return '$_temp0';
  }

  @override
  String weekdayLabel(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '0': 'Monday',
      '1': 'Tuesday',
      '2': 'Wednesday',
      '3': 'Thursday',
      '4': 'Friday',
      '5': 'Saturday',
      '6': 'Sunday',
      'other': '$day',
    });
    return '$_temp0';
  }

  @override
  String loadKgValue(String kg) {
    return '$kg kg';
  }

  @override
  String get loadBodyweight => 'Bodyweight';

  @override
  String loadPctValue(String pct) {
    return '$pct% of working load';
  }

  @override
  String get settingsHealthUpdateBody =>
      'There is a new version of the text that adds body measurements (circumferences) and BMI and body-fat estimates. Your current consent still covers weight, height and limitations.';

  @override
  String get settingsHealthUpdate => 'Read and accept the new version';

  @override
  String pendingChangesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String failedChangesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes couldn\'t be sent',
      one: '1 change couldn\'t be sent',
    );
    return '$_temp0';
  }

  @override
  String loadImplementLabel(String implement) {
    String _temp0 = intl.Intl.selectLogic(implement, {
      'barbell': 'Barbell',
      'trap_bar': 'Trap bar',
      'ez_bar': 'EZ bar',
      'smith_machine': 'Smith machine',
      'dumbbell': 'Dumbbells',
      'kettlebell': 'Kettlebell',
      'machine': 'Machine',
      'cable': 'Cable',
      'weight_plate': 'Plate',
      'other': '$implement',
    });
    return '$_temp0';
  }

  @override
  String todayLoadStep(String implement, String step) {
    return '$implement · in $step steps';
  }

  @override
  String get platesButton => 'Plates';

  @override
  String platesButtonFor(String kg) {
    return 'Show plates for $kg';
  }

  @override
  String platesTitle(String kg) {
    return 'Plates for $kg';
  }

  @override
  String platesBar(String kg) {
    return 'Bar: $kg';
  }

  @override
  String platesPerSide(String plates) {
    return 'Per side: $plates';
  }

  @override
  String get platesOnlyBar => 'Just the bar, no plates.';

  @override
  String platesRemainder(String kg) {
    return '$kg can\'t be made with standard plates: use the nearest weight.';
  }

  @override
  String platesBelowBar(String kg) {
    return 'The load is lighter than the empty bar ($kg).';
  }

  @override
  String get platesHelp =>
      'Standard plates from 25 to 1.25 kg. Load the same on each side.';

  @override
  String loadDecrease(String step) {
    return 'Decrease by $step';
  }

  @override
  String loadIncrease(String step) {
    return 'Increase by $step';
  }

  @override
  String get noteLabel => 'Your note';

  @override
  String get noteAdd => 'Add note';

  @override
  String get noteEdit => 'Edit note';

  @override
  String noteSheetTitle(String exercise) {
    return 'Note for $exercise';
  }

  @override
  String get noteHint =>
      'Machine settings, grip, seat height… You\'ll see it every time this exercise comes up.';

  @override
  String get noteFieldLabel => 'Note';

  @override
  String get notePrivacy =>
      'Only you can see it. If something hurts, talk to a professional rather than noting it here.';

  @override
  String get noteSave => 'Save note';

  @override
  String get noteDelete => 'Delete note';

  @override
  String get noteEmptyError => 'Write the note or delete it.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get noteDeleted => 'Note deleted.';

  @override
  String get swapPinLabel => 'Always use this swap';

  @override
  String get swapPinHelp =>
      'Applies to every session in this plan with this exercise and carries over to new versions while it\'s still valid.';

  @override
  String swapPinnedDone(String name) {
    return 'From now on you\'ll do $name in this plan';
  }

  @override
  String get pinnedBadge => 'Pinned swap';

  @override
  String pinnedInsteadOf(String name) {
    return 'Pinned swap: instead of $name';
  }

  @override
  String unpinAction(String name) {
    return 'Go back to $name';
  }

  @override
  String unpinDone(String name) {
    return 'Back to $name';
  }

  @override
  String get pinDroppedTitle => 'A pinned swap can no longer be applied.';

  @override
  String get adjustOpen => 'Short on time today?';

  @override
  String get adjustTitle => 'Adjust today\'s session';

  @override
  String get adjustIntro =>
      'Pick the time you have or a lighter version. It only changes today: your plan stays the same and it doesn\'t count as a drop in performance.';

  @override
  String get adjustMinutesLabel => 'Time available';

  @override
  String adjustMinutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String get adjustReducedLabel => 'Reduced volume';

  @override
  String get adjustReducedHelp =>
      'One set fewer per exercise and 1 more rep in reserve, without increasing load.';

  @override
  String get adjustPreview => 'See how it looks';

  @override
  String get adjustPickSomething => 'Pick a time or turn on reduced volume.';

  @override
  String adjustEstimated(int minutes) {
    return 'Estimated duration: $minutes min';
  }

  @override
  String get adjustDroppedTitle => 'Dropped today:';

  @override
  String get adjustNothingDropped => 'No exercise is dropped.';

  @override
  String get adjustDoesNotFit =>
      'Even the essentials don\'t fit in that time: do what you can, starting with the main lift.';

  @override
  String get adjustApply => 'Start with this adjustment';

  @override
  String adjustBannerMinutes(int minutes) {
    return 'Session adjusted to $minutes min';
  }

  @override
  String get adjustBannerReduced => 'Reduced-volume session';

  @override
  String adjustBannerBoth(int minutes) {
    return 'Session adjusted to $minutes min with reduced volume';
  }

  @override
  String adjustBannerDropped(String names) {
    return 'Skipped today: $names';
  }

  @override
  String get adjustRemove => 'Back to the full session';

  @override
  String get settingsSchedule => 'Training days, breaks and reminder';

  @override
  String get settingsScheduleSubtitle =>
      'Which days you train, holidays and a reminder on this phone';

  @override
  String get scheduleTitle => 'Days and breaks';

  @override
  String get scheduleDaysTitle => 'Training days';

  @override
  String get scheduleDaysIntro =>
      'They\'re used for the reminder and to know whether today is a training day. They don\'t change your plan: it follows your session order.';

  @override
  String scheduleDaysCount(int count, int max) {
    return '$count of $max days chosen';
  }

  @override
  String get scheduleDaysDefault =>
      'No days chosen: the plan\'s days are used.';

  @override
  String scheduleDaysTooMany(int max) {
    return 'Your plan has $max days a week: choose $max at most.';
  }

  @override
  String get scheduleDaysSave => 'Save days';

  @override
  String get scheduleDaysSaved => 'Training days saved.';

  @override
  String get scheduleBreaksTitle => 'Breaks';

  @override
  String get scheduleBreaksIntro =>
      'Holidays or days off (1 to 60 days). They don\'t count against your adherence, don\'t lower the load when you\'re back and the reminder stays quiet.';

  @override
  String get scheduleBreaksEmpty => 'You have no planned breaks.';

  @override
  String scheduleBreakRange(String start, String end) {
    return 'From $start to $end';
  }

  @override
  String scheduleBreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get scheduleBreakAdd => 'Add break';

  @override
  String get scheduleBreakPickerHelp => 'Pick the first and last day';

  @override
  String get scheduleBreakTooLong => 'A break lasts 60 days at most.';

  @override
  String get scheduleBreakAdded => 'Break added.';

  @override
  String get scheduleBreakDelete => 'Delete break';

  @override
  String get scheduleBreakDeleteTitle => 'Delete this break?';

  @override
  String get scheduleBreakDeleteBody =>
      'Those days will count towards your adherence again.';

  @override
  String get scheduleBreakDeleted => 'Break deleted.';

  @override
  String get scheduleReminderTitle => 'Reminder';

  @override
  String get scheduleReminderToggle => 'Remind me on training days';

  @override
  String get scheduleReminderHelp =>
      'A notification on this phone, without going through our server. It stays quiet during breaks.';

  @override
  String scheduleReminderTime(String time) {
    return 'Time: $time';
  }

  @override
  String get scheduleReminderTimeEdit => 'Change the reminder time';

  @override
  String get scheduleReminderPermissionTitle => 'Shall we remind you?';

  @override
  String get scheduleReminderPermissionBody =>
      'To remind you on training days, your phone will ask for permission to show notifications. We only use it for the reminder.';

  @override
  String get scheduleReminderPermissionContinue => 'Continue';

  @override
  String get scheduleReminderPermissionLater => 'Not now';

  @override
  String get scheduleReminderDenied =>
      'Without permission we can\'t remind you. You can turn it on in your system settings.';

  @override
  String get reminderNotificationTitle => 'Training day today';

  @override
  String get reminderNotificationBody =>
      'Your session is waiting in Pipos Fitness.';

  @override
  String todayBreakNotice(String date) {
    return 'You\'re on a break until $date. You can still train if you feel like it.';
  }

  @override
  String get todayRestDayNotice =>
      'Today isn\'t one of your training days. You can rest or train anyway.';

  @override
  String progressAdherenceBreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days on a break: not counted',
      one: '1 day on a break: not counted',
    );
    return '$_temp0';
  }

  @override
  String get progressTabTraining => 'Training';

  @override
  String get progressTabBody => 'Body';

  @override
  String get bodyConsentNeededTitle => 'Your measurements are health data';

  @override
  String get bodyConsentNeededBody =>
      'To log your weight and circumferences and see how they change we need your consent. You can withdraw it at any time and they\'re deleted.';

  @override
  String get bodyConsentUpgradeBody =>
      'Your consent covers weight. For circumferences, BMI and estimated body fat, accept the new version of the text.';

  @override
  String get bodyConsentReview => 'Read and accept';

  @override
  String get bodyAddMeasurement => 'Add measurements';

  @override
  String get bodyEmpty =>
      'You haven\'t logged any measurements yet. Weigh and measure yourself in similar conditions each time (for example, in the morning).';

  @override
  String get bodyWeightTitle => 'Weight';

  @override
  String bodyWeightLatest(String kg, String date) {
    return 'Latest: $kg ($date)';
  }

  @override
  String bodyTrendStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'on_track': 'You\'re on track',
      'too_fast': 'You\'re going too fast',
      'too_slow': 'Slower than expected',
      'wrong_direction': 'Moving away from your goal',
      'no_target': 'Your goal doesn\'t set a pace',
      'insufficient_data': 'Not enough data for a trend',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String bodyTrendRate(String rate) {
    return '$rate% per week';
  }

  @override
  String bodyTrendTarget(String direction, String min, String max) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'loss': 'Target: lose $min–$max% per week',
      'gain': 'Target: gain $min–$max% per week',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String bodyChartLabel(String first, String last, String period) {
    return 'Weight: from $first to $last kg over $period';
  }

  @override
  String get bodyChartTitle =>
      'Weight (kg): 7-day moving average at each weigh-in';

  @override
  String get bodyEstimateLabel => 'Estimate — not a diagnosis';

  @override
  String get bodyBmiTitle => 'Body mass index (BMI)';

  @override
  String bmiCategoryLabel(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'underweight': 'Underweight',
      'normal': 'Normal weight',
      'pre_obese': 'Overweight (pre-obesity)',
      'obese_class_1': 'Obesity class I',
      'obese_class_2': 'Obesity class II',
      'obese_class_3': 'Obesity class III',
      'other': '$category',
    });
    return '$_temp0';
  }

  @override
  String get bodyBmiWhoNote => 'WHO categories for adults.';

  @override
  String get bodyFatTitle => 'Estimated body fat';

  @override
  String bodyFatValue(String value) {
    return '$value%';
  }

  @override
  String get bodyNotApplicable => 'Not applicable';

  @override
  String bodyEstimateStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'insufficient_data': 'Not enough data to calculate it.',
      'consent_required':
          'Requires accepting the new version of the health consent.',
      'invalid_input': 'Check your measurements: it can\'t be calculated.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get bodyBmiMissing => 'Needs your weight and your height (profile).';

  @override
  String get bodyFatMissing =>
      'Needs waist, neck and, for women, hip from the same day, plus your height.';

  @override
  String bodyMeasuredOn(String date) {
    return 'Measured on $date';
  }

  @override
  String get bodyCircumferencesTitle => 'Circumferences';

  @override
  String get bodyCircumferencesNote =>
      'Chest, arm and thigh are for tracking only.';

  @override
  String bodyFieldLabel(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weightKg': 'Weight',
      'waistCm': 'Waist',
      'neckCm': 'Neck',
      'hipCm': 'Hip',
      'chestCm': 'Chest',
      'armCm': 'Arm',
      'thighCm': 'Thigh',
      'other': '$field',
    });
    return '$_temp0';
  }

  @override
  String bodyFieldHelp(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'weightKg': 'In the morning, after using the toilet and before eating.',
      'waistCm':
          'Men: at navel height. Women: at the narrowest part of the waist. At the end of a normal breath out.',
      'neckCm': 'Just below the Adam\'s apple (larynx).',
      'hipCm': 'At the widest part of the buttocks.',
      'chestCm': 'At nipple height, at the end of a normal breath out.',
      'armCm': 'Relaxed arm, halfway between shoulder and elbow.',
      'thighCm': 'Halfway between groin and kneecap.',
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
      'w4': 'Δ 4 wk: $change',
      'w12': 'Δ 12 wk: $change',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get bodyNoValue => 'No data';

  @override
  String get bodyHistoryTitle => 'Entries';

  @override
  String bodyHistoryDelete(String date) {
    return 'Delete the measurements of $date';
  }

  @override
  String get bodyHistoryDeleted => 'Measurements deleted.';

  @override
  String get measureTitle => 'Add measurements';

  @override
  String get measureIntro =>
      'All are optional: fill in at least one. Always measure the same way and in similar conditions.';

  @override
  String measureDate(String date) {
    return 'Date: $date';
  }

  @override
  String get measureDateEdit => 'Change the date';

  @override
  String get measureAtLeastOne => 'Enter at least one measurement.';

  @override
  String get measureNeedsConsent =>
      'Circumferences require accepting the new version of the health consent.';

  @override
  String get measureSave => 'Save measurements';

  @override
  String get measureSaved => 'Measurements saved.';

  @override
  String get measureUnitKg => 'kg';

  @override
  String get measureUnitCm => 'cm';

  @override
  String chartPeriodWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String chartPeriodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String progressVolumeSets(num count, String sets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sets sets',
      one: '$sets set',
    );
    return '$_temp0';
  }

  @override
  String progressVolumeTarget(String min, String max) {
    return 'target $min–$max';
  }

  @override
  String get progressVolumeLegendBelow => 'Below range';

  @override
  String get progressVolumeLegendWithin => 'Within range';

  @override
  String get progressVolumeLegendAbove => 'Above range';

  @override
  String get progressVolumeLegendBand =>
      'The band marks the target range of effective sets.';

  @override
  String get settingsHealthGrantedNoDate => 'Health consent given';

  @override
  String settingsLegalConsentVersion(String version, String date) {
    return 'Your health consent: text version $version, accepted on $date.';
  }
}
