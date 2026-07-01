# Recuperacion despues de mezcla accidental

## Contexto

Durante la preparacion de esta entrega hubo un problema al hacer pull desde una
version anterior. Ese pull mezclo codigo de una version previa con la rama
principal y dejo el proyecto en un estado inconsistente para continuar el
release.

## Resolucion

Se reviso la rama principal, se recuperaron los cambios necesarios y se volvio a
alinear la version activa con `0.0.3+3`.

La recuperacion dejo resueltos estos puntos:

- La rama principal vuelve a representar la base valida del proyecto.
- `pubspec.yaml` declara `version: 0.0.3+3`.
- Android toma `versionName` y `versionCode` desde `pubspec.yaml`.
- La documentacion de versiones vuelve a apuntar a `0.0.3+3` como entrega
  activa para publicar.

## Estado

El incidente queda documentado como referencia historica. El proyecto queda
habilitado para desplegar la version 3.
