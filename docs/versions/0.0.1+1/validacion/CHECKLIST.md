# Checklist de validacion 0.0.1+1

## Pre-commit
- [x] Cambios registrados en `docs/versions/0.0.1+1/cambios/`
- [x] Release redactado en `docs/versions/0.0.1+1/release/README.md`
- [x] Version en `pubspec.yaml` revisada (`0.0.1+1`)

## Validacion local
- [x] `dart analyze` sobre archivos nuevos/tocados del sistema de actualizaciones
- [ ] `flutter analyze` completo sin warnings ni infos
- [ ] `flutter test` completo
- [x] `flutter build apk --debug`
- [x] `flutter build apk --release`

## Configuracion pendiente
- [x] `github_owner` configurado en `assets/local/bootstrap_secrets.json`
- [x] `github_repo` configurado en `assets/local/bootstrap_secrets.json`
- [x] `github_token` configurado si el repo es privado
- [x] Release GitHub no prerelease creado con asset `.apk`
- [ ] Prueba en dispositivo Android real para permiso de instalar apps desconocidas

## Publicacion
- [ ] Commit creado con mensaje descriptivo
- [ ] Push a `main`
- [x] Release creado en GitHub con `gh release create`
- [x] APK adjunto al release

## Notas de validacion

- `dart analyze` de `lib/features/app_updates`,
  `lib/shared/utils/local_bootstrap_secrets_service.dart`,
  `lib/core/di/service_locator.dart`, `lib/app.dart` y
  `lib/core/router/app_router.dart` no reporto issues.
- `flutter build apk --debug` genero
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --release` genero
  `build/app/outputs/flutter-apk/app-release.apk`.
- El APK de release se copio como
  `build/app/outputs/flutter-apk/0.0.1+1.apk`.
- `flutter analyze` completo reporta warnings e infos existentes en el proyecto.
- `flutter test` falla por pruebas existentes de `SessionService` que usan
  FirebaseAuth sin inicializar Firebase.
- La cuenta activa de GitHub CLI es `Chapa0`.
- No existia release `v0.0.1` en `Chapa0/Almeet`; no hubo release de BackToMe
  que borrar en Almeet.
- `assets/local/bootstrap_secrets.json` apunta a `Chapa0/backtome`.
- Release publicado:
  `https://github.com/Chapa0/backtome/releases/tag/v0.0.1`.
- Asset adjunto:
  `backtome-0.0.1-1.apk`.
