# Mapas de hallazgo y recoleccion

## Problemas corregidos

- La pantalla abierta desde los detalles solo mostraba coordenadas.
- Cuando un objeto llegaba a un punto de entrega, su marcador dejaba de mostrar
  el lugar del hallazgo y se movia al punto de custodia.
- Los puntos de entrega se confundian con los marcadores circulares de objetos.

## Comportamiento nuevo

- La pantalla de ubicaciones usa Mapbox y muestra informacion util, sin exponer
  coordenadas como contenido principal.
- El circulo del objeto permanece en el lugar donde se encontro.
- Si el objeto esta en custodia, el mapa muestra simultaneamente el lugar del
  hallazgo y el punto donde puede recogerse.
- La camara encuadra las dos ubicaciones al seleccionar el objeto.
- El punto de entrega relacionado con la seleccion se resalta visualmente.

## Diseño de los puntos de entrega

Los puntos de entrega ahora usan un pin turquesa con icono de establecimiento.
El marcador seleccionado tiene borde ambar y mayor tamaño. Los objetos mantienen
los circulos rojo, naranja o verde asociados a su estado.

El marcador se genera en la capa de presentacion como bitmap para Mapbox y se
reutiliza tanto en el mapa principal como en la administracion de puntos.
