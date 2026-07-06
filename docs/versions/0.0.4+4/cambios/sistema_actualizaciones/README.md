# Sistema de actualizaciones

## Contexto

La implementacion anterior dejaba la revision de releases concentrada en el
servicio y en la pantalla de ajustes. Eso permitia consultar manualmente, pero
no garantizaba que el usuario viera un dialogo cuando existia una version nueva.

## Cambio

- Se toma como referencia el flujo de `C:\Users\chapa\Documents\almeet`.
- La app debe revisar actualizaciones al iniciar sesion cualquier tipo de usuario.
- El sistema debe descargar automaticamente si hay Wi-Fi y mantener visible el
  estado de descarga.
- Si el APK ya esta descargado, el dialogo debe ofrecer instalarlo.
- El dialogo debe mostrar version actual, version nueva, fecha, progreso,
  errores y notas del release.
- La revision periodica queda dentro del servicio, no en pantallas puntuales.

## Criterio arquitectonico

La logica de red, persistencia, descarga e instalacion permanece en
`features/app_updates/data/services`. La capa de presentacion solo coordina
cuando mostrar el dialogo y que accion pedir al servicio.
