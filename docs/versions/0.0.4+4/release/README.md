# Release 0.0.4+4

## Estado

Release publicado.

Release GitHub:
`https://github.com/Chapa0/backtome/releases/tag/v0.0.4`.

Esta version corrige problemas detectados despues del despliegue anterior y
deja la app lista para recibir actualizaciones de forma mas clara.

## Mejoras para usuarios

- La app vuelve a abrir correctamente las pantallas internas como Ajustes desde
  los botones de navegacion.
- La pantalla de Ajustes ya puede mostrar el estado de actualizaciones sin
  errores de Provider.
- Cuando exista una version nueva, la app mostrara un dialogo con la version
  disponible, el progreso de descarga, las notas del release y la accion para
  instalar.
- Si el dispositivo esta conectado a Wi-Fi, la descarga del APK puede quedar
  lista automaticamente para instalarla despues.
- La sesion se limpia correctamente al cerrar sesion, evitando que la app vuelva
  a entrar con el usuario anterior despues de reiniciar.
- Las imagenes internas de la app vuelven a cargar desde los assets correctos.

## Correcciones de estabilidad

- Se corrigio el error de permisos al cargar objetos perdidos para usuarios
  normales y administradores.
- Se corrigio el fallo de rutas desconocidas al tocar opciones del panel.
- Se quitaron dependencias de imagenes externas temporales para evitar errores
  de conexion al cargar avatares.
- Se actualizo la integracion de Firebase para evitar errores de autenticacion
  observados en el APK anterior.
