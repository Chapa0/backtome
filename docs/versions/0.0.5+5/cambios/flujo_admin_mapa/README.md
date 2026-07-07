# Flujo admin con mapa

## Contexto

El root de autenticacion estaba enviando usuarios admin a `PageAppGeneralAdmin`,
una pantalla vieja de administracion basada en lista. Esa vista no contiene el
mapa ni el `UP_PANEL` que ya usa el flujo actual de admin.

## Cambios

- La ruta root para usuarios autenticados vuelve a usar `PageAppGeneral`.
- La ruta `AppRouter.adminHome` tambien apunta a `PageAppGeneral`.
- Se elimina `admin_home_page.dart` para evitar que el flujo vuelva a usar la
  pantalla vieja.
- Se elimina la copia legacy `lib/views/administradores/AdminHomePage.dart` y
  el login legacy deja de referenciar `PageAppGeneralAdmin`.

## Resultado esperado

El admin entra a la home con mapa y `UP_PANEL`; desde esa misma pantalla conserva
filtros y acciones administrativas para aprobar, rechazar y gestionar
reclamaciones.
