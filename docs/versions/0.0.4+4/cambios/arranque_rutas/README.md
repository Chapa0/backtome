# Arranque y rutas

## Objetivo

Corregir errores de arranque detectados despues del despliegue de `0.0.3+3`.

## Cambios

- `main.dart` espera `setupLocator()` antes de usar dependencias registradas en
  GetIt.
- `MaterialApp` registra `AppRouter.onGenerateRoute` para que
  `Navigator.pushNamed` pueda abrir rutas como Ajustes.
- `BackToMeApp` provee `AppUpdateService` para que `SettingsPage` pueda leer el
  estado de actualizaciones con Provider.
