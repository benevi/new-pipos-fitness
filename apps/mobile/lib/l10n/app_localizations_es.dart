// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pipos Fitness';

  @override
  String get splashLoading => 'Cargando tu sesión…';

  @override
  String get navHome => 'Inicio';

  @override
  String get navWorkouts => 'Entrenos';

  @override
  String get navNutrition => 'Nutrición';

  @override
  String get navCoach => 'Coach IA';

  @override
  String get navProfile => 'Perfil';

  @override
  String get offlineBanner => 'Sin conexión: mostrando datos guardados';

  @override
  String pendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series pendientes de sincronizar',
      one: '1 serie pendiente de sincronizar',
    );
    return '$_temp0';
  }

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldConfirmPassword => 'Confirmar contraseña';

  @override
  String get validationEmailInvalid => 'Introduce un correo válido';

  @override
  String get validationPasswordRequired => 'Introduce tu contraseña';

  @override
  String validationPasswordTooShort(int min) {
    return 'La contraseña debe tener al menos $min caracteres';
  }

  @override
  String get validationPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginGoToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerSubmit => 'Crear cuenta';

  @override
  String get registerGoToLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authErrorInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'Ya existe una cuenta con este correo.';

  @override
  String get authErrorInvalidInput => 'Revisa los datos introducidos.';

  @override
  String get authErrorSessionExpired =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorNetwork => 'Sin conexión a internet.';

  @override
  String get errorTimeout =>
      'La petición ha tardado demasiado. Inténtalo de nuevo.';

  @override
  String get errorServer => 'Error del servidor. Inténtalo más tarde.';

  @override
  String get errorUnauthorized =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorBadRequest => 'La solicitud no es válida.';

  @override
  String get errorParse => 'El servidor devolvió una respuesta inesperada.';

  @override
  String get errorUnknown => 'Ha ocurrido un error inesperado.';

  @override
  String get configErrorTitle => 'Configuración incompleta';

  @override
  String get configErrorBody =>
      'Esta compilación no define la URL de la API. Vuelve a compilar con --dart-define=API_BASE_URL=https://…';
}
