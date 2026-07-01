# Checklist de validacion 0.0.2+2

## Pre-commit

- [x] Cambios registrados en `docs/versions/0.0.2+2/cambios/`
- [x] Release redactado en `docs/versions/0.0.2+2/release/README.md`
- [x] Version en `pubspec.yaml` revisada (`0.0.2+2`)

## Validacion local

- [x] `dart analyze` enfocado sobre archivos de autenticacion tocados
- [x] `flutter build apk --debug`
- [x] Prueba Android del panel inferior con `adb` y logs `[UP_PANEL]`
- [x] Pruebas unitarias de Cloud Functions para logica de objetos perdidos
- [ ] Validar manualmente que la agarradera quede visible con el panel completo
- [ ] Validar manualmente que arrastrar hacia abajo desde el inicio de la lista cierre el panel
- [ ] Validar que la barra de busqueda abre el panel completo al presionar el boton
- [ ] Validar que el calendario abre el panel completo al presionar el boton
- [ ] Validar que el teclado no empuja el panel al escribir en la busqueda
- [ ] Validar que los marcadores del mapa cargan al mismo tiempo que la lista
- [ ] Validar que la camara del mapa se mantiene fija al buscar, filtrar, aprobar o rechazar
- [ ] Validar que la camara del mapa se mantiene fija al abrir y cerrar el panel
- [ ] Validar que la camara del mapa solo se ajusta al entrar por primera vez al mapa
- [ ] Validar que rechazar una publicacion muestra el badge naranja y la oculta a usuarios normales
- [ ] Validar que el filtro "Rechazados" lista publicaciones rechazadas en admin
- [ ] Validar que aprobar y rechazar funcionan desde el panel, las cards y la pagina de detalle admin
- [ ] Validar que todas las cards muestran el badge de aprobacion (Pendiente/Aprobado/Rechazado)
- [ ] Validar que el badge es visible para cualquier usuario, no solo el dueño del objeto
- [ ] Validar que los botones de aprobar/rechazar NO aparecen en las cards, solo en el panel de detalle
- [ ] Validar que aprobar y rechazar desde el panel muestran un dialogo de confirmacion
- [ ] Validar que al seleccionar un objeto como admin se muestra la lista de reclamantes en el panel
- [ ] Validar que el boton "Entregar" de cada reclamante muestra confirmacion y actualiza el estado
- [ ] Validar que el dialogo de detalles de reclamacion muestra texto, fecha e imagen de evidencia
- [ ] Validar que el estado "Entregado" y "Sin reclamaciones" se muestran correctamente en el panel
- [ ] Validar que al seleccionar un objeto su marcador en el mapa se agranda con anillo blanco
- [ ] Validar que al deseleccionar el objeto el marcador vuelve a su tamaño normal
- [ ] Validar que al volver de detalles a la lista el panel mantiene el tamaño
- [ ] Validar que los botones de aprobar/rechazar no aparecen tras rechazar una publicacion
- [ ] `flutter analyze` completo sin warnings ni infos
- [ ] `flutter test` completo
- [ ] `flutter build apk --release`

## Publicacion

- [x] APK release generado y renombrado como `0.0.2+2.apk`
- [x] Release GitHub `v0.0.2` creado
- [x] APK adjunto al release

## Notas de validacion

- El panel inferior se probo en dispositivo Android `c402509e`.
- El gesto de abrir paso de `0.075` a `0.420` en logs `[UP_PANEL]`.
- El gesto de cerrar volvio de `0.420` a `0.075` en logs `[UP_PANEL]`.
- `flutter build apk --debug` compilo correctamente despues de los cambios.
- El campo `rechazado` en `LostObject` es nullable y compatible con documentos
  existentes en Firestore que no tengan el campo.
- El endpoint `rechazarObjeto` requiere una cloud function en
  `solicitudes_rechazar_objeto` que marque `rechazado: true` en el documento.
- La camara del mapa solo se ajusta en la carga inicial desde
  `_setupAnnotationsAndRender()`. Los cambios de datos (busqueda, filtros,
  aprobar, rechazar) actualizan marcadores sin mover la camara.
- Release publicado en GitHub:
  `https://github.com/Chapa0/backtome/releases/tag/v0.0.2`.
- Asset adjunto al release: `0.0.2+2.apk`.
