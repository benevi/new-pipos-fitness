// Biblioteca por músculo y mapa de calor (ADR-0014, Fase 3; CUJ-12): la
// figura (cada región abre su lista, con etiqueta y área ≥ 48 dp), la vista
// de lista con los 19 músculos, el filtro por material, la ficha con
// favoritos/vetados y el mapa de calor vacío y con datos.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pipos_fitness/features/exercise/exercise_detail_screen.dart';
import 'package:pipos_fitness/features/exercises/body_geometry.dart';
import 'package:pipos_fitness/features/exercises/exercises_screen.dart';
import 'package:pipos_fitness/features/exercises/muscle_groups.dart';
import 'package:pipos_fitness/features/onboarding/onboarding_screen.dart';
import 'package:pipos_fitness/models/enums.dart';
import 'package:pipos_fitness/models/progress.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

const glutesLabel = 'Glúteos, vista de Detrás. Ver sus ejercicios';

Future<AppHarness> openLibrary(
  WidgetTester tester, {
  FakeBackend? backend,
}) async {
  usePhoneSize(tester);
  final harness = AppHarness.signedIn(backend: backend);
  await harness.pump(tester);
  await tester.pumpAndSettle();
  await tapKey(tester, 'nav-plan');
  await tapKey(tester, 'plan-exercises-by-muscle');
  expect(find.byType(ExercisesScreen), findsOneWidget);
  return harness;
}

/// Toca el centro del área táctil de una región (los toques se resuelven
/// por geometría, no por el nodo semántico).
Future<void> tapRegion(WidgetTester tester, String id) async {
  await tester.tapAt(tester.getCenter(find.byKey(Key('body-region-$id'))));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'la geometría cubre los 19 músculos y cada área se resuelve a su región',
    () {
      expect({for (final r in bodyRegions) r.muscle}, Muscle.values.toSet());
      // Ids únicos (una región por músculo y vista).
      expect(bodyRegions.map((r) => r.id).toSet().length, bodyRegions.length);
      for (final scale in [0.6, 0.83, 1.5]) {
        for (final r in bodyRegions) {
          final touch = regionTouchRect(r, scale);
          expect(touch.width, greaterThanOrEqualTo(minRegionTouchSize));
          expect(touch.height, greaterThanOrEqualTo(minRegionTouchSize));
          expect(
            hitTestRegion(r.side, touch.center, scale),
            same(r),
            reason: '${r.id} a escala $scale',
          );
        }
      }
      // Lista: 10 grupos + «otros», sin repetir ni olvidar músculos.
      final listed = [for (final s in muscleSections()) ...s.muscles];
      expect(listed.toSet(), Muscle.values.toSet());
      expect(listed.length, Muscle.values.length);
    },
  );

  testWidgets('CUJ-12: de Plan a una ficha en 3 toques, con tu material y '
      'ordenados por nivel', (tester) async {
    final backend = FakeBackend();
    // Toque 1 (dentro de openLibrary): «Ver ejercicios por músculo».
    final harness = await openLibrary(tester, backend: backend);
    // Toque 2: glúteos en la figura de espaldas.
    await tapRegion(tester, 'back-glutes');
    expect(find.byType(MuscleExercisesScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Glúteos'), findsOneWidget);
    final q = backend.muscleQueries.single;
    expect(q.muscle, Muscle.glutes);
    expect(q.role, MuscleRole.primary);
    // Material del perfil.
    expect(q.equipment, [
      Equipment.bodyweight,
      Equipment.barbell,
      Equipment.dumbbell,
      Equipment.bench,
      Equipment.squatRack,
    ]);
    // Sin polea: la patada en polea no aparece.
    expect(
      find.byKey(const Key('library-exercise-patada-gluteo-polea')),
      findsNothing,
    );
    // Por nivel, con encabezado de cada nivel.
    final beginner = tester.getTopLeft(
      find.byKey(const Key('library-level-beginner')),
    );
    final intermediate = tester.getTopLeft(
      find.byKey(const Key('library-level-intermediate')),
    );
    final bridge = tester.getTopLeft(
      find.byKey(const Key('library-exercise-puente-gluteos')),
    );
    final deadlift = tester.getTopLeft(
      find.byKey(const Key('library-exercise-peso-muerto-barra')),
    );
    expect(beginner.dy, lessThan(bridge.dy));
    expect(bridge.dy, lessThan(intermediate.dy));
    expect(intermediate.dy, lessThan(deadlift.dy));

    // Toque 3: la ficha del ejercicio.
    await tapKey(tester, 'library-exercise-puente-gluteos');
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('«Todo el catálogo» quita el filtro de material', (tester) async {
    final backend = FakeBackend();
    final harness = await openLibrary(tester, backend: backend);
    await tapRegion(tester, 'back-glutes');
    await tapKey(tester, 'library-all-catalog');
    expect(backend.muscleQueries.last.equipment, isNull);
    expect(
      find.byKey(const Key('library-exercise-patada-gluteo-polea')),
      findsOneWidget,
    );
    expect(find.text('Con cualquier material'), findsOneWidget);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('sin ejercicios con tu material: lo dice y ofrece todo el '
      'catálogo', (tester) async {
    final backend = FakeBackend();
    backend.exercisesByMuscleJson[Muscle.calves] = {
      'items': [
        {
          'id': '00000000-0000-4000-8000-000000000200',
          'slug': 'gemelo-maquina',
          'nameEs': 'Gemelo en máquina',
          'nameEn': 'Machine calf raise',
          'movementPattern': 'calf_raise',
          'isCompound': false,
          'isUnilateral': false,
          'minLevel': 'beginner',
          'equipment': ['machine'],
          'loadType': 'weighted',
          'primaryMuscles': ['calves'],
        },
      ],
      'page': 1,
      'pageSize': 100,
      'total': 1,
    };
    final harness = await openLibrary(tester, backend: backend);
    await tapRegion(tester, 'back-calves');
    expect(find.byKey(const Key('muscle-exercises-empty')), findsOneWidget);
    await tapText(tester, 'Ver todo el catálogo');
    expect(
      find.byKey(const Key('library-exercise-gemelo-maquina')),
      findsOneWidget,
    );
    await harness.drainAndUnmount(tester);
  });

  testWidgets('cada región de la figura abre la lista de su músculo', (
    tester,
  ) async {
    final backend = FakeBackend();
    final harness = await openLibrary(tester, backend: backend);
    for (final r in bodyRegions) {
      await tapRegion(tester, r.id);
      final screen = tester.widget<MuscleExercisesScreen>(
        find.byType(MuscleExercisesScreen),
      );
      expect(screen.muscle, r.muscle, reason: r.id);
      expect(backend.muscleQueries.last.muscle, r.muscle, reason: r.id);
      GoRouter.of(
        tester.element(find.byType(MuscleExercisesScreen)),
      ).go(exercisesLocation);
      await tester.pumpAndSettle();
    }
    await harness.drainAndUnmount(tester);
  });

  testWidgets('etiquetas de accesibilidad y áreas ≥ 48 dp en todas las '
      'regiones', (tester) async {
    final semantics = tester.ensureSemantics();
    final harness = await openLibrary(tester);
    for (final r in bodyRegions) {
      final node = tester.getSemantics(find.byKey(Key('body-region-${r.id}')));
      final side = r.side == BodySide.front ? 'Delante' : 'Detrás';
      final data = node.getSemanticsData();
      expect(data.label, contains(', vista de $side. Ver sus ejercicios'));
      expect(data.flagsCollection.isButton, isTrue, reason: r.id);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: r.id);
      expect(node.rect.width, greaterThanOrEqualTo(48), reason: r.id);
      expect(node.rect.height, greaterThanOrEqualTo(48), reason: r.id);
    }
    expect(find.bySemanticsLabel(glutesLabel), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // TalkBack: la acción de la región abre su lista.
    tester.semantics.tap(find.semantics.byLabel(glutesLabel));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Glúteos'), findsOneWidget);
    semantics.dispose();
    await harness.drainAndUnmount(tester);
  });

  testWidgets('la vista de lista cubre los 19 músculos por grupo de volumen', (
    tester,
  ) async {
    final backend = FakeBackend();
    final harness = await openLibrary(tester, backend: backend);
    await tapKey(tester, 'exercises-tab-list');
    var seen = 0;
    for (final section in muscleSections()) {
      final key = 'muscle-section-${section.group?.wire ?? 'other'}';
      await tester.scrollUntilVisible(
        find.byKey(Key(key)),
        200,
        scrollable: verticalScrollable(),
      );
      for (final m in section.muscles) {
        final tile = find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byKey(Key('muscle-list-${m.wire}')),
        );
        await tester.scrollUntilVisible(
          tile,
          100,
          scrollable: verticalScrollable(),
        );
        expect(tile, findsOneWidget, reason: m.wire);
        seen++;
      }
    }
    expect(seen, Muscle.values.length);
    expect(find.text('Otros músculos'), findsOneWidget);
    await tapKey(tester, 'muscle-list-forearms');
    expect(find.widgetWithText(AppBar, 'Antebrazos'), findsOneWidget);
    expect(backend.muscleQueries.last.muscle, Muscle.forearms);
    await harness.drainAndUnmount(tester);
  });

  testWidgets('ficha: «Añadir a favoritos» abre el perfil con el cambio '
      'preparado y al guardar va por la edición existente', (tester) async {
    final backend = FakeBackend();
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    openExerciseDetail(
      tester.element(find.byType(Scaffold).first),
      'sentadilla-trasera-barra',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-preferences')),
      200,
      scrollable: verticalScrollable(),
    );
    expect(find.byKey(const Key('exercise-preferences')), findsOneWidget);

    await tapKey(tester, 'exercise-add-favourite');
    expect(find.byType(ProfileEditScreen), findsOneWidget);
    expect(find.text('Ejercicios favoritos'), findsOneWidget);
    expect(find.text('Sentadilla trasera con barra'), findsOneWidget);
    // Nada se guarda hasta que el usuario confirma.
    expect(backend.profileRequests, isEmpty);

    await tapKey(tester, 'onboarding-next'); // Preferencias → Datos.
    await tapKey(tester, 'onboarding-next'); // Guardar.
    final saved = backend.profileRequests.single;
    expect(saved.favouriteExerciseSlugs, contains('sentadilla-trasera-barra'));
    expect(
      saved.bannedExerciseSlugs,
      isNot(contains('sentadilla-trasera-barra')),
    );
    await harness.drainAndUnmount(tester);
  });

  testWidgets('ficha: «No quiero hacerlo» lo pasa a vetados (y lo quita de '
      'favoritos)', (tester) async {
    final backend = FakeBackend();
    backend.exerciseDetails['back-squat'] = {
      ...fixture('exercise_detail'),
      'slug': 'back-squat',
    };
    usePhoneSize(tester);
    final harness = AppHarness.signedIn(backend: backend);
    await harness.pump(tester);
    await tester.pumpAndSettle();
    // `back-squat` ya es favorito en el perfil.
    openExerciseDetail(
      tester.element(find.byType(Scaffold).first),
      'back-squat',
    );
    await tester.pumpAndSettle();
    await tapKey(tester, 'exercise-ban');
    expect(find.text('Ejercicios que no quieres hacer'), findsOneWidget);
    await tapKey(tester, 'onboarding-next');
    await tapKey(tester, 'onboarding-next');
    final saved = backend.profileRequests.single;
    expect(saved.bannedExerciseSlugs, contains('back-squat'));
    expect(saved.favouriteExerciseSlugs, isNot(contains('back-squat')));
    await harness.drainAndUnmount(tester);
  });

  group('mapa de calor de la semana', () {
    Future<AppHarness> openProgress(
      WidgetTester tester,
      FakeBackend backend,
    ) async {
      usePhoneSize(tester);
      final harness = AppHarness.signedIn(backend: backend);
      await harness.pump(tester);
      await tester.pumpAndSettle();
      await tapKey(tester, 'nav-progress');
      return harness;
    }

    testWidgets('semana vacía: mensaje, sin figura', (tester) async {
      final backend = FakeBackend()
        ..volume = VolumeResponse.fromJson({
          'timezone': 'Europe/Madrid',
          'weeks': <Object>[],
        });
      final harness = await openProgress(tester, backend);
      await tester.scrollUntilVisible(
        find.byKey(const Key('heatmap')),
        200,
        scrollable: verticalScrollable(),
      );
      expect(find.byKey(const Key('heatmap-empty')), findsOneWidget);
      expect(find.byKey(const Key('heatmap-figure-front')), findsNothing);
      await harness.drainAndUnmount(tester);
    });

    testWidgets('con datos: estados por grupo, leyenda y etiquetas', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final harness = await openProgress(tester, FakeBackend());
      await tester.scrollUntilVisible(
        find.byKey(const Key('heatmap-figure-front')),
        200,
        scrollable: verticalScrollable(),
      );
      expect(
        find.text('Series de esta semana frente a tu objetivo.'),
        findsOneWidget,
      );
      for (final s in ['below', 'within', 'above', 'no_target']) {
        expect(find.byKey(Key('heatmap-legend-$s')), findsOneWidget);
      }
      // Nada de recuperación ni predicciones.
      expect(find.textContaining('recupera'), findsNothing);
      String label(String id) => tester
          .getSemantics(
            find.descendant(
              of: find.byKey(const Key('heatmap')),
              matching: find.byKey(Key('body-region-$id')),
            ),
          )
          .label;
      expect(
        label('front-quads'),
        'Cuádriceps (Cuádriceps): 6 series, objetivo 8 a 12, por debajo',
      );
      expect(
        label('back-glutes'),
        'Glúteos (Glúteos): 11 series, objetivo 10 a 14, dentro del rango',
      );
      // Abductores cuentan para glúteos.
      expect(label('back-abductors'), startsWith('Abductores (Glúteos): 11'));
      // Grupo sin objetivo en la semana y músculo sin grupo.
      expect(
        label('front-chest'),
        'Pecho (Pecho): 0 series, objetivo – a –, sin objetivo',
      );
      expect(
        label('front-traps'),
        'Trapecio: no cuenta para ningún grupo, sin objetivo',
      );
      // Solo lectura: las regiones del mapa no son botones.
      final data = tester
          .getSemantics(
            find.descendant(
              of: find.byKey(const Key('heatmap')),
              matching: find.byKey(const Key('body-region-front-quads')),
            ),
          )
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      // Las barras siguen debajo.
      await tester.scrollUntilVisible(
        find.byKey(const Key('volume-quads')),
        200,
        scrollable: verticalScrollable(),
      );
      expect(find.byKey(const Key('volume-quads')), findsOneWidget);
      semantics.dispose();
      await harness.drainAndUnmount(tester);
    });
  });
}
