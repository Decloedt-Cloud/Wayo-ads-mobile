# wayoadsgo

Wayo Ads Go — Flutter client for Auth_Wayo and related APIs.

## Configuration

Copy `dart_defines.example.json` to `dart_defines.json` (tracked locally, not committed with secrets) and run:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

**Android emulator + Laravel sur le PC** : mets l’URL d’API en `http://10.0.2.2:8000` (pas `localhost`). Voir `SECURITY.md`.

See `SECURITY.md` for TLS pinning, Sentry symbol upload, and scrubbed fields.

## Release builds (obfuscation)

Production values should live in `dart_defines.prod.json` (not committed with real secrets). From Git Bash on Windows or any Unix shell:

```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh
```

This runs `flutter build apk` and `flutter build ipa` with `--obfuscate` and `--split-debug-info=build/symbols`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
