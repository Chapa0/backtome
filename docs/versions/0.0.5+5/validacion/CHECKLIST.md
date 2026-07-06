# Checklist de validacion 0.0.5+5

## Pre-commit

- [x] Version `0.0.4+4` marcada como cerrada
- [x] Version activa actualizada a `0.0.5+5`
- [ ] Cambios registrados en `docs/versions/0.0.5+5/cambios/`
- [ ] Version en `pubspec.yaml` actualizada
- [ ] Version Android alineada con la version de Flutter

## Validacion local

- [ ] `flutter analyze` completo sin warnings ni infos
- [ ] `flutter test` completo
- [ ] `flutter build apk --release`

## Publicacion

- [ ] APK release generado y renombrado
- [ ] Release GitHub creado
- [ ] APK adjunto al release
