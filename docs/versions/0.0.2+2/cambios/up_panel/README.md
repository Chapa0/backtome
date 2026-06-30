# Up panel

## Cambios incluidos

- Se reemplazo el `DraggableScrollableSheet` por un panel con altura controlada
  internamente porque el controller no se adjuntaba en Android.
- La barra superior del panel funciona como agarradera de arrastre.
- El panel inicia colapsado.
- El panel hace snap a tres posiciones: colapsado, lista y pantalla casi
  completa.
- El alto maximo del panel se calcula contra el area visible de la pantalla
  para que la agarradera no quede escondida al abrirlo por completo.
- Se elimino el pull-to-refresh de la lista; al estar al inicio y arrastrar
  hacia abajo, el gesto ahora colapsa el panel.
- Se agregaron logs `[UP_PANEL]` para diagnosticar gestos y tamanos.
- Se activo debug visual global en modo debug para ver bordes, tamanos y
  punteros.
- La barra de busqueda se movio dentro del panel, debajo de la agarradera.
  Antes era un overlay flotante sobre el mapa.
- Al presionar el boton de buscar, el panel se abre completamente para
  mostrar la barra de busqueda.
- El calendario de filtro por fecha se movio dentro del panel, debajo de la
  barra de busqueda. Antes era un overlay en la parte superior del mapa.
- Al presionar el boton de calendario, el panel se abre completamente para
  mostrar el calendario.
- Los botones de calendario y busqueda se movieron al `BottomAppBar`, a la
  derecha del boton de menu.
- Se agrego `resizeToAvoidBottomInset: false` al `Scaffold` para que el
  teclado no empuje el panel hacia arriba al escribir en la busqueda. El
  panel queda fijo y el teclado se sobrepone encima.
- Al volver de los detalles de un objeto a la lista, el panel mantiene el
  tamano que tenia al entrar. Antes `_deselectObject()` forzaba
  `_panelListSize`, encogiendo el panel a la mitad aunque estuviera
  completamente desplegado. Ahora solo cambia el contenido, no la altura.

## Resultado esperado

El panel responde al arrastre vertical y no depende de botones para abrirse o
cerrarse.

La busqueda y el calendario estan integrados en el panel como filtros para
encontrar objetos perdidos. Al tocar cualquiera de los dos botones, el panel
se despliega completamente y muestra el control correspondiente.

Al escribir en la barra de busqueda, el panel permanece fijo en su lugar y
el teclado aparece encima sin desplazar la interfaz.
