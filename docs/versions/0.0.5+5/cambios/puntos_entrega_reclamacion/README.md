# Puntos de entrega y reclamacion

## Contexto

El flujo anterior usaba una pantalla con una imagen estatica del mapa para
indicar un punto de entrega. Ese enfoque ya no cubre el proceso real: ahora los
puntos donde se pueden dejar o reclamar objetos deben ser configurables, visibles
en mapa y conectados con el estado del objeto perdido.

## Cambios

- Se agrega la entidad `LostObjectPoint` para representar puntos de entrega,
  reclamacion o ambos.
- Se crea la pantalla `LostObjectPointsPage` para consultar puntos en mapa y
  lista.
- La pantalla de Ajustes agrega la entrada `Puntos de objetos perdidos`.
- El drawer de usuario/admin deja de mostrar la opcion legacy de mapa estatico.
- El alta de objetos perdidos muestra los puntos activos de entrega para orientar
  al usuario antes de guardar.
- `LostObject` agrega campos de custodia actual:
  `custodiaEstado`, `custodiaUid`, `custodiaNombre`, `puntoCustodiaId`,
  `puntoCustodiaNombre`, `puntoCustodiaLatitud`,
  `puntoCustodiaLongitud` y `fechaRecepcionPunto`.
- Al crear un objeto, la custodia inicial queda con el usuario que publico el
  objeto.
- Al aprobar una publicacion, admin puede marcar opcionalmente que el objeto ya
  fue recibido en un punto de entrega.
- Para objetos ya aprobados, admin puede registrar posteriormente la recepcion
  en un punto.
- Las tarjetas y el panel de detalle muestran si el objeto lo tiene el usuario
  que publico o si ya esta en un punto de entrega.
- Los marcadores del mapa usan el punto de custodia cuando el objeto ya esta
  recibido en un punto.

## Backend y reglas

- Se agrega la coleccion `puntos_objetos_perdidos`.
- Se agregan solicitudes backend:
  - `solicitudes_guardar_punto_objeto_perdido`
  - `solicitudes_eliminar_punto_objeto_perdido`
  - `solicitudes_recibir_objeto_en_punto`
- `aprobarObjetoPerdido` acepta `puntoCustodiaId` opcional.
- Las reglas Firestore permiten leer puntos activos a usuarios autenticados y
  puntos inactivos solo a admins.
- Se desplegaron Cloud Functions y reglas Firestore para soportar el flujo.

## Resultado esperado

El sistema ya no depende del mapa estatico. Los puntos se administran desde
Ajustes, los usuarios ven donde pueden entregar objetos perdidos y admin puede
registrar en que punto quedo recibido cada objeto antes de su reclamacion final.
