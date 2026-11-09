import 'dart:convert';
import 'dart:io';

/// Lee un fixture de `test/fixtures/api_v1/` (JSON validado contra los
/// esquemas Zod de la API con `tool/validate_fixtures.mjs`). Devuelve una
/// copia nueva en cada llamada (se puede modificar).
Map<String, dynamic> fixture(String name) {
  final file = File('test/fixtures/api_v1/$name.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}
