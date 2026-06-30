# Release 0.0.2+2

## Registro e inicio de sesion

Ahora puedes ver la contrasena mientras creas una cuenta, tanto en el campo de
contrasena como en la confirmacion.

Las cuentas nuevas requieren una contrasena de al menos 8 caracteres. Esto evita
crear cuentas con contrasenas demasiado cortas que despues causaban confusion al
intentar iniciar sesion.

Tambien se mejoraron los mensajes cuando el correo o la contrasena no coinciden.

## Reclamaciones

Se corrigio un error que podia impedir enviar una reclamacion de objeto perdido.
La app ya no debe mostrar el error relacionado con `horaReclamacion` y
`FieldValue.serverTimestamp()`.

## Administracion desde el mapa

Los administradores ahora entran a la vista de mapa y desde ahi pueden revisar
los objetos por estado:

- Todos.
- Pendientes.
- Aprobados.
- Rechazados.
- Reclamados.
- Entregados.

Desde el panel se pueden aprobar o rechazar publicaciones pendientes. Al
seleccionar un objeto, puedes ver la lista de reclamantes y entregar el objeto
directamente desde el panel, sin necesidad de ir a otra pantalla.

Las publicaciones rechazadas muestran un distintivo naranja y no aparecen a los
usuarios normales.

Al aprobar o rechazar una publicacion, la app te pide confirmacion para evitar
hacerlo por accidente.

Ahora todas las publicaciones muestran un indicador de estado (Pendiente,
Aprobado o Rechazado) en su tarjeta, visible para cualquier usuario.

## Busqueda y calendario en el panel

La barra de busqueda ahora esta dentro del panel inferior. Al presionar el
boton de buscar, el panel se abre automaticamente y puedes escribir para
encontrar objetos perdidos.

El calendario para filtrar por fecha tambien esta dentro del panel. Al
presionar el boton de calendario, el panel se abre y puedes seleccionar un
dia o rango de fechas.

Ambos botones estan juntos en la barra inferior, junto al boton de menu.

Al escribir en la busqueda, el teclado ya no empuja la interfaz hacia arriba.
El panel se mantiene fijo.

## Marcadores en el mapa

Los marcadores de objetos perdidos ahora aparecen en el mapa al mismo tiempo
que en la lista, sin esperas ni necesidad de hacer gestos adicionales.

El mapa ya no regresa a la vista inicial cada vez que realizas una accion. Si
moviste o hiciste zoom en el mapa, se queda exactamente donde lo dejaste al
buscar, filtrar, aprobar o rechazar publicaciones.

Al seleccionar un objeto en el panel, su marcador en el mapa se agranda y
muestra un anillo blanco para que puedas identificarlo facilmente entre los
demas.

## Panel inferior

El panel inferior del mapa inicia colapsado y se despliega arrastrando la barra
superior. Ya no depende de botones para abrir o cerrar.

El panel puede quedar en tres posiciones: cerrado, lista y vista ampliada.

Al abrirlo completamente, la agarradera permanece visible para poder volver a
cerrarlo. Ademas, cuando la lista esta en el inicio, arrastrar hacia abajo
colapsa el panel en lugar de activar una recarga manual.

Al volver de los detalles de un objeto a la lista, el panel ya no se encoge.
Mantiene el tamano en que lo tenias para que no pierdas tu posicion.

## Sesion admin

Si el rol de un usuario se cambia a admin en Firestore, la app vuelve a leer ese
rol al restaurar la sesion para mostrar la experiencia correcta.
