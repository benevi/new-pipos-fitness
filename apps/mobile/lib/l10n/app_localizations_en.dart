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
      'I agree that Pipos Fitness may process my health data (weight, height and limitations or discomfort by body area) for the sole purpose of adapting my training plan and my nutrition targets. I can withdraw this consent at any time from Settings; doing so deletes that data and regenerates the plan without it. Pipos Fitness does not give medical advice.';

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
  String progressE1rmTrend(String name, String first, String last, int count) {
    return '$name trend: from $first to $last kg over $count sessions';
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
  String get settingsProfile => 'Training profile';

  @override
  String get settingsProfileSubtitle =>
      'Goal, days, minutes, equipment and preferences';

  @override
  String get settingsHealth => 'Health data and limitations';

  @override
  String settingsHealthGranted(String version) {
    return 'Consent given ($version)';
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
  String settingsNutritionKcal(int kcal) {
    return '$kcal kcal a day';
  }

  @override
  String settingsNutritionMacros(int protein, int fat, int carbs) {
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
}
