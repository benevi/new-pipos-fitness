// Tokens, BD local (series/sesiones) y cachés no deben salir del
// dispositivo por la copia de seguridad de Android.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const res = 'android/app/src/main/res/xml';

  test('AndroidManifest desactiva la copia de seguridad', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  test('las reglas de copia excluyen todos los dominios', () {
    const domains = ['root', 'file', 'database', 'sharedpref', 'external'];
    final backup = File('$res/backup_rules.xml').readAsStringSync();
    final extraction = File(
      '$res/data_extraction_rules.xml',
    ).readAsStringSync();
    for (final d in domains) {
      expect(backup, contains('<exclude domain="$d" path="." />'));
      expect(
        RegExp('<exclude domain="$d" path="." />').allMatches(extraction),
        hasLength(2),
        reason: 'cloud-backup y device-transfer',
      );
    }
    expect(backup, isNot(contains('<include')));
    expect(extraction, isNot(contains('<include')));
  });
}
