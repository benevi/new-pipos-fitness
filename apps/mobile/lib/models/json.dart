/// Lectura estricta de JSON para los DTOs de la API v1.
///
/// Los DTOs se escriben a mano (no hay generador de OpenAPI → Dart que
/// funcione sin red y produzca código idiomático) y replican 1:1 los
/// esquemas Zod de `packages/contracts/src/schemas`. Cualquier campo
/// obligatorio ausente o con tipo incorrecto lanza [FormatException], que
/// `ApiFailure.from` convierte en `ApiFailureType.parse`.
///
/// El test de contrato (`test/contract/contract_fixtures_test.dart`) parsea
/// los fixtures de `test/fixtures/api_v1/` y comprueba que `toJson()`
/// reproduce exactamente el JSON original: si la API añade, quita o renombra
/// un campo, el test falla.
library;

typedef Json = Map<String, dynamic>;

/// Enum con su valor de cable (snake_case de la API).
abstract interface class WireEnum {
  String get wire;
}

E parseEnum<E extends WireEnum>(List<E> values, Object? raw, String field) {
  if (raw is String) {
    for (final v in values) {
      if (v.wire == raw) return v;
    }
  }
  throw FormatException('Valor no válido para $field: $raw');
}

extension JsonRead on Json {
  Object? _need(String key) {
    if (!containsKey(key)) throw FormatException('Falta el campo "$key"');
    return this[key];
  }

  String str(String key) {
    final v = _need(key);
    if (v is String) return v;
    throw FormatException('"$key" debe ser texto');
  }

  String? strOrNull(String key) {
    final v = _need(key);
    if (v == null || v is String) return v as String?;
    throw FormatException('"$key" debe ser texto o null');
  }

  int integer(String key) {
    final v = _need(key);
    if (v is int) return v;
    if (v is num && v == v.roundToDouble()) return v.toInt();
    throw FormatException('"$key" debe ser entero');
  }

  int? intOrNull(String key) => _need(key) == null ? null : integer(key);

  double number(String key) {
    final v = _need(key);
    if (v is num) return v.toDouble();
    throw FormatException('"$key" debe ser numérico');
  }

  double? numOrNull(String key) => _need(key) == null ? null : number(key);

  bool boolean(String key) {
    final v = _need(key);
    if (v is bool) return v;
    throw FormatException('"$key" debe ser booleano');
  }

  Json obj(String key) {
    final v = _need(key);
    if (v is Map) return v.cast<String, dynamic>();
    throw FormatException('"$key" debe ser un objeto');
  }

  Json? objOrNull(String key) => _need(key) == null ? null : obj(key);

  List<T> list<T>(String key, T Function(Object? item) read) {
    final v = _need(key);
    if (v is List) return List.unmodifiable(v.map(read));
    throw FormatException('"$key" debe ser una lista');
  }

  List<T> objList<T>(String key, T Function(Json item) read) => list(key, (i) {
    if (i is Map) return read(i.cast<String, dynamic>());
    throw FormatException('Elemento de "$key" no es un objeto');
  });

  List<String> strList(String key) => list(key, (i) {
    if (i is String) return i;
    throw FormatException('Elemento de "$key" no es texto');
  });

  List<E> enumList<E extends WireEnum>(String key, List<E> values) =>
      list(key, (i) => parseEnum(values, i, key));

  E enumValue<E extends WireEnum>(String key, List<E> values) =>
      parseEnum(values, _need(key), key);

  E? enumOrNull<E extends WireEnum>(String key, List<E> values) =>
      _need(key) == null ? null : enumValue(key, values);

  DateTime dateTime(String key) {
    final s = str(key);
    final d = DateTime.tryParse(s);
    if (d == null) throw FormatException('"$key" no es una fecha ISO');
    return d;
  }

  DateTime? dateTimeOrNull(String key) =>
      _need(key) == null ? null : dateTime(key);
}

/// Serializa un instante como lo hace `Date.prototype.toISOString`
/// (UTC, milisegundos, sufijo `Z`).
String isoUtc(DateTime d) => d.toUtc().toIso8601String().replaceFirstMapped(
  RegExp(r'\.(\d{3})\d*Z$'),
  (m) => '.${m[1]}Z',
);

/// Número tal como lo escribiría JSON.stringify (entero sin `.0`).
num jsonNum(double v) =>
    v == v.roundToDouble() && v.abs() < 1e15 ? v.toInt() : v;

List<String> wires(Iterable<WireEnum> values) =>
    values.map((e) => e.wire).toList();
