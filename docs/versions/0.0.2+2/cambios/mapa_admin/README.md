# Mapa admin

## Cambios incluidos

- Los administradores entran a la misma vista de mapa que los usuarios.
- El mapa admin muestra objetos pendientes, aprobados, reclamados y entregados.
- Se agregaron filtros admin dentro del panel inferior.
- Se agrego accion para aprobar publicaciones pendientes desde el panel.
- El detalle admin permite abrir la gestion existente para reclamaciones y
  entrega de objetos.
- La gestion de reclamaciones y entrega ahora se muestra directamente en el
  panel inferior al seleccionar un objeto como admin. Antes habia que tocar
  un boton que abria una pagina separada. Ahora la lista de reclamantes, los
  botones de entrega, el dialogo de detalles de reclamacion y la confirmacion
  de entrega estan integrados en el mismo panel, sin salir de la vista del
  mapa.
- Se agrego la accion de rechazar publicaciones pendientes desde el panel,
  las cards del listado y la pagina de detalle admin.
- Se agrego el filtro "Rechazados" al panel admin para listar publicaciones
  rechazadas.
- Las publicaciones rechazadas muestran un badge naranja de "Rechazado" en
  las cards y en la pagina de detalle.
- Los usuarios normales no ven publicaciones rechazadas en su lista ni mapa.
- Se agrego el campo `rechazado` al modelo `LostObject` para distinguir entre
  pendiente y rechazado.
- Se agrego el endpoint `rechazarObjeto` en `SolicitudBackendService` bajo
  la coleccion `solicitudes_rechazar_objeto`.
- El endpoint `rechazarObjeto` requiere una cloud function en
  `solicitudes_rechazar_objeto` que marque `rechazado: true` en el documento.
- El `FilterLostObjectsUseCase` excluye objetos rechazados para usuarios
  no admin.
- Se unificaron los badges de estado de aprobacion en las cards: todos los
  objetos muestran un badge "Pendiente" (naranja), "Aprobado" (verde) o
  "Rechazado" (rojo) visible para todos los usuarios. Antes solo los dueños
  veian el icono de aprobacion, lo que causaba que muchos objetos no
  mostraran ningun indicador.
- Se eliminaron los botones de aprobar/rechazar de las cards del listado.
  Esas acciones solo se realizan desde el panel de detalle, evitando
  aprobaciones o rechazos accidentales al navegar la lista.
- Se agregaron dialogos de confirmacion para las acciones de aprobar y
  rechazar publicaciones. Ambos piden confirmacion explicita antes de
  ejecutar la accion.
- Se elimino la clase `ApprovalInfoOverlay` y el metodo `_showApprovalInfo`
  que eran usados por el antiguo sistema de iconos por dueño.
- Se corrigio que los marcadores del mapa tardaban en aparecer o no aparecian
  hasta despues de varios gestos. El problema era que
  `_initAnnotationManagers()` no se esperaba con `await` antes de llamar
  `_renderMarkers()`, por lo que el `CircleAnnotationManager` aun no estaba
  listo y el renderizado se saltaba silenciosamente.
- Se corrigio que la camara del mapa se reposicionaba cada vez que se realizaba
  una accion (buscar, filtrar, abrir o cerrar el panel). `_fitCameraToMarkers()`
  se llamaba desde `_setupLostObjectsListener()` y `_applyAdminStatusFilter()`,
  lo que forzaba la vista a encuadrar todos los marcadores en cada cambio de
  datos. Ahora solo se llama en la carga inicial del mapa, y la camara se
  mantiene donde el usuario la dejo.
- El marcador del objeto seleccionado en el mapa ahora se distingue visualmente
  del resto: radio mas grande (16 vs 10), borde blanco grueso (4px vs 2px) y
  mayor prioridad de renderizado. Al seleccionar o deseleccionar un objeto,
  los marcadores se re-renderizan para reflejar el cambio.
- Se corrigio que los botones de aprobar/rechazar seguian visibles en el panel
  de detalle despues de rechazar una publicacion. Ahora se ocultan al quedar
  el objeto en estado rechazado.
- Se desplego la Cloud Function `rechazarObjetoPerdido` que procesa la
  coleccion `solicitudes_rechazar_objeto`.
- Se desplegaron las reglas de Firestore que autorizan la escritura en
  `solicitudes_rechazar_objeto` para usuarios autenticados.

## Resultado esperado

Un usuario con `tipoUsuario: admin` puede administrar objetos desde el mapa sin
perder la vista geografica que tiene el usuario normal. Puede aprobar, rechazar
y eliminar publicaciones. Las publicaciones rechazadas quedan visibles para
admins con un filtro dedicado, pero ocultas para usuarios normales.

Los marcadores en el mapa aparecen inmediatamente al cargar los objetos, sin
necesidad de esperar gestos adicionales.

La camara del mapa se mantiene fija en la posicion que el usuario eligio al
navegar, buscar, filtrar o realizar cualquier otra accion. Solo se ajusta al
inicio en la carga inicial.

La gestion completa de administracion (aprobar, rechazar, revisar reclamantes,
entregar objetos) se realiza dentro del panel inferior sin necesidad de navegar
a paginas separadas. Las acciones de aprobar y rechazar requieren confirmacion
explicita.

Todas las cards muestran un badge de estado de aprobacion (Pendiente, Aprobado
o Rechazado) visible para cualquier usuario, sin importar quien publico el
objeto.

Al seleccionar un objeto en el panel, su marcador en el mapa se agranda y
muestra un anillo blanco para identificarlo visualmente entre los demas.
