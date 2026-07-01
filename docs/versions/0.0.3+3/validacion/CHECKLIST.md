# Checklist de validacion 0.0.3+3

## Pre-commit

- [x] Version `0.0.2+2` marcada como cerrada
- [x] Version activa actualizada a `0.0.3+3`
- [x] Cambios registrados en `docs/versions/0.0.3+3/cambios/`
- [x] Version en `pubspec.yaml` actualizada (`0.0.3+3`)
- [x] Version Android alineada con la version de Flutter

## Validacion local

- [ ] `flutter analyze` completo sin warnings ni infos
- [x] `flutter test` completo
- [x] `flutter build apk --debug`
- [x] `flutter build apk --release`

## Publicacion

- [x] APK release generado y renombrado como `0.0.3+3.apk`
- [x] Release GitHub `v0.0.3` creado
- [x] APK adjunto al release

## Notas de validacion

- El usuario confirmo la publicacion de `v0.0.3`.
- El sistema de actualizaciones compara tags semanticos de GitHub; al publicar
  `v0.0.3`, los usuarios de `0.0.2+2` podran recibir la nueva actualizacion.
- `flutter build apk --debug` genero
  `build/app/outputs/flutter-apk/app-debug.apk`.
- El APK debug fue inspeccionado con `aapt` y reporto `versionCode='3'` y
  `versionName='0.0.3'`.
- Despues de integrar el visor de imagenes, `flutter build apk --debug`
  compilo correctamente.
- `dart analyze lib/shared/widgets/image_viewer_dialog.dart` no reporto issues.
- `dart analyze` enfocado sobre los archivos tocados no reporto errores; sigue
  reportando warnings e infos existentes en esas pantallas.
- La version queda documentada como recuperacion despues de una mezcla
  accidental provocada por un pull desde una version anterior hacia la rama
  principal.
- `flutter analyze` completo fue ejecutado el 2026-07-01 y termino con 235
  issues entre warnings e infos existentes; no queda como validacion limpia.
- `flutter test` fue ejecutado el 2026-07-01 y paso correctamente.
- Las pruebas de Cloud Functions (`npm test` en `functions/`) fueron ejecutadas
  el 2026-07-01 y pasaron 6/6.
- `flutter build apk --release` fue ejecutado el 2026-07-01 y genero
  `build/app/outputs/flutter-apk/app-release.apk`.
- El APK release fue copiado a
  `build/app/outputs/flutter-apk/0.0.3+3.apk`.
- `aapt dump badging` confirmo `versionCode='3'` y `versionName='0.0.3'`.
- El asset `bootstrap_secrets.json` empaquetado no contiene token de GitHub ni
  token de Mapbox; el repositorio de releases es publico y se consulta con
  owner/repo.
- GitHub Push Protection bloqueo un intento de push porque el asset local tenia
  un token de Mapbox. Se retiro el token del commit y se regenero el APK.
- Release publicado en GitHub:
  `https://github.com/Chapa0/backtome/releases/tag/v0.0.3`.
- Asset adjunto al release: `0.0.3+3.apk`.
