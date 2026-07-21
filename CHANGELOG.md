# Historial de versiones

## 0.0.7+7 - progreso de acciones y mapas de recolección

### Acciones con tiempo de espera

- Las operaciones que dependen del backend muestran una pantalla de carga que
  bloquea la interacción y la navegación hacia atrás hasta terminar.
- La retroalimentación se aplica a aprobación, rechazo, recepción, entrega y
  eliminación de objetos; administración de puntos; eliminación de usuarios y
  acciones importantes de la cuenta.

### Ubicaciones útiles para el usuario

- La pantalla de ubicación ahora muestra un mapa interactivo en lugar de las
  coordenadas del objeto.
- El mapa distingue el lugar donde se encontró el objeto del punto donde puede
  recogerse y encuadra ambas ubicaciones cuando están disponibles.

### Identidad de puntos de entrega

- Los objetos perdidos conservan sus marcadores circulares en el lugar del
  hallazgo, incluso cuando están bajo custodia de un punto de entrega.
- Los puntos de entrega usan un marcador turquesa con forma de pin e icono de
  establecimiento, y el punto del objeto seleccionado se resalta en ámbar.

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
