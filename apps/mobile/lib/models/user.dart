/// Auth y cuenta (contracts/src/schemas/auth.ts y account.ts).
library;

import 'enums.dart';
import 'json.dart';

/// Usuario de la sesión (lo que devuelve `AuthResponse.user`, y lo que se
/// cachea para el modo offline).
class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  factory AuthUser.fromJson(Json j) =>
      AuthUser(id: j.str('id'), email: j.str('email'));

  Json toJson() => {'id': id, 'email': email};

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// POST /auth/login|register|refresh.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  factory AuthResponse.fromJson(Json j) => AuthResponse(
    accessToken: j.str('accessToken'),
    refreshToken: j.str('refreshToken'),
    expiresIn: j.integer('expiresIn'),
    user: AuthUser.fromJson(j.obj('user')),
  );

  Json toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'user': user.toJson(),
  };
}

/// GET /me.
class MeResponse {
  const MeResponse({
    required this.id,
    required this.email,
    required this.role,
    required this.locale,
    required this.createdAt,
  });

  final String id;
  final String email;
  final Role role;
  final AppLocale locale;
  final DateTime createdAt;

  AuthUser get authUser => AuthUser(id: id, email: email);

  factory MeResponse.fromJson(Json j) => MeResponse(
    id: j.str('id'),
    email: j.str('email'),
    role: j.enumValue('role', Role.values),
    locale: j.enumValue('locale', AppLocale.values),
    createdAt: j.dateTime('createdAt'),
  );

  Json toJson() => {
    'id': id,
    'email': email,
    'role': role.wire,
    'locale': locale.wire,
    'createdAt': isoUtc(createdAt),
  };
}
