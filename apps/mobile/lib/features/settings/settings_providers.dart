import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/pipos_api.dart';
import '../../models/profile.dart';
import '../../models/progress.dart';

final healthConsentProvider = FutureProvider.autoDispose<HealthConsentStatus>(
  (ref) => ref.watch(profileApiProvider).getHealthConsent(),
);

final nutritionTargetsProvider = FutureProvider.autoDispose<NutritionTargets>(
  (ref) => ref.watch(profileApiProvider).getNutritionTargets(),
);

/// Entrega el JSON exportado al usuario (hoja de compartir del sistema:
/// guardar en Archivos, enviar por correo...). Sustituible en tests.
abstract class ExportSaver {
  Future<void> save(String fileName, Map<String, dynamic> json);
}

/// Escribe el JSON en el directorio temporal, abre la hoja de compartir y
/// BORRA el fichero al terminar (contiene datos personales y de salud: no
/// debe quedarse en el temporal). share_plus copia el fichero a su propia
/// caché antes de compartirlo, así que borrarlo después es seguro.
class ShareSheetExportSaver implements ExportSaver {
  ShareSheetExportSaver({
    Future<Directory> Function()? tempDirectory,
    Future<void> Function(XFile file)? share,
  }) : _tempDirectory = tempDirectory ?? getTemporaryDirectory,
       _share = share ?? _shareSheet;

  final Future<Directory> Function() _tempDirectory;
  final Future<void> Function(XFile file) _share;

  static Future<void> _shareSheet(XFile file) async {
    await SharePlus.instance.share(ShareParams(files: [file]));
  }

  @override
  Future<void> save(String fileName, Map<String, dynamic> json) async {
    final dir = await _tempDirectory();
    final file = File('${dir.path}/$fileName');
    try {
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );
      await _share(XFile(file.path, mimeType: 'application/json'));
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}

final exportSaverProvider = Provider<ExportSaver>(
  (_) => ShareSheetExportSaver(),
);
