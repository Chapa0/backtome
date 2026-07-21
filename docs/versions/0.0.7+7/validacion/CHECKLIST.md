# Checklist de validacion 0.0.7+7

## Pre-commit

- [x] Version `0.0.6+6` marcada como cerrada
- [x] Cambios registrados en `docs/versions/0.0.7+7/cambios/`
- [x] Notas para usuario final registradas
- [x] Version en `pubspec.yaml` actualizada a `0.0.7+7`
- [x] Version Android verificada dentro del APK release

## Validacion local

- [x] Analisis dirigido sin errores nuevos
- [x] APK debug Android compilado
- [x] `flutter analyze` completo revisado
- [x] `flutter test` completo
- [x] `flutter build apk --release`

## Publicacion

- [x] APK release generado y renombrado como `0.0.7+7.apk`
- [x] Commit y push realizados
- [x] Release `v0.0.7` creado en GitHub
- [x] APK adjunto y disponible para actualizacion

## Notas de validacion

- El analisis dirigido de los archivos nuevos de mapas finalizo sin problemas.
- `flutter test`: todas las pruebas pasaron.
- `flutter analyze`: sin errores de compilacion; reporta 194 warnings e infos
  acumulados principalmente en pantallas legacy.
- APK: `versionName=0.0.7`, `versionCode=7`, firma APK v2 valida.
- SHA-256: `C5F192FB6A48F6C7D22D8B98B255A6EB94DBA3C3EA41460B6F6A4587BADB0145`.
- Release: `https://github.com/Chapa0/backtome/releases/tag/v0.0.7`.
