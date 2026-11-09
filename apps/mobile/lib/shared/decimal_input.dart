/// Números decimales en campos de texto (kg, cm): se muestran con el
/// separador decimal del idioma (`62,5` en castellano) y se aceptan tanto
/// con coma como con punto, porque el teclado numérico de cada sistema trae
/// uno u otro.
library;

import 'package:intl/intl.dart';

/// Texto para un campo: sin decimales si es entero y como mucho
/// [maxDecimals], sin ceros sobrantes ni separador de miles (`1062,5`).
String formatDecimalInput(
  double value,
  String localeName, {
  int maxDecimals = 2,
}) {
  final f = NumberFormat.decimalPattern(localeName)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = maxDecimals
    ..turnOffGrouping();
  return f.format(value);
}

final _decimal = RegExp(r'^([0-9]+([.,][0-9]*)?|[.,][0-9]+)$');

/// Lee lo que escribe la persona: `62,5`, `62.5`, ` 62,5 `, `,5` o `62,`.
/// Devuelve null si no es un número con como mucho un separador decimal
/// (`62,5,0`, `1.062,5`, `abc`, vacío).
double? parseDecimalInput(String raw) {
  final s = raw.trim().replaceAll(' ', '');
  if (s.isEmpty || !_decimal.hasMatch(s)) return null;
  var normalized = s.replaceAll(',', '.');
  if (normalized.startsWith('.')) normalized = '0$normalized';
  if (normalized.endsWith('.')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return double.tryParse(normalized);
}
