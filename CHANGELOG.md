# Historial de versiones

## 0.0.6+6 - sincronización y seguridad de objetos perdidos

### Sincronización en tiempo real

- Las listas de objetos perdidos se actualizan automáticamente para usuarios y
  administradores cuando se crea, aprueba, entrega o modifica una publicación.
- La pantalla abierta de un objeto se mantiene alineada con su estado más reciente.

### Reclamaciones

- Al reclamar un objeto, la pantalla de detalle se actualiza de inmediato y evita
  que el mismo usuario pueda reclamarlo de nuevo.
- Se muestra claramente que el objeto fue reclamado por el usuario actual, junto
  con la hora de la reclamación y su estado.

### Integridad de objetos entregados

- Un objeto ya recibido en un punto de entrega, con una reclamación pendiente o
  ya entregado no puede eliminarse desde la app.
- La misma regla se aplica en el backend para impedir eliminaciones directas por
  parte de usuarios o administradores.

### Ubicación al publicar

- Al agregar un objeto perdido, el mapa ya no muestra buscador.
- La ubicación se selecciona manteniendo pulsado el mapa; el botón flotante de
  confirmación aparece solo después de elegir un punto.
