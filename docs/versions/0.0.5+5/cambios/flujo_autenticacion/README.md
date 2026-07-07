# Flujo de autenticacion

## Contexto

Al limpiar los datos de la app, el arranque mostraba directamente la pantalla de
usuario aunque no hubiera sesion restaurada. Eso impedia validar correctamente
el login y dejaba accesible parte del flujo sin autenticacion.

## Cambios

- El widget raiz decide entre Login, Admin y Usuario segun `AuthState`.
- El login deja de forzar siempre `PageAppGeneral()` despues de autenticar.
- El usuario administrador debe entrar a la pantalla admin y el usuario normal a
  la pantalla de usuario.

- Registro y cierre de sesion vuelven a la ruta raiz en vez de reemplazar el stack con PageLogin, para que el enrutamiento por AuthState siga activo.
