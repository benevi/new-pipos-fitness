// Vídeos de técnica (ADR-0014, Fase 4): botón «Ver vídeo (YouTube)» en la
// ficha y en la tarjeta de Hoy. Solo aparece con un vídeo revisado
// (`hasVideo` / `media`), avisa de que se sale de Pipos antes de abrir el
// vídeo FUERA de la app en el segundo de inicio y, sin red, avisa en vez de
// abrir nada. Los vídeos de estos tests son FICTICIOS: el catálogo real no
// lleva ninguno hasta que una persona lo elija y lo apruebe por PR.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/exercise/exercise_detail_screen.dart';
import 'package:pipos_fitness/features/exercise/exercise_video.dart';
import 'package:pipos_fitness/models/exercise.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/ui.dart';

/// Sentadilla (ejercicio 040, hueco 030) y remo (043) en `today_session`.
const squat = '00000000-0000-4000-8000-000000000040';
const row = '00000000-0000-4000-8000-000000000043';

/// URL que debe abrirse: el vídeo ficticio en el segundo 42.
final expectedUri = Uri.parse(
  'https://www.youtube.com/watch?v=AAAAAAAAAA1&t=42s',
);

/// Lanzador falso: apunta lo que se abriría fuera de la app.
class RecordingLauncher implements ExternalLinkLauncher {
  RecordingLauncher({this.succeed = true});

  final bool succeed;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeed;
  }
}

/// Hoy con `hasVideo` en los ejercicios de [withVideo].
FakeBackend backendWithVideo(Set<String> withVideo) {
  final backend = FakeBackend();
  final today = fixture('today_session');
  for (final e in (today['exercises'] as List).cast<Map<String, dynamic>>()) {
    final id = (e['exercise'] as Map<String, dynamic>)['id'];
    e['hasVideo'] = withVideo.contains(id);
  }
  backend.todayJson = today;
  backend.exerciseDetails[squat] = fixture('exercise_detail_video');
  return backend;
}

Future<(AppHarness, RecordingLauncher)> openToday(
  WidgetTester tester,
  FakeBackend backend, {
  RecordingLauncher? launcher,
}) async {
  usePhoneSize(tester);
  final h = AppHarness.signedIn(backend: backend);
  final l = launcher ?? RecordingLauncher();
  await h.pump(
    tester,
    overrides: [externalLinkLauncherProvider.overrideWithValue(l)],
  );
  await tester.pumpAndSettle();
  return (h, l);
}

Future<(AppHarness, RecordingLauncher)> openDetail(
  WidgetTester tester,
  Map<String, dynamic> detail,
) async {
  usePhoneSize(tester);
  final backend = FakeBackend()..exerciseDetails[squat] = detail;
  final h = AppHarness.signedIn(backend: backend);
  final l = RecordingLauncher();
  await h.pump(
    tester,
    overrides: [externalLinkLauncherProvider.overrideWithValue(l)],
  );
  await tester.pumpAndSettle();
  openExerciseDetail(tester.element(find.byType(Scaffold).first), squat);
  await tester.pumpAndSettle();
  return (h, l);
}

void main() {
  group('modelo', () {
    test('el vídeo principal se abre en el segundo de inicio', () {
      final detail = ExerciseDetail.fromJson(fixture('exercise_detail_video'));
      final video = detail.primaryVideo!;
      expect(video.channelName, 'Canal de prueba');
      expect(video.watchUri, expectedUri);
      expect(
        const ExerciseVideo(
          videoId: 'AAAAAAAAAA1',
          channelName: 'c',
          locale: 'es',
        ).watchUri.toString(),
        'https://www.youtube.com/watch?v=AAAAAAAAAA1',
      );
    });

    test('sin medios, solo imágenes o con un id dudoso no hay vídeo', () {
      ExerciseVideo? videoOf(List<Map<String, dynamic>> media) =>
          ExerciseDetail.fromJson({
            ...fixture('exercise_detail'),
            'media': media,
          }).primaryVideo;
      final video =
          (fixture('exercise_detail_video')['media'] as List).first
              as Map<String, dynamic>;
      final image =
          (fixture('exercise_detail_video')['media'] as List).last
              as Map<String, dynamic>;
      expect(videoOf([]), isNull);
      expect(videoOf([image]), isNull);
      expect(
        videoOf([
          {...video, 'videoId': 'x/../evil'},
        ]),
        isNull,
      );
      expect(
        videoOf([
          {...video, 'kind': 'youtube_search'},
        ]),
        isNull,
      );
      // Si el principal es una imagen, se usa el primer vídeo.
      expect(
        videoOf([
          {...image, 'isPrimary': true},
          {...video, 'isPrimary': false},
        ])?.videoId,
        'AAAAAAAAAA1',
      );
    });
  });

  testWidgets('Hoy: el botón aparece solo en el ejercicio con hasVideo; '
      'tamaño táctil ≥ 48 dp y TalkBack avisa de que sale de Pipos', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (h, _) = await openToday(tester, backendWithVideo({squat}));

    expect(find.byKey(const Key('exercise-video-$squat')), findsOneWidget);
    expect(find.byKey(const Key('exercise-video-$row')), findsNothing);
    expect(find.text('Ver vídeo (YouTube)'), findsOneWidget);
    final size = tester.getSize(find.byKey(const Key('exercise-video-$squat')));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel(
        'Ver vídeo de técnica de Sentadilla trasera en YouTube. '
        'Sales de Pipos.',
      ),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
    await h.drainAndUnmount(tester);
  });

  testWidgets('Hoy: sin hasVideo (o respuesta anterior) no hay botón', (
    tester,
  ) async {
    final (h, _) = await openToday(tester, backendWithVideo({}));
    expect(find.text('Ver vídeo (YouTube)'), findsNothing);
    await h.drainAndUnmount(tester);
  });

  testWidgets('Hoy: avisa de que sale de Pipos y abre el vídeo fuera de la '
      'app en el segundo de inicio; «Cancelar» no abre nada', (tester) async {
    final (h, launcher) = await openToday(tester, backendWithVideo({squat}));

    await tapKey(tester, 'exercise-video-$squat');
    expect(find.text('Vas a salir de Pipos'), findsOneWidget);
    expect(find.textContaining('canal Canal de prueba'), findsOneWidget);
    expect(find.textContaining('Pipos no envía ningún dato'), findsOneWidget);
    await tapText(tester, 'Cancelar');
    expect(launcher.opened, isEmpty);

    await tapKey(tester, 'exercise-video-$squat');
    await tapKey(tester, 'exercise-video-confirm');
    expect(launcher.opened, [expectedUri]);
    expect(h.backend.calls, contains('GET /exercises/$squat'));
    await h.drainAndUnmount(tester);
  });

  testWidgets('Hoy sin red: el botón avisa y no abre nada', (tester) async {
    final (h, launcher) = await openToday(tester, backendWithVideo({squat}));
    h.setOnline(false);
    await tester.pump();

    await tapKey(tester, 'exercise-video-$squat');
    expect(
      find.text(
        'Sin conexión: el vídeo necesita internet. Inténtalo cuando '
        'vuelvas a tener red.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vas a salir de Pipos'), findsNothing);
    expect(launcher.opened, isEmpty);
    await h.drainAndUnmount(tester);
  });

  testWidgets('Hoy: si el vídeo se retiró después, avisa en vez de abrir', (
    tester,
  ) async {
    final backend = backendWithVideo({squat})
      ..exerciseDetails[squat] = fixture('exercise_detail');
    final (h, launcher) = await openToday(tester, backend);

    await tapKey(tester, 'exercise-video-$squat');
    expect(
      find.text('Este ejercicio ya no tiene un vídeo revisado.'),
      findsOneWidget,
    );
    expect(launcher.opened, isEmpty);
    await h.drainAndUnmount(tester);
  });

  testWidgets('si el sistema no puede abrir YouTube, se dice', (tester) async {
    final (h, launcher) = await openToday(
      tester,
      backendWithVideo({squat}),
      launcher: RecordingLauncher(succeed: false),
    );
    await tapKey(tester, 'exercise-video-$squat');
    await tapKey(tester, 'exercise-video-confirm');
    expect(launcher.opened, [expectedUri]);
    expect(find.text('No se ha podido abrir YouTube.'), findsOneWidget);
    await h.drainAndUnmount(tester);
  });

  testWidgets('ficha con vídeo: botón, canal y apertura tras el aviso', (
    tester,
  ) async {
    final (h, launcher) = await openDetail(
      tester,
      fixture('exercise_detail_video'),
    );
    expect(find.byKey(const Key('exercise-video')), findsOneWidget);
    expect(
      find.text(
        'Vídeo revisado del canal Canal de prueba. Se abre en YouTube, '
        'fuera de Pipos.',
      ),
      findsOneWidget,
    );
    await tapKey(tester, 'exercise-video-$squat');
    await tapKey(tester, 'exercise-video-confirm');
    expect(launcher.opened, [expectedUri]);
    await h.drainAndUnmount(tester);
  });

  testWidgets('ficha sin vídeo revisado: ni botón ni hueco', (tester) async {
    final (h, _) = await openDetail(tester, fixture('exercise_detail'));
    expect(find.byKey(const Key('exercise-detail')), findsOneWidget);
    expect(find.byKey(const Key('exercise-video')), findsNothing);
    expect(find.text('Ver vídeo (YouTube)'), findsNothing);
    await h.drainAndUnmount(tester);
  });

  testWidgets('ficha sin red: el botón de la copia guardada avisa', (
    tester,
  ) async {
    final (h, launcher) = await openDetail(
      tester,
      fixture('exercise_detail_video'),
    );
    h.setOnline(false);
    await tapKey(tester, 'exercise-video-$squat');
    expect(find.textContaining('Sin conexión: el vídeo'), findsOneWidget);
    expect(launcher.opened, isEmpty);
    await h.drainAndUnmount(tester);
  });

  testWidgets('en inglés el botón y el aviso están traducidos', (tester) async {
    final (h, _) = await openToday(tester, backendWithVideo({squat}));
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    await tester.pumpAndSettle();
    expect(find.text('Watch video (YouTube)'), findsOneWidget);
    await tapKey(tester, 'exercise-video-$squat');
    expect(find.text("You're leaving Pipos"), findsOneWidget);
    expect(find.text('Open YouTube'), findsOneWidget);
    await tapText(tester, 'Cancel');
    await h.drainAndUnmount(tester);
  });

  test('ProviderScope por defecto usa url_launcher en modo externo', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(externalLinkLauncherProvider),
      isA<UrlLauncherExternalLinks>(),
    );
  });
}
