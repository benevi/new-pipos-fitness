// Ficha del ejercicio (CUJ-11, ADR-0014): contenido completo, ficha sin
// descripción, sin red con y sin caché, ejercicio retirado, zonas a vigilar
// solo con consentimiento y los cuatro puntos de entrada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/offline/offline_providers.dart';
import 'package:pipos_fitness/features/exercise/exercise_detail_screen.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/exercise.dart';
import 'package:pipos_fitness/models/profile.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

const squat = '00000000-0000-4000-8000-000000000040';
const squatSlot = '00000000-0000-4000-8000-000000000030';
const legPress = '00000000-0000-4000-8000-000000000044';

/// Abre la app en Hoy y navega a la ficha de [idOrSlug] por su ruta.
Future<AppHarness> openDetail(
  WidgetTester tester,
  String idOrSlug, {
  AppHarness? harness,
  bool online = true,
}) async {
  usePhoneSize(tester);
  final h = harness ?? AppHarness.signedIn();
  await h.pump(tester);
  await tester.pumpAndSettle();
  h.setOnline(online);
  final context = tester.element(find.byType(Scaffold).first);
  openExerciseDetail(context, idOrSlug);
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('ficha completa: descripción, músculos, claves, errores, '
      'material, nivel y zonas a vigilar con consentimiento', (tester) async {
    final backend = FakeBackend();
    // Limitación en rodilla con consentimiento que cubre las limitaciones.
    backend.profileJson = {
      ...fixture('profile'),
      'limitations': ['knee'],
    };
    final harness = await openDetail(
      tester,
      squat,
      harness: AppHarness.signedIn(backend: backend),
    );
    final detail = ExerciseDetail.fromJson(fixture('exercise_detail'));

    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(find.text('Sentadilla trasera con barra'), findsOneWidget);
    expect(find.text(detail.descriptionEs!), findsOneWidget);
    expect(find.text('Músculos que trabaja'), findsOneWidget);
    expect(find.text('Cuádriceps'), findsOneWidget);
    expect(find.text('Glúteos'), findsOneWidget);
    expect(find.text('Aductores'), findsOneWidget);
    for (final cue in detail.cuesEs) {
      expect(find.text(cue), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-watch-zones')),
      200,
      scrollable: verticalScrollable(),
    );
    for (final m in detail.mistakesEs) {
      expect(find.text(m), findsOneWidget);
    }
    expect(find.text('Barra olímpica, Rack de sentadilla'), findsOneWidget);
    expect(find.text('Intermedio (1–3 años)'), findsOneWidget);
    // Solo la rodilla (la limitación del usuario), no la cadera ni la lumbar.
    expect(find.text('Rodilla: este ejercicio la carga'), findsOneWidget);
    expect(find.textContaining('Cadera'), findsNothing);
    expect(harness.backend.calls, contains('GET /exercises/$squat'));
    await harness.drainAndUnmount(tester);
  });

  test('zonas a vigilar: nada sin consentimiento de limitaciones o sin '
      'coincidencias; «evitar» primero', () {
    final detail = ExerciseDetail.fromJson({
      ...fixture('exercise_detail'),
      'riskTags': [
        {'zone': 'knee', 'level': 'caution'},
        {'zone': 'lumbar', 'level': 'avoid'},
      ],
    });
    ProfileResponse profile({required bool consent, List<String>? zones}) =>
        ProfileResponse.fromJson({
          ...fixture('profile'),
          'limitations': zones ?? ['knee', 'lumbar'],
          'healthConsent': {
            ...fixture('profile')['healthConsent'] as Map<String, dynamic>,
            'granted': consent,
          },
        });

    expect(zonesToWatch(detail, null), isEmpty);
    expect(zonesToWatch(detail, profile(consent: false)), isEmpty);
    expect(zonesToWatch(detail, profile(consent: true, zones: [])), isEmpty);
    expect(
      zonesToWatch(
        detail,
        profile(consent: true),
      ).map((t) => (t.zone, t.level)),
      [(BodyZone.lumbar, RiskLevel.avoid), (BodyZone.knee, RiskLevel.caution)],
    );
  });

  testWidgets('ficha sin descripción ni errores: no deja huecos', (
    tester,
  ) async {
    final backend = FakeBackend();
    backend.exerciseDetails[squat] = fixture('exercise_detail_legacy');
    final harness = await openDetail(
      tester,
      squat,
      harness: AppHarness.signedIn(backend: backend),
    );
    expect(find.byKey(const Key('exercise-description')), findsNothing);
    expect(find.byKey(const Key('exercise-mistakes')), findsNothing);
    expect(find.text('Errores comunes'), findsNothing);
    expect(find.text('Músculos que trabaja'), findsOneWidget);
    expect(find.byKey(const Key('exercise-cues')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('sin red y con la ficha precargada con el plan: se ve la copia '
      'con el aviso de datos guardados', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    // Al abrir Plan se precargan las fichas del plan vigente.
    await tapKey(tester, 'nav-plan');
    await pumpFrames(tester);
    expect(harness.backend.calls, contains('GET /exercises/$squat'));
    final cached = await tester.runAsync(
      () => harness
          .container(tester)
          .read(cacheStoreProvider)
          .read(CacheKeys.exercise(squat)),
    );
    expect(cached, isNotNull);

    harness.setOnline(false);
    final context = tester.element(find.byType(Scaffold).first);
    openExerciseDetail(context, squat);
    await tester.pumpAndSettle();
    expect(find.text('Sentadilla trasera con barra'), findsOneWidget);
    expect(
      find.textContaining('Sin conexión. Datos guardados'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('exercise-description')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('sin red y sin copia: «Necesitas conexión para ver esta ficha» '
      'y al volver la red, reintentar la abre', (tester) async {
    final harness = await openDetail(tester, 'no-guardada', online: false);
    expect(
      find.text('Necesitas conexión para ver esta ficha.'),
      findsOneWidget,
    );
    harness.setOnline(true);
    await tapText(tester, 'Reintentar');
    expect(find.byKey(const Key('exercise-detail')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('ejercicio retirado (404): mensaje claro y sin reintento', (
    tester,
  ) async {
    final backend = FakeBackend()..missingExercises.add('retirado');
    final harness = await openDetail(
      tester,
      'retirado',
      harness: AppHarness.signedIn(backend: backend),
    );
    expect(
      find.text('Este ejercicio ya no está en el catálogo.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsNothing);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('desde Hoy: tocar el nombre abre la ficha (1 toque) y volver '
      'deja la sesión como estaba', (tester) async {
    usePhoneSize(tester);
    final semantics = tester.ensureSemantics();
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Ver ficha de Sentadilla trasera')),
      findsOneWidget,
    );
    await tapKey(tester, 'exercise-link-$squat');
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    expect(find.byKey(const Key('exercise-link-$squat')), findsOneWidget);
    semantics.dispose();
    await harness.drainAndUnmount(tester);
  });

  testWidgets('desde Plan: el nombre de cada ejercicio abre su ficha', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-plan');
    await tester.scrollUntilVisible(
      find.text('Cuerpo completo A'),
      200,
      scrollable: verticalScrollable(),
    );
    if (find.byKey(const Key('exercise-link-$squat')).evaluate().isEmpty) {
      await tapText(tester, 'Cuerpo completo A');
    }
    await tapKey(tester, 'exercise-link-$squat');
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('desde cambiar ejercicio: cada alternativa abre su ficha encima '
      'de la hoja, y al volver la hoja sigue abierta', (tester) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn();
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'swap-$squatSlot');
    await tapKey(tester, 'exercise-link-$legPress');
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(harness.backend.calls, contains('GET /exercises/$legPress'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Alternativas a Sentadilla trasera'), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('desde la búsqueda de favoritos y vetados del onboarding', (
    tester,
  ) async {
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(
      backend: FakeBackend(hasPlan: false, hasProfile: false),
    );
    await harness.pump(tester);
    await tester.pumpAndSettle();
    await tapKey(tester, 'goal-hypertrophy');
    await tapKey(tester, 'level-beginner');
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'days-3');
    await tapKey(tester, 'minutes-45');
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'preset-bodyweight');
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'consent-skip');
    expect(find.text('Preferencias (opcional)'), findsOneWidget);

    await tapText(tester, 'Añadir ejercicio');
    await tester.enterText(find.byKey(const Key('exercise-search')), 'sen');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-info-$squat')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    // La búsqueda sigue abierta para elegir.
    expect(find.byKey(const Key('exercise-search')), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets(
    'texto ×2.0: la ficha no desborda y los objetivos miden ≥ 48 dp',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      final backend = FakeBackend();
      backend.profileJson = {
        ...fixture('profile'),
        'limitations': ['knee'],
      };
      final harness = await openDetail(
        tester,
        squat,
        harness: AppHarness.signedIn(backend: backend),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-watch-zones')),
        300,
        scrollable: verticalScrollable(),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    },
  );
}
