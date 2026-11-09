// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pipos Fitness';

  @override
  String get splashLoading => 'Loading your session…';

  @override
  String get navHome => 'Home';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navNutrition => 'Nutrition';

  @override
  String get navCoach => 'AI Coach';

  @override
  String get navProfile => 'Profile';

  @override
  String get offlineBanner => 'Offline: showing saved data';

  @override
  String pendingSyncCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets waiting to sync',
      one: '1 set waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get validationEmailInvalid => 'Enter a valid email';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String validationPasswordTooShort(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get validationPasswordsDontMatch => 'Passwords do not match';

  @override
  String get loginSubmit => 'Log in';

  @override
  String get loginGoToRegister => 'Don\'t have an account? Sign up';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerGoToLogin => 'Already have an account? Log in';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailAlreadyRegistered =>
      'An account with this email already exists.';

  @override
  String get authErrorInvalidInput => 'Please check the data you entered.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorNetwork => 'No internet connection.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please log in again.';

  @override
  String get errorBadRequest => 'The request is not valid.';

  @override
  String get errorParse => 'The server returned an unexpected response.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get configErrorTitle => 'Incomplete configuration';

  @override
  String get configErrorBody =>
      'This build does not define the API URL. Rebuild with --dart-define=API_BASE_URL=https://…';
}
