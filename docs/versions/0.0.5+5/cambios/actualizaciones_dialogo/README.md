# Dialogo global de actualizacion

## Contexto

El APK `0.0.3+3` no puede mostrar el dialogo de actualizacion porque esa version
publicada no monta `AppUpdateGate` ni provee `AppUpdateService` en `main.dart`.
En la implementacion actual, aunque el gate ya existe, puede perderse despues de
un inicio de sesion porque `login_page.dart` reemplaza la pila con
`PageAppGeneral()` directamente.

## Cambios

- Mantener el gate de actualizaciones a nivel de app para que sobreviva a los
  cambios de ruta.
- Usar un `navigatorKey` para abrir el dialogo sobre la pantalla actual.
- Probar con Android/adb una build local con version anterior frente al release
  publicado en GitHub.
- Simplificar Ajustes para no exponer logs ni estados tecnicos al usuario final.
