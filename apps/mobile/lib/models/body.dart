/// Medidas corporales y su evolución (contracts/src/schemas/body.ts y
/// engine-v2/body.ts). DATOS DE SALUD (RGPD art. 9; ADR-0011, ADR-0013).
/// Nada de esto es un diagnóstico.
library;

import 'enums.dart';
import 'json.dart';

/// PUT /me/measurements (y la medida guardada que devuelve la API).
class BodyMeasurement {
  const BodyMeasurement({required this.measuredOn, required this.values});

  /// Fecha local `YYYY-MM-DD`.
  final String measuredOn;

  /// Valores por campo; un campo ausente es null en el cable.
  final Map<BodyField, double> values;

  double? operator [](BodyField f) => values[f];

  bool get isEmpty => values.isEmpty;

  /// Campos de perímetro (requieren el ámbito `body_measurements`).
  bool get hasCircumferences => values.keys.any((f) => f != BodyField.weightKg);

  static Map<BodyField, double> _read(Json j) => {
    for (final f in BodyField.values)
      if (j.numOrNull(f.wire) != null) f: j.number(f.wire),
  };

  factory BodyMeasurement.fromJson(Json j) =>
      BodyMeasurement(measuredOn: j.str('measuredOn'), values: _read(j));

  /// Cuerpo de `PUT /me/measurements`.
  Json toJson() => {
    'measuredOn': measuredOn,
    for (final f in BodyField.values)
      f.wire: values[f] == null ? null : jsonNum(values[f]!),
  };
}

/// Medida guardada (respuesta de la API).
class BodyMeasurementRecord {
  const BodyMeasurementRecord({
    required this.measurement,
    required this.updatedAt,
  });

  final BodyMeasurement measurement;
  final DateTime updatedAt;

  factory BodyMeasurementRecord.fromJson(Json j) => BodyMeasurementRecord(
    measurement: BodyMeasurement.fromJson(j),
    updatedAt: j.dateTime('updatedAt'),
  );

  Json toJson() => {...measurement.toJson(), 'updatedAt': isoUtc(updatedAt)};
}

class BodyMeasurementList {
  const BodyMeasurementList(this.items);

  final List<BodyMeasurementRecord> items;

  factory BodyMeasurementList.fromJson(Json j) =>
      BodyMeasurementList(j.objList('items', BodyMeasurementRecord.fromJson));

  Json toJson() => {'items': items.map((m) => m.toJson()).toList()};
}

class DatedValue {
  const DatedValue(this.date, this.value);

  final String date;
  final double value;

  factory DatedValue.fromJson(Json j, String valueKey) =>
      DatedValue(j.str('date'), j.number(valueKey));

  Json toJson(String valueKey) => {'date': date, valueKey: jsonNum(value)};
}

class WeightTarget {
  const WeightTarget({
    required this.direction,
    required this.minPct,
    required this.maxPct,
  });

  /// `loss` o `gain`.
  final String direction;
  final double minPct;
  final double maxPct;

  factory WeightTarget.fromJson(Json j) {
    final d = j.str('direction');
    if (d != 'loss' && d != 'gain') {
      throw FormatException('Valor no válido para direction: $d');
    }
    return WeightTarget(
      direction: d,
      minPct: j.number('minPct'),
      maxPct: j.number('maxPct'),
    );
  }

  Json toJson() => {
    'direction': direction,
    'minPct': jsonNum(minPct),
    'maxPct': jsonNum(maxPct),
  };
}

class WeightTrend {
  const WeightTrend({
    required this.status,
    required this.weeklyRatePct,
    required this.target,
    required this.movingAverage,
    required this.spanDays,
    required this.rationale,
  });

  final WeightTrendStatus status;
  final double? weeklyRatePct;
  final WeightTarget? target;

  /// Media móvil de 7 días en cada fecha con peso.
  final List<DatedValue> movingAverage;
  final int spanDays;
  final List<String> rationale;

  factory WeightTrend.fromJson(Json j) => WeightTrend(
    status: j.enumValue('status', WeightTrendStatus.values),
    weeklyRatePct: j.numOrNull('weeklyRatePct'),
    target: j.objOrNull('target') == null
        ? null
        : WeightTarget.fromJson(j.obj('target')),
    movingAverage: j.objList(
      'movingAverage',
      (i) => DatedValue.fromJson(i, 'kg'),
    ),
    spanDays: j.integer('spanDays'),
    rationale: j.strList('rationale'),
  );

  Json toJson() => {
    'status': status.wire,
    'weeklyRatePct': weeklyRatePct == null ? null : jsonNum(weeklyRatePct!),
    'target': target?.toJson(),
    'movingAverage': movingAverage.map((p) => p.toJson('kg')).toList(),
    'spanDays': spanDays,
    'rationale': rationale,
  };
}

class BmiResult {
  const BmiResult({
    required this.status,
    required this.value,
    required this.category,
    required this.categoryEs,
    required this.caveats,
  });

  /// `ok` o `invalid_input`.
  final String status;
  final double? value;
  final BmiCategory? category;
  final String? categoryEs;
  final List<String> caveats;

  factory BmiResult.fromJson(Json j) => BmiResult(
    status: j.str('status'),
    value: j.numOrNull('value'),
    category: j.enumOrNull('category', BmiCategory.values),
    categoryEs: j.strOrNull('categoryEs'),
    caveats: j.strList('caveats'),
  );

  Json toJson() => {
    'status': status,
    'value': value == null ? null : jsonNum(value!),
    'category': category?.wire,
    'categoryEs': categoryEs,
    'caveats': caveats,
  };
}

class BodyFatResult {
  const BodyFatResult({
    required this.status,
    required this.percent,
    required this.method,
    required this.issues,
    required this.caveats,
  });

  final EstimateStatus status;
  final double? percent;
  final String method;
  final List<String> issues;
  final List<String> caveats;

  factory BodyFatResult.fromJson(Json j) => BodyFatResult(
    status: j.enumValue('status', EstimateStatus.values),
    percent: j.numOrNull('percent'),
    method: j.str('method'),
    issues: j.strList('issues'),
    caveats: j.strList('caveats'),
  );

  Json toJson() => {
    'status': status.wire,
    'percent': percent == null ? null : jsonNum(percent!),
    'method': method,
    'issues': issues,
    'caveats': caveats,
  };
}

class BmiBlock {
  const BmiBlock({
    required this.status,
    required this.measuredOn,
    required this.result,
    required this.series,
  });

  final EstimateStatus status;
  final String? measuredOn;
  final BmiResult? result;
  final List<DatedValue> series;

  factory BmiBlock.fromJson(Json j) => BmiBlock(
    status: j.enumValue('status', EstimateStatus.values),
    measuredOn: j.strOrNull('measuredOn'),
    result: j.objOrNull('result') == null
        ? null
        : BmiResult.fromJson(j.obj('result')),
    series: j.objList('series', (i) => DatedValue.fromJson(i, 'value')),
  );

  Json toJson() => {
    'status': status.wire,
    'measuredOn': measuredOn,
    'result': result?.toJson(),
    'series': series.map((p) => p.toJson('value')).toList(),
  };
}

class BodyFatBlock {
  const BodyFatBlock({
    required this.status,
    required this.measuredOn,
    required this.result,
    required this.series,
  });

  final EstimateStatus status;
  final String? measuredOn;
  final BodyFatResult? result;
  final List<DatedValue> series;

  factory BodyFatBlock.fromJson(Json j) => BodyFatBlock(
    status: j.enumValue('status', EstimateStatus.values),
    measuredOn: j.strOrNull('measuredOn'),
    result: j.objOrNull('result') == null
        ? null
        : BodyFatResult.fromJson(j.obj('result')),
    series: j.objList('series', (i) => DatedValue.fromJson(i, 'percent')),
  );

  Json toJson() => {
    'status': status.wire,
    'measuredOn': measuredOn,
    'result': result?.toJson(),
    'series': series.map((p) => p.toJson('percent')).toList(),
  };
}

class CircumferenceTrend {
  const CircumferenceTrend({
    required this.field,
    required this.latest,
    required this.change4w,
    required this.change12w,
  });

  final BodyField field;
  final DatedValue? latest;
  final double? change4w;
  final double? change12w;

  factory CircumferenceTrend.fromJson(Json j) {
    final field = j.enumValue('field', BodyField.values);
    if (field == BodyField.weightKg) {
      throw const FormatException('weightKg no es un perímetro');
    }
    return CircumferenceTrend(
      field: field,
      latest: j.objOrNull('latest') == null
          ? null
          : DatedValue.fromJson(j.obj('latest'), 'value'),
      change4w: j.numOrNull('change4w'),
      change12w: j.numOrNull('change12w'),
    );
  }

  Json toJson() => {
    'field': field.wire,
    'latest': latest?.toJson('value'),
    'change4w': change4w == null ? null : jsonNum(change4w!),
    'change12w': change12w == null ? null : jsonNum(change12w!),
  };
}

/// GET /progress/body.
class BodyProgress {
  const BodyProgress({
    required this.timezone,
    required this.latestWeight,
    required this.trend,
    required this.bmi,
    required this.bodyFat,
    required this.circumferences,
    required this.disclaimer,
  });

  final String timezone;
  final DatedValue? latestWeight;
  final WeightTrend trend;
  final BmiBlock bmi;
  final BodyFatBlock bodyFat;
  final List<CircumferenceTrend> circumferences;
  final String disclaimer;

  bool get isEmpty =>
      latestWeight == null && circumferences.every((c) => c.latest == null);

  factory BodyProgress.fromJson(Json j) {
    final weight = j.obj('weight');
    return BodyProgress(
      timezone: j.str('timezone'),
      latestWeight: weight.objOrNull('latest') == null
          ? null
          : DatedValue.fromJson(weight.obj('latest'), 'value'),
      trend: WeightTrend.fromJson(weight.obj('trend')),
      bmi: BmiBlock.fromJson(j.obj('bmi')),
      bodyFat: BodyFatBlock.fromJson(j.obj('bodyFat')),
      circumferences: j.objList('circumferences', CircumferenceTrend.fromJson),
      disclaimer: j.str('disclaimer'),
    );
  }

  Json toJson() => {
    'timezone': timezone,
    'weight': {
      'latest': latestWeight?.toJson('value'),
      'trend': trend.toJson(),
    },
    'bmi': bmi.toJson(),
    'bodyFat': bodyFat.toJson(),
    'circumferences': circumferences.map((c) => c.toJson()).toList(),
    'disclaimer': disclaimer,
  };
}
