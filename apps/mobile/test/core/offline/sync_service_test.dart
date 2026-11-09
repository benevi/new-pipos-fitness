import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/core/offline/app_database.dart';
import 'package:pipos_fitness/core/offline/connectivity.dart';
import 'package:pipos_fitness/core/offline/set_log_uploader.dart';
import 'package:pipos_fitness/core/offline/sync_service.dart';

import '../../helpers/fake_http_adapter.dart';

/// Uploader programable: devuelve los resultados de [script] en orden y
/// luego [fallback].
class ScriptedUploader implements SetLogUploader {
  ScriptedUploader([List<UploadOutcome>? script]) : script = [...?script];

  final List<UploadOutcome> script;
  UploadOutcome fallback = const UploadSucceeded();
  final List<String> sent = [];

  @override
  Future<UploadOutcome> upload(PendingSetLog item) async {
    sent.add(item.clientId);
    return script.isNotEmpty ? script.removeAt(0) : fallback;
  }
}

void main() {
  late AppDatabase db;
  late ManualConnectivitySource connectivity;
  late DateTime now;
  final services = <SyncService>[];

  SyncService makeService(SetLogUploader uploader, {String? userId = 'u1'}) {
    final s = SyncService(
      database: db,
      uploader: uploader,
      connectivity: connectivity,
      userId: userId,
      clock: () => now,
      backoff: const BackoffPolicy(
        baseDelay: Duration(seconds: 2),
        maxDelay: Duration(minutes: 1),
        maxAttempts: 4,
      ),
    );
    services.add(s);
    return s;
  }

  Future<void> enqueue(SyncService s, String id, int setIndex) => s.enqueue(
    clientId: id,
    workoutSessionId: 'ws1',
    workoutExerciseId: 'we1',
    exerciseId: 'ex1',
    setIndex: setIndex,
    reps: 10,
    loadKg: 60,
    rir: 2,
    completedAt: now.add(Duration(seconds: setIndex)),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    connectivity = ManualConnectivitySource(online: false);
    now = DateTime(2026, 1, 1, 10);
  });

  tearDown(() async {
    for (final s in services) {
      await s.dispose();
    }
    services.clear();
    await connectivity.dispose();
    await db.close();
  });

  test('sin red: la serie queda pending y no se envía', () async {
    final uploader = ScriptedUploader();
    final service = makeService(uploader);
    await enqueue(service, 'c1', 0);

    final report = await service.syncNow();

    expect(report.offline, isTrue);
    expect(uploader.sent, isEmpty);
    final queue = await service.queue();
    expect(queue.single.status, PendingSetLogStatus.pending);
    expect(queue.single.attempts, 0);
  });

  test('con red: envía en orden y borra de la cola', () async {
    final uploader = ScriptedUploader();
    final service = makeService(uploader);
    await enqueue(service, 'c2', 1);
    await enqueue(service, 'c1', 0);

    connectivity.online = true;
    final synced = <String>[];
    service.synced.listen((e) => synced.add(e.clientId));
    final report = await service.syncNow();
    await Future<void>.delayed(Duration.zero);

    expect(report.sent, 2);
    expect(uploader.sent, ['c1', 'c2'], reason: 'orden por completedAt');
    expect(await service.queue(), isEmpty);
    expect(synced, ['c1', 'c2']);
  });

  test('al volver la conectividad se sincroniza sola', () async {
    final uploader = ScriptedUploader();
    final service = makeService(uploader);
    await service.start();
    await enqueue(service, 'c1', 0);
    expect(uploader.sent, isEmpty);

    connectivity.online = true;
    for (var i = 0; i < 20 && uploader.sent.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await service.syncNow();
    expect(uploader.sent, ['c1']);
    expect(await service.queue(), isEmpty);
  });

  test('respuesta duplicada (409) cuenta como sincronizada', () async {
    final uploader = ScriptedUploader([const UploadDuplicate()]);
    final service = makeService(uploader);
    await enqueue(service, 'c1', 0);
    connectivity.online = true;

    final report = await service.syncNow();

    expect(report.sent, 1);
    expect(await service.queue(), isEmpty);
  });

  test('error transitorio → reintenta con backoff exponencial', () async {
    final uploader = ScriptedUploader([
      const UploadTransientFailure('HTTP 503'),
      const UploadTransientFailure('HTTP 503'),
    ]);
    final service = makeService(uploader);
    await enqueue(service, 'c1', 0);
    await enqueue(service, 'c2', 1);
    connectivity.online = true;

    var report = await service.syncNow();
    expect(report.deferred, 2, reason: 'se detiene para no desordenar');
    var item = (await service.queue()).first;
    expect(item.status, PendingSetLogStatus.pending);
    expect(item.attempts, 1);
    expect(item.lastError, 'HTTP 503');
    expect(item.nextAttemptAt, now.add(const Duration(seconds: 2)));

    // Antes de que venza el backoff no se reintenta.
    now = now.add(const Duration(seconds: 1));
    await service.syncNow();
    expect(uploader.sent, ['c1']);

    // Vence el primer backoff (2 s) → nuevo fallo → espera 4 s.
    now = now.add(const Duration(seconds: 1));
    await service.syncNow();
    item = (await service.queue()).first;
    expect(item.attempts, 2);
    expect(item.nextAttemptAt, now.add(const Duration(seconds: 4)));

    now = now.add(const Duration(seconds: 4));
    report = await service.syncNow();
    expect(report.sent, 2);
    expect(uploader.sent, ['c1', 'c1', 'c1', 'c2']);
    expect(await service.queue(), isEmpty);
  });

  test('error permanente o reintentos agotados → failed, sin bloquear al '
      'resto', () async {
    final uploader = ScriptedUploader([
      const UploadPermanentFailure('HTTP 400'),
    ]);
    final service = makeService(uploader);
    await enqueue(service, 'c1', 0);
    await enqueue(service, 'c2', 1);
    connectivity.online = true;

    final report = await service.syncNow();

    expect(report.failed, 1);
    expect(report.sent, 1);
    final queue = await service.queue();
    expect(queue.single.clientId, 'c1');
    expect(queue.single.status, PendingSetLogStatus.failed);

    await service.retryFailed();
    await service.syncNow();
    expect(await service.queue(), isEmpty);
  });

  test('BackoffPolicy: 2^n acotado', () {
    const p = BackoffPolicy(
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 30),
    );
    expect(p.delayFor(1), const Duration(seconds: 2));
    expect(p.delayFor(2), const Duration(seconds: 4));
    expect(p.delayFor(3), const Duration(seconds: 8));
    expect(p.delayFor(10), const Duration(seconds: 30));
  });

  test('sobrevive a un "reinicio": otra instancia sobre la misma BD envía lo '
      'pendiente, incluidos envíos interrumpidos', () async {
    final first = makeService(ScriptedUploader());
    await enqueue(first, 'c1', 0);
    await enqueue(first, 'c2', 1);
    // Simula que la app murió a mitad del envío de c1.
    await (db.update(
      db.pendingSetLogs,
    )..where((t) => t.clientId.equals('c1'))).write(
      const PendingSetLogsCompanion(status: Value(PendingSetLogStatus.syncing)),
    );
    await first.dispose();

    connectivity.online = true;
    final uploader = ScriptedUploader();
    final second = makeService(uploader);
    await second.start();
    await second.syncNow();

    expect(uploader.sent, ['c1', 'c2']);
    expect(await second.queue(), isEmpty);
  });

  test('solo sincroniza las series del usuario de la sesión', () async {
    final a = makeService(ScriptedUploader(), userId: 'ana');
    await enqueue(a, 'ana-1', 0);
    connectivity.online = false;

    connectivity.online = true;
    final uploader = ScriptedUploader();
    final b = makeService(uploader, userId: 'bob');
    await b.syncNow();

    expect(uploader.sent, isEmpty);
    expect(await b.queue(), isEmpty);
    expect((await a.queue()).single.clientId, 'ana-1');
  });

  group('ApiSetLogUploader', () {
    late FakeHttpAdapter adapter;
    late Dio dio;

    setUp(() {
      adapter = FakeHttpAdapter();
      dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = adapter;
    });

    Future<PendingSetLog> item() async {
      final s = makeService(ScriptedUploader());
      return s.enqueue(
        clientId: 'cid-1',
        workoutSessionId: 'ws1',
        workoutExerciseId: 'we1',
        setIndex: 0,
        reps: 8,
        loadKg: 50,
      );
    }

    test('envía clientId y datos a la ruta de sets', () async {
      const path = '/workouts/ws1/exercises/we1/sets';
      adapter.reply('POST', path, 201, {'id': 'ws1'});

      final outcome = await ApiSetLogUploader(dio).upload(await item());

      expect(outcome, isA<UploadSucceeded>());
      final body = adapter.requests.single.data as Map;
      expect(body['clientId'], 'cid-1');
      expect(body['weightKg'], 50);
      expect(body['reps'], 8);
      expect(body['completed'], isTrue);
    });

    test(
      'mapea 409 → duplicado, 5xx/sin red → transitorio, 400 → permanente',
      () async {
        const path = '/workouts/ws1/exercises/we1/sets';
        final pending = await item();
        final uploader = ApiSetLogUploader(dio);

        adapter.reply('POST', path, 409, {'message': 'duplicate'});
        expect(await uploader.upload(pending), isA<UploadDuplicate>());
        adapter.reply('POST', path, 200, {'id': 'ws1'});
        expect(await uploader.upload(pending), isA<UploadSucceeded>());
        adapter.reply('POST', path, 503);
        expect(await uploader.upload(pending), isA<UploadTransientFailure>());
        adapter.on('POST', path, (_) async => const FakeResponse.offline());
        expect(await uploader.upload(pending), isA<UploadTransientFailure>());
        adapter.reply('POST', path, 400, {'message': 'bad'});
        expect(await uploader.upload(pending), isA<UploadPermanentFailure>());
      },
    );
  });
}
