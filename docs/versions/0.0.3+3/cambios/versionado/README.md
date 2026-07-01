# Versionado

## Inicio de 0.0.3+3

Se abre la version `0.0.3+3` como version activa del proyecto.

## Alineacion Android

`android/app/build.gradle` deja de usar `versionName "1.0"` y `versionCode 1`
fijos. A partir de esta version lee `pubspec.yaml` como fuente principal para
obtener `versionName` y `versionCode`.

Si `pubspec.yaml` no estuviera disponible durante una ejecucion Gradle directa,
se conserva `android/local.properties` como respaldo.

Esto evita que el sistema de actualizaciones compare contra una version Android
incorrecta.
