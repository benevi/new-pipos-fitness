# Pipos Fitness Mobile

Flutter application for the Pipos Fitness platform.

## Setup

```bash
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run
```

## Configure API URL

```bash
flutter run --dart-define=API_BASE_URL=http://your-api:3000
```

Default: `http://10.0.2.2:3000` (Android emulator → host localhost).
