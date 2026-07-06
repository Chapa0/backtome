# Checklist de validacion 0.0.4+4

## Pre-commit

- [x] Version `0.0.3+3` marcada como cerrada
- [x] Version activa actualizada a `0.0.4+4`
- [x] Cambios registrados en `docs/versions/0.0.4+4/cambios/`
- [x] Version en `pubspec.yaml` actualizada
- [x] Version Android alineada con la version de Flutter

## Validacion local

- [ ] `flutter analyze` completo sin warnings ni infos
- [x] `flutter test` completo
- [x] `flutter build apk --release`

## Publicacion

- [x] APK release generado y renombrado
- [x] Release GitHub creado
- [x] APK adjunto al release

## Notas de validacion

- El usuario confirmo la publicacion de `0.0.4+4`.
- `flutter analyze` completo fue ejecutado el 2026-07-06 y termino con 233
  issues entre warnings e infos heredados del proyecto; no queda como validacion
  limpia.
- `dart analyze` enfocado sobre los archivos tocados en el sistema de
  actualizaciones no reporto issues.
- `flutter test` fue ejecutado el 2026-07-06 y paso correctamente.
- `flutter build apk --release` fue ejecutado el 2026-07-06 y genero
  `build/app/outputs/flutter-apk/app-release.apk`.
- El APK release fue copiado a
  `build/app/outputs/flutter-apk/0.0.4+4.apk`.
- `aapt dump badging` confirmo `versionCode='4'` y `versionName='0.0.4'`.
- El APK empaqueta `assets/local/bootstrap_secrets.json` para funcionamiento en
  runtime, pero ese archivo local no debe subirse al repositorio.
- `firebase deploy --only firestore:rules --project back-to-me-48f22` fue
  ejecutado el 2026-07-06 y publico las reglas correctamente.
- Release publicado en GitHub:
  `https://github.com/Chapa0/backtome/releases/tag/v0.0.4`.
- Asset adjunto al release: `0.0.4+4.apk`.
