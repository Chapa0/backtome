# 0.0.1+1

## Estado

Version cerrada. Queda como referencia historica.

## Objetivo

Estandarizar el sistema de actualizaciones Android de BackToMe tomando como
base el flujo documental usado en Almeet. Esta version deja instalada la base
operativa para consultar releases de GitHub, descargar APKs e iniciar la
instalacion desde la app.

## Areas de cambio

| Area | Descripcion |
|---|---|
| actualizaciones_android | Servicio de actualizaciones Android, dialogo in-app, pantalla de ajustes, descarga e instalacion de APK |
| docs | Estructura `docs/versions/` y primera version documentada |

## Notas de alcance

- Esta version aun no debe subirse a GitHub Releases.
- El sistema queda listo para probar cuando se configuren `github_owner`,
  `github_repo` y, si aplica, `github_token` en
  `assets/local/bootstrap_secrets.json`.
- La app conserva la version actual `0.0.1+1` declarada en `pubspec.yaml`.
