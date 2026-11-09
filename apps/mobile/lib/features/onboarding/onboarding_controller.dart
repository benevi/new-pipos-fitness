/// Estado y envío del cuestionario (alta) y de la edición del perfil
/// (Ajustes, CUJ-6). Orden del envío:
/// 1. Consentimiento de salud (`POST /me/consents/health`) si lo aceptó.
/// 2. `PUT /me/profile`.
/// 3. Alta: `POST /plans/generate`. Edición: la API devuelve la nueva
///    versión del plan si el cambio le afecta.
/// Un 422 con `issues` se mapea a errores por campo y se vuelve al primer
/// paso con error.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/api_failure.dart';
import '../../core/offline/offline_providers.dart';
import '../../data/pipos_api.dart';
import '../../models/enums.dart';
import '../../models/plan.dart';
import '../../models/profile.dart';
import 'profile_draft.dart';

enum ProfileFormMode { onboarding, edit }

/// Zona horaria IANA del dispositivo (sustituible en tests).
final deviceTimezoneProvider = FutureProvider<String>((ref) async {
  try {
    final tz = (await FlutterTimezone.getLocalTimezone()).identifier;
    return tz.isEmpty ? 'UTC' : tz;
  } catch (_) {
    return 'UTC';
  }
});

class OnboardingState {
  const OnboardingState({
    required this.draft,
    required this.step,
    this.errors = const {},
    this.submitting = false,
    this.failure,
    this.plan,
    this.newPlanVersion,
    this.saved = false,
    this.revision = 0,
  });

  final ProfileDraft draft;
  final OnboardingStep step;
  final Map<OnboardingField, FieldMessage> errors;
  final bool submitting;
  final ApiFailure? failure;

  /// Alta: plan generado (se muestra con su explicación).
  final PlanVersion? plan;

  /// Edición: nueva versión creada por el cambio (null si no afectó).
  final PlanVersionSummary? newPlanVersion;
  final bool saved;

  /// Cambia con cada edición del borrador (fuerza el repintado).
  final int revision;

  OnboardingState copyWith({
    OnboardingStep? step,
    Map<OnboardingField, FieldMessage>? errors,
    bool? submitting,
    ApiFailure? failure,
    bool clearFailure = false,
    PlanVersion? plan,
    PlanVersionSummary? newPlanVersion,
    bool? saved,
    bool bump = false,
  }) => OnboardingState(
    draft: draft,
    step: step ?? this.step,
    errors: errors ?? this.errors,
    submitting: submitting ?? this.submitting,
    failure: clearFailure ? null : (failure ?? this.failure),
    plan: plan ?? this.plan,
    newPlanVersion: newPlanVersion ?? this.newPlanVersion,
    saved: saved ?? this.saved,
    revision: bump ? revision + 1 : revision,
  );
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(
    this._ref, {
    required this.mode,
    ProfileResponse? profile,
  }) : _consentAlreadyValid = profile?.healthConsent.isValid ?? false,
       super(
         OnboardingState(
           draft: profile == null
               ? ProfileDraft()
               : ProfileDraft.fromProfile(profile),
           step: OnboardingStep.goal,
         ),
       );

  final Ref _ref;
  final ProfileFormMode mode;
  final bool _consentAlreadyValid;

  int get _year => _ref.read(clockProvider)().year;

  /// Pasos visibles con el borrador actual.
  List<OnboardingStep> get steps => [
    for (final s in OnboardingStep.values)
      if (_isVisible(s)) s,
  ];

  bool _isVisible(OnboardingStep s) {
    final d = state.draft;
    return switch (s) {
      OnboardingStep.consent =>
        mode == ProfileFormMode.onboarding && !_consentAlreadyValid,
      OnboardingStep.limitations => d.hasConsent,
      OnboardingStep.review => mode == ProfileFormMode.onboarding,
      _ => true,
    };
  }

  /// Aplica un cambio al borrador y limpia el error de ese campo.
  void edit(void Function(ProfileDraft d) change, {OnboardingField? field}) {
    change(state.draft);
    final errors = {...state.errors};
    if (field != null) errors.remove(field);
    state = state.copyWith(errors: errors, bump: true, clearFailure: true);
  }

  /// Prepara un cambio de favoritos o vetados que llega desde la ficha: el
  /// ejercicio pasa a la lista elegida (y sale de la otra) y el formulario se
  /// abre en el paso de preferencias. No guarda nada hasta que el usuario lo
  /// confirma.
  void applyPick(ProfilePick pick) {
    final slug = pick.exercise.slug;
    edit(
      (d) {
        d.favourites.removeWhere((x) => x.slug == slug);
        d.banned.removeWhere((x) => x.slug == slug);
        (pick.favourite ? d.favourites : d.banned).add(pick.exercise);
      },
      field: pick.favourite
          ? OnboardingField.favouriteExerciseSlugs
          : OnboardingField.bannedExerciseSlugs,
    );
    if (steps.contains(OnboardingStep.preferences)) {
      state = state.copyWith(step: OnboardingStep.preferences, bump: true);
    }
  }

  void setConsent(bool accepted) {
    state.draft.consent = accepted;
    if (!accepted) {
      state.draft.limitations.clear();
      state.draft.weightKg = '';
      state.draft.heightCm = '';
    }
    state = state.copyWith(bump: true);
    next();
  }

  /// Valida el paso actual; si está bien, avanza. Devuelve si avanzó.
  bool next() {
    final errors = state.draft.validateStep(state.step, currentYear: _year);
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors, bump: true);
      return false;
    }
    final list = steps;
    final i = list.indexOf(state.step);
    if (i < list.length - 1) {
      state = state.copyWith(step: list[i + 1], errors: const {}, bump: true);
    }
    return true;
  }

  void back() {
    final list = steps;
    final i = list.indexOf(state.step);
    if (i > 0) {
      state = state.copyWith(step: list[i - 1], errors: const {}, bump: true);
    }
  }

  bool get isLastStep => steps.last == state.step;

  Future<void> submit({required Locale locale}) async {
    final errors = state.draft.validateAll(currentYear: _year);
    if (errors.isNotEmpty) {
      _showErrors(errors);
      return;
    }
    state = state.copyWith(submitting: true, clearFailure: true);
    try {
      final tz =
          state.draft.timezone ??
          await _ref.read(deviceTimezoneProvider.future);
      final profileApi = _ref.read(profileApiProvider);
      if (state.draft.hasConsent && !_consentAlreadyValid) {
        await profileApi.grantHealthConsent(
          version: healthConsentPolicyVersion,
          locale: locale.languageCode == 'en' ? AppLocale.en : AppLocale.es,
        );
      }
      final update = await profileApi.putProfile(
        state.draft.toRequest(fallbackTimezone: tz ?? 'UTC'),
      );
      final planApi = _ref.read(planApiProvider);
      if (mode == ProfileFormMode.onboarding) {
        final plan = update.planVersion != null
            ? (await planApi.getCurrentPlan())!
            : await _generatePlan(planApi);
        await _ref
            .read(cacheStoreProvider)
            .write(CacheKeys.currentPlan, plan.toJson());
        if (!mounted) return;
        state = state.copyWith(submitting: false, plan: plan, saved: true);
      } else {
        if (update.planVersion != null) {
          final plan = await planApi.getCurrentPlan();
          if (plan != null) {
            await _ref
                .read(cacheStoreProvider)
                .write(CacheKeys.currentPlan, plan.toJson());
          }
          await _ref.read(cacheStoreProvider).remove(CacheKeys.today);
        }
        if (!mounted) return;
        state = state.copyWith(
          submitting: false,
          saved: true,
          newPlanVersion: update.planVersion,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final f = ApiFailure.from(e);
      final fieldErrors = <OnboardingField, FieldMessage>{};
      for (final issue in f.issues) {
        final field = OnboardingField.fromApiPath(issue.path);
        if (field != null) fieldErrors[field] = (l) => l.validationServerField;
      }
      state = state.copyWith(submitting: false, failure: f);
      if (fieldErrors.isNotEmpty) _showErrors(fieldErrors);
    }
  }

  /// Clave de idempotencia del «Generar mi plan» en curso: se crea en la
  /// pulsación y se reutiliza en cada reintento hasta que sale bien (así un
  /// reintento tras una respuesta perdida no crea una segunda versión).
  String? _generateKey;

  static String _newKey() => const Uuid().v4();

  Future<PlanVersion> _generatePlan(PlanApi api) async {
    final key = _generateKey ??= _newKey();
    try {
      final plan = await api.generatePlan(idempotencyKey: key);
      _generateKey = null;
      return plan;
    } on ApiFailure catch (f) {
      if (f.code != ApiErrorCode.idempotencyKeyReused) rethrow;
      // La clave ya se usó con otro perfil (cambió entre intentos): una
      // nueva y un reintento.
      _generateKey = _newKey();
      final plan = await api.generatePlan(idempotencyKey: _generateKey);
      _generateKey = null;
      return plan;
    }
  }

  void _showErrors(Map<OnboardingField, FieldMessage> errors) {
    final visible = steps;
    final first = visible.firstWhere(
      (s) => errors.keys.any((f) => f.step == s),
      orElse: () => state.step,
    );
    state = state.copyWith(step: first, errors: errors, bump: true);
  }
}

/// Alta (sin perfil previo, o prellenado si ya había perfil sin plan).
final onboardingControllerProvider = StateNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingState, ProfileResponse?>(
      (ref, profile) => OnboardingController(
        ref,
        mode: ProfileFormMode.onboarding,
        profile: profile,
      ),
    );

/// Edición desde Ajustes.
final profileEditControllerProvider = StateNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingState, ProfileResponse>(
      (ref, profile) => OnboardingController(
        ref,
        mode: ProfileFormMode.edit,
        profile: profile,
      ),
    );

/// Perfil actual (null si aún no existe).
final profileProvider = FutureProvider.autoDispose<ProfileResponse?>(
  (ref) => ref.watch(profileApiProvider).getProfile(),
);
