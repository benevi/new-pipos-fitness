import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/api/api_failure.dart';
import 'package:pipos_fitness/features/onboarding/onboarding_screen.dart';
import 'package:pipos_fitness/features/today/today_screen.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/profile.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/ui.dart';

/// Backend sin perfil ni plan: el usuario entra al cuestionario.
FakeBackend newUser() => FakeBackend(hasPlan: false, hasProfile: false);

/// La API rechaza los días con 422 por campo.
class _Rejects422 extends FakeBackend {
  _Rejects422() : super(hasPlan: false, hasProfile: false);

  @override
  Future<ProfileUpdateResponse> putProfile(ProfileUpsertRequest request) async {
    calls.add('PUT /me/profile');
    throw const ApiFailure(
      type: ApiFailureType.badRequest,
      message: 'Validation failed',
      statusCode: 422,
      code: ApiErrorCode.validationFailed,
      issues: [FieldIssue(path: 'daysPerWeek', message: 'too big')],
    );
  }
}

Future<AppHarness> openOnboarding(
  WidgetTester tester,
  FakeBackend backend,
) async {
  usePhoneSize(tester);
  final harness = AppHarness.signedIn(backend: backend);
  await harness.pump(tester);
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingScreen), findsOneWidget);
  return harness;
}

Future<void> fillUntilConsent(WidgetTester tester) async {
  await tapKey(tester, 'goal-hypertrophy');
  await tapKey(tester, 'level-beginner');
  await tapKey(tester, 'onboarding-next');
  await tapKey(tester, 'days-3');
  await tapKey(tester, 'minutes-45');
  await tapKey(tester, 'onboarding-next');
  await tapKey(tester, 'preset-bodyweight');
  await tapKey(tester, 'onboarding-next');
}

void main() {
  testWidgets(
    'validación inline: no avanza sin responder y explica cada campo',
    (tester) async {
      final harness = await openOnboarding(tester, newUser());

      await tapKey(tester, 'onboarding-next');
      expect(find.text('Elige una opción'), findsNWidgets(2));
      expect(find.text('Paso 1 de 7'), findsOneWidget);

      await tapKey(tester, 'goal-strength');
      expect(
        find.text('Elige una opción'),
        findsOneWidget,
        reason: 'se limpia el error del campo corregido',
      );
      await tapKey(tester, 'level-intermediate');
      await tapKey(tester, 'onboarding-next');

      // Días y minutos son obligatorios (nunca valores por defecto).
      await tapKey(tester, 'onboarding-next');
      expect(find.text('Elige una opción'), findsNWidgets(2));
      await tapKey(tester, 'days-4');
      await tapKey(tester, 'minutes-60');
      await tapKey(tester, 'onboarding-next');

      // Material: al menos uno.
      await tapKey(tester, 'onboarding-next');
      expect(
        find.text('Elige al menos un material (o «Peso corporal»)'),
        findsOneWidget,
      );
      await tapKey(tester, 'equipment-dumbbell');
      expect(
        find.text('Elige al menos un material (o «Peso corporal»)'),
        findsNothing,
      );
      await tapKey(tester, 'onboarding-next');
      expect(find.byKey(const Key('consent-skip')), findsOneWidget);
      expect(harness.backend.profileRequests, isEmpty);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets(
    'saltar el consentimiento: sin limitaciones ni datos corporales, plan con explicación',
    (tester) async {
      final backend = newUser();
      final harness = await openOnboarding(tester, backend);
      await fillUntilConsent(tester);

      expect(
        find.textContaining('Versión del texto: health-2026-11'),
        findsOneWidget,
      );
      await tapKey(tester, 'consent-skip');

      // Se salta el paso de limitaciones: va directo a preferencias.
      expect(find.text('Preferencias (opcional)'), findsOneWidget);
      await tapKey(tester, 'onboarding-next');
      // Datos corporales: peso y altura no se ofrecen sin consentimiento.
      expect(find.byKey(const Key('field-weightKg')), findsNothing);
      expect(
        find.text(
          'El peso y la altura son datos de salud: solo se guardan si das tu consentimiento.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Europe/Madrid'), findsOneWidget);
      await tapKey(tester, 'onboarding-next');

      // Revisión: explica qué implica no darlo.
      expect(
        find.textContaining(
          'Sin este consentimiento tu plan no tendrá en cuenta',
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'onboarding-next');

      expect(backend.consentGrants, isEmpty);
      final req = backend.profileRequests.single;
      expect(req.limitations, isEmpty);
      expect(req.weightKg, isNull);
      expect(req.heightCm, isNull);
      expect(req.goal, TrainingGoal.hypertrophy);
      expect(req.daysPerWeek, 3);
      expect(req.equipment, [Equipment.bodyweight]);
      expect(req.timezone, 'Europe/Madrid');
      expect(backend.calls, contains('POST /plans/generate'));

      // Plan con su porqué.
      expect(find.text('Tu plan está listo'), findsOneWidget);
      expect(
        find.textContaining('cuerpo completo permite trabajar cada grupo'),
        findsOneWidget,
      );

      await tapKey(tester, 'onboarding-start');
      expect(find.byType(TodayScreen), findsOneWidget);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets(
    'aceptar el consentimiento: se concede antes de guardar y aparecen las limitaciones',
    (tester) async {
      final backend = newUser();
      final harness = await openOnboarding(tester, backend);
      await fillUntilConsent(tester);
      await tapKey(tester, 'consent-accept');

      expect(find.text('¿Alguna zona con molestias?'), findsOneWidget);
      expect(find.textContaining('consulta a un profesional'), findsWidgets);
      await tapKey(tester, 'zone-shoulder');
      await tapKey(tester, 'onboarding-next'); // preferencias
      await tapKey(tester, 'onboarding-next'); // datos corporales
      await tester.enterText(find.byKey(const Key('field-weightKg')), '20');
      await tapKey(tester, 'onboarding-next');
      expect(find.text('Debe estar entre 25 y 400'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('field-weightKg')), '62,5');
      await tapKey(tester, 'onboarding-next');
      await tapKey(tester, 'onboarding-next'); // generar

      expect(backend.consentGrants.single.version, healthConsentPolicyVersion);
      final req = backend.profileRequests.single;
      expect(req.limitations, [BodyZone.shoulder]);
      expect(req.weightKg, 62.5);
      await harness.drainAndUnmount(tester);
    },
  );

  testWidgets('un 422 de la API se muestra en el campo y vuelve a su paso', (
    tester,
  ) async {
    final backend = _Rejects422();
    final harness = await openOnboarding(tester, backend);
    await fillUntilConsent(tester);
    await tapKey(tester, 'consent-skip');
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'onboarding-next');

    expect(find.text('¿Cuánto tiempo tienes?'), findsOneWidget);
    expect(find.text('Revisa este campo'), findsOneWidget);
    expect(find.text('Revisa los campos marcados.'), findsOneWidget);
    expect(backend.calls.where((c) => c == 'POST /plans/generate'), isEmpty);
    await harness.drainAndUnmount(tester);
  });

  group('Idempotency-Key al generar el plan', () {
    Future<void> toGenerate(WidgetTester tester) async {
      await fillUntilConsent(tester);
      await tapKey(tester, 'consent-skip');
      await tapKey(tester, 'onboarding-next'); // preferencias
      await tapKey(tester, 'onboarding-next'); // datos corporales
      await tapKey(tester, 'onboarding-next'); // revisión → generar
    }

    testWidgets('respuesta perdida: el reintento reenvía la MISMA clave y no '
        'crea una segunda versión', (tester) async {
      final backend = newUser()..loseNextGenerateResponse = true;
      final harness = await openOnboarding(tester, backend);
      await toGenerate(tester);
      expect(find.text('Tu plan está listo'), findsNothing);
      expect(backend.plansGenerated, 1, reason: 'la API ya la creó');

      await tapKey(tester, 'onboarding-next'); // reintentar
      expect(find.text('Tu plan está listo'), findsOneWidget);
      expect(backend.generateKeys, hasLength(2));
      expect(backend.generateKeys.first, isNotNull);
      expect(backend.generateKeys.toSet(), hasLength(1));
      expect(backend.plansGenerated, 1);
      await harness.drainAndUnmount(tester);
    });

    testWidgets('422 IDEMPOTENCY_KEY_REUSED: clave nueva y un reintento', (
      tester,
    ) async {
      final backend = newUser()..loseNextGenerateResponse = true;
      final harness = await openOnboarding(tester, backend);
      await toGenerate(tester);
      final first = backend.generateKeys.single!;
      // Entre medias el perfil cambió: la clave ya no vale.
      backend.reserveKeyWithOtherProfile(first);

      await tapKey(tester, 'onboarding-next');
      expect(find.text('Tu plan está listo'), findsOneWidget);
      expect(backend.generateKeys, hasLength(3));
      expect(backend.generateKeys[1], first);
      expect(backend.generateKeys[2], isNot(first));
      await harness.drainAndUnmount(tester);
    });
  });
}
