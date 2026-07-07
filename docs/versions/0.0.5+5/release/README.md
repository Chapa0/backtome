# Release 0.0.5+5

## Estado

Release publicado.

Release GitHub:
`https://github.com/Chapa0/backtome/releases/tag/v0.0.5`.

Esta version mejora el flujo principal de objetos perdidos, corrige el arranque
segun el tipo de usuario y agrega una gestion mas clara de actualizaciones.

## Mejoras para usuarios

- Al agregar un objeto perdido, la app ahora muestra los puntos disponibles para
  dejarlo en entrega.
- Las publicaciones indican quien tiene actualmente el objeto: el usuario que lo
  encontro o el punto de entrega donde ya fue recibido.
- Si el objeto ya esta en un punto de entrega, el mapa puede centrar ese punto
  para ubicarlo con mayor claridad.
- La pantalla de Ajustes incluye una seccion de puntos de objetos perdidos.
- Usuarios y administradores ya no dependen de una imagen estatica del mapa para
  conocer puntos de entrega.

## Mejoras para administradores

- Admin puede crear, editar y desactivar puntos de entrega y reclamacion desde
  Ajustes.
- Al aprobar una publicacion, admin puede marcar si el objeto ya fue recibido en
  un punto de entrega.
- Si una publicacion ya estaba aprobada, admin puede registrar posteriormente la
  recepcion del objeto en un punto.
- La home admin vuelve a usar el mapa y el panel de gestion actual para aprobar,
  rechazar y revisar reclamaciones.

## Correcciones de estabilidad

- La app inicia en Login cuando no hay sesion activa y redirige correctamente a
  usuario o admin segun su rol.
- El dialogo global de actualizacion queda disponible aunque el usuario cambie
  de pantalla o inicie sesion.
- Ajustes muestra la informacion de actualizacion de forma mas limpia para el
  usuario final.
