import 'package:dio/dio.dart';

import 'app_database.dart';

/// Resultado de intentar enviar una serie.
sealed class UploadOutcome {
  const UploadOutcome();
}

/// La API aceptó la serie (201/200). [responseData] es la sesión
/// actualizada que devuelve el endpoint, si la hay.
class UploadSucceeded extends UploadOutcome {
  const UploadSucceeded([this.responseData]);
  final Object? responseData;
}

/// La API ya tenía esa serie (mismo `clientId`): cuenta como sincronizada.
class UploadDuplicate extends UploadOutcome {
  const UploadDuplicate([this.responseData]);
  final Object? responseData;
}

/// Error transitorio (sin red, timeout, 5xx, 401, 408, 429): reintentar.
class UploadTransientFailure extends UploadOutcome {
  const UploadTransientFailure(this.reason);
  final String reason;
}

/// Error permanente (4xx de validación, 404...): no reintentar.
class UploadPermanentFailure extends UploadOutcome {
  const UploadPermanentFailure(this.reason);
  final String reason;
}

abstract class SetLogUploader {
  Future<UploadOutcome> upload(PendingSetLog item);
}

/// Envía la serie a `POST /workouts/:id/exercises/:workoutExerciseId/sets`.
///
/// El cuerpo incluye `clientId`, que la API usará como clave de
/// idempotencia en Fase 3 (hasta entonces lo ignora: el schema Zod no es
/// estricto y descarta claves desconocidas).
class ApiSetLogUploader implements SetLogUploader {
  ApiSetLogUploader(this._dio);

  final Dio _dio;

  static String pathFor(PendingSetLog item) =>
      '/workouts/${item.workoutSessionId}/exercises/'
      '${item.workoutExerciseId}/sets';

  static Map<String, dynamic> bodyFor(PendingSetLog item) => {
    'clientId': item.clientId,
    if (item.loadKg != null) 'weightKg': item.loadKg,
    if (item.reps != null) 'reps': item.reps,
    if (item.rir != null) 'rir': item.rir,
    'completed': true,
  };

  @override
  Future<UploadOutcome> upload(PendingSetLog item) async {
    try {
      final response = await _dio.post<dynamic>(
        pathFor(item),
        data: bodyFor(item),
      );
      return UploadSucceeded(response.data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) return UploadDuplicate(e.response?.data);
      if (status == null) {
        return UploadTransientFailure(e.type.name);
      }
      if (status >= 500 || status == 401 || status == 408 || status == 429) {
        return UploadTransientFailure('HTTP $status');
      }
      return UploadPermanentFailure('HTTP $status');
    } catch (e) {
      return UploadTransientFailure(e.runtimeType.toString());
    }
  }
}
