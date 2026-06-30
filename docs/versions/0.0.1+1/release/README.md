# Release 0.0.1+1

## Sistema de actualizaciones Android

BackToMe ahora cuenta con una base para recibir actualizaciones desde la propia
app en Android.

Cuando exista una version nueva publicada en GitHub con su APK adjunto, la app
podra detectarla al iniciar sesion y mostrar un dialogo con la informacion de la
actualizacion.

Desde ese dialogo el usuario podra:

- Ver la version instalada y la nueva version disponible.
- Leer las notas del release.
- Descargar el APK si todavia no esta disponible en el dispositivo.
- Instalar la actualizacion cuando la descarga haya terminado.

## Nueva pantalla de Ajustes

Se agrego una pantalla de Ajustes con una seccion de actualizaciones. Desde ahi
se puede:

- Ver la version instalada.
- Ver el ultimo release detectado.
- Buscar actualizaciones manualmente.
- Descargar una actualizacion.
- Instalar un APK ya descargado.
- Limpiar un APK local si hace falta.
- Revisar logs recientes y ultimo error.

## Estado de esta version

Primera version publicada para activar el sistema de actualizaciones Android de
BackToMe.

## Correccion incluida

Se corrigio la lectura del progreso de descarga para evitar errores cuando la
app recibe valores enteros como `0` o `1` al actualizar el estado interno.
