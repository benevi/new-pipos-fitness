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

class ShareSheetExportSaver implements ExportSaver {
  @override
  Future<void> save(String fileName, Map<String, dynamic> json) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')]);
  }
}

final exportSaverProvider = Provider<ExportSaver>(
  (_) => ShareSheetExportSaver(),
);
