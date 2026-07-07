# Checklist de validacion 0.0.5+5

## Pre-commit

- [x] Version `0.0.4+4` marcada como cerrada
- [x] Version activa actualizada a `0.0.5+5`
- [x] Cambios registrados en `docs/versions/0.0.5+5/cambios/`
- [x] Version en `pubspec.yaml` actualizada
- [x] Version Android alineada con la version de Flutter

## Validacion local

- [ ] `flutter analyze` completo sin warnings ni infos
- [x] `flutter test` completo
- [x] `npm test` en `functions/`
- [x] `npm run lint` en `functions/`
- [x] `flutter build apk --release`

## Publicacion

- [x] APK release generado y renombrado
- [x] Release GitHub creado
- [x] APK adjunto al release
- [x] Cloud Functions desplegadas
- [x] Reglas Firestore desplegadas

## Notas de validacion

- `dart analyze` enfocado sobre `main.dart` y `features/app_updates` no reporto
  issues.
- `flutter test` fue ejecutado el 2026-07-06 y paso correctamente.
- Se uso `test-android-apps:android-emulator-qa` con el dispositivo
  `c402509e`.
- Se instalo una build local con `versionCode=3` y `versionName=0.0.3` para
  simular una app anterior frente al release publicado `v0.0.4`.
- Al abrir la app, el dialogo emergente de actualizacion aparecio correctamente
  mostrando version actual `0.0.3+3`, nueva `v0.0.4` y boton `Instalar`.
- Logcat confirmo `APP_UPDATE inicio de chequeo` y
  `APP_UPDATE release seleccionado v0.0.4`.
- Se corrigio una excepcion `LocaleDataException` del dialogo de actualizacion
  eliminando la dependencia de `DateFormat('es_MX')`.
- La pantalla de Ajustes fue verificada con `uiautomator`; ya no muestra logs,
  ultimo chequeo ni metadatos de publicacion del release.
- `flutter test` fue ejecutado nuevamente el 2026-07-07 y paso correctamente.
- `npm test` en `functions/` fue ejecutado el 2026-07-07 y paso con 8 tests.
- `npm run lint` en `functions/` fue ejecutado el 2026-07-07 y paso
  correctamente.
- `flutter analyze` fue ejecutado el 2026-07-07. No reporto errores de
  compilacion; mantiene warnings/infos preexistentes del proyecto.
- Se desplegaron Cloud Functions y reglas Firestore el 2026-07-07 para soportar
  puntos de entrega/reclamacion y recepcion de objetos en punto.
- `flutter build apk --release` fue ejecutado el 2026-07-07 y genero
  `build/app/outputs/flutter-apk/app-release.apk`.
- El APK fue copiado como `build/app/outputs/flutter-apk/0.0.5+5.apk`.
- Release GitHub `v0.0.5` creado el 2026-07-07:
  `https://github.com/Chapa0/backtome/releases/tag/v0.0.5`.
- APK `0.0.5+5.apk` adjunto al release `v0.0.5`.
