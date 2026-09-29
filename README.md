# Jobmate

Flutter client for the Jobmate work marketplace (workers, work givers, admin console).

## Run

```sh
flutter pub get
flutter run
```

The backend address is `ApiConfig.baseUrl` in `lib/core/constants/app_config.dart`.
Android emulator: use `http://10.0.2.2:5234`.
The backend API contract is in `swagger.json`.

Plain `http://` is only allowed in debug builds; release builds need an HTTPS backend.

## Test

```sh
flutter analyze
flutter test
```

Tests run against in-memory fakes in `test/support/`, no backend needed.
