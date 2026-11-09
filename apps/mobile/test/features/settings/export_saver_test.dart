import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/settings/settings_providers.dart';

void main() {
  late Directory tmp;

  setUp(() async => tmp = await Directory.systemTemp.createTemp('export'));
  tearDown(() => tmp.delete(recursive: true));

  test('el JSON exportado se borra del temporal tras compartirlo', () async {
    String? sharedContent;
    final saver = ShareSheetExportSaver(
      tempDirectory: () async => tmp,
      share: (f) async => sharedContent = await File(f.path).readAsString(),
    );
    await saver.save('pipos.json', {'a': 1});
    expect(sharedContent, contains('"a": 1'));
    expect(tmp.listSync(), isEmpty);
  });

  test('también se borra si compartir falla', () async {
    final saver = ShareSheetExportSaver(
      tempDirectory: () async => tmp,
      share: (_) async => throw StateError('cancelado'),
    );
    await expectLater(saver.save('pipos.json', {'a': 1}), throwsStateError);
    expect(tmp.listSync(), isEmpty);
  });
}
