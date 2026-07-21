# Pantalla de carga para acciones

## Problema

Varias operaciones remotas, como aprobar un objeto, no mostraban progreso. El
usuario podia volver a pulsar controles o salir de la pantalla mientras el
backend seguia procesando la solicitud.

## Solucion

Se creo un overlay reutilizable dentro de la capa de presentacion. El overlay:

- muestra un indicador y un mensaje especifico para cada accion;
- bloquea los controles que quedan detras;
- bloquea la flecha del AppBar, el boton fisico y el gesto de volver;
- se retira siempre al completar o fallar la operacion;
- conserva los errores y resultados en la pantalla que inicio la accion.

## Flujos cubiertos

- Aprobar y rechazar publicaciones.
- Registrar la recepcion en un punto de entrega.
- Entregar el objeto a un reclamante.
- Eliminar objetos y usuarios.
- Guardar o desactivar puntos de entrega.
- Actualizar nombre y apellido, enviar restablecimiento de contraseña y cerrar
  sesion.

## Arquitectura

La responsabilidad visual vive en `shared/widgets`. Los casos de uso siguen
coordinando el dominio y los repositorios mantienen el acceso a datos. Ninguna
capa inferior conoce el overlay ni depende de `BuildContext`.
