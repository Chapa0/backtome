# Implementacion de actualizaciones Android con dialogo in-app

Este documento describe la implementacion operativa del sistema de actualizaciones para `almeet`.

## Objetivo

- Consultar releases de GitHub al abrir la app cuando ya existe una sesion activa.
- Descargar el APK mas reciente en segundo plano solo cuando el dispositivo esta en Wi-Fi.
- Mostrar un dialogo in-app con los datos del release y una accion contextual.
- Permitir instalar directamente desde el dialogo cuando el APK del release mas reciente ya esta descargado.
- Exponer el estado de actualizacion en una pantalla compartida de Ajustes para admin, conductor y rentador.

## Archivo local de bootstrap

La configuracion local vive en:

- `assets/local/bootstrap_secrets.json`

Ese archivo no se versiona. El proyecto incluye un ejemplo:

- `assets/local/bootstrap_secrets.example.json`

Contrato esperado:

```json
{
  "github_token": "ghp_reemplazar_token",
  "github_owner": "owner_del_repo",
  "github_repo": "repo_del_release"
}
```

Notas:

- El archivo real se lee como asset local al arrancar la app.
- Si existe y tiene valores, se siembran en `flutter_secure_storage`.
- Si no existe o esta vacio, la app no se rompe; solo deja el sistema sin credenciales para consultar releases privados.
- Para cambiar token o repositorio se edita ese archivo y se vuelve a compilar la app.

## Flujo de arranque

Orden deseado:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp()`
3. `setupLocator()`
4. `LocalBootstrapSecretsService.seedSecureStorageFromLocalAsset()`
5. `AppUpdateService.initialize()`
6. `runApp(App(...))`

El chequeo automatico de actualizaciones corre despues del primer frame del `MaterialApp` y solo para roles autenticados:

- admin: `1`
- conductor: `2`
- rentador: `3`

No corre en:

- login
- selector de rol
- completar perfil

## Estados persistidos del updater

Claves principales:

- `github_access_token`
- `github_repo_owner`
- `github_repo_name`
- `app_update_latest_tag`
- `app_update_latest_name`
- `app_update_latest_asset_name`
- `app_update_latest_asset_url`
- `app_update_release_notes`
- `app_update_release_published_at`
- `app_update_downloaded_tag`
- `app_update_downloaded_apk_path`
- `app_update_last_checked_at`
- `app_update_status`
- `app_update_last_error`
- `app_update_download_progress`
- `app_update_recent_logs`

Estados funcionales:

- `idle`
- `checking`
- `available`
- `downloading`
- `downloaded`
- `installing`
- `failed`

## Reglas del release

Un release es valido si:

- no es pre-release
- tiene `tag_name` con version semantica interpretable
- tiene al menos un asset `.apk`

Comparacion de version:

- Se compara `major.minor.patch`
- El `buildNumber` de Flutter se muestra, pero no decide la actualizacion
- Se aceptan tags como `1.0.3` o `v1.0.3`

## Reglas del APK descargado

- Si existe un APK local y su `tag` coincide con el release mas reciente, el sistema conserva el archivo y muestra accion `Instalar`.
- Si existe un APK local pero aparece un release mas reciente, el sistema elimina el APK viejo, limpia su metadata y procesa el nuevo release.
- Si el archivo desaparece del almacenamiento, el estado persistido se invalida y se limpia.
- Si la version instalada ya es igual o mayor que el `downloaded_tag`, el APK descargado se considera obsoleto y se elimina.

## Comportamiento por red

### Wi-Fi

- Si hay release nuevo y no esta descargado, se inicia la descarga asincrona al abrir la app.
- El dialogo puede mostrar `Descargando...` y actualizarse a `Instalar` cuando termine.

### Datos moviles

- Si hay release nuevo y no esta descargado, no se descarga automaticamente.
- El dialogo muestra `Descargar`.
- Si el usuario confirma, la descarga se ejecuta manualmente.

### Sin red

- Si hay un APK valido ya descargado, el dialogo muestra `Instalar`.
- Si no hay APK valido, se deja el estado visible en Ajustes y se registra el error.

## Dialogo in-app

El dialogo es la “notificacion” principal del sistema.

Contenido:

- version actual instalada
- version nueva disponible
- fecha del release
- notas del release (`body`)
- estado actual
- error legible si aplica

Accion principal segun estado:

- `Descargar`
- `Descargando...`
- `Instalar`
- `Reintentar`

Accion secundaria:

- `Despues`

Comportamiento:

- se muestra automaticamente cuando hay release nuevo, una descarga en curso o un APK listo para instalar
- puede cerrarse sin detener una descarga ya iniciada
- si el usuario vuelve a entrar y el APK del release mas reciente sigue descargado, vuelve a mostrarse con `Instalar`

## Pantalla de Ajustes

Ruta nueva compartida:

- `AppRouter.settingsRoute`

Funciones iniciales:

- mostrar version actual
- mostrar ultimo release detectado
- mostrar notas del release
- mostrar ultimo chequeo
- mostrar estado actual
- buscar actualizacion manualmente
- descargar manualmente
- instalar APK descargado
- limpiar APK local invalido
- mostrar logs recientes y ultimo error

## Cambios en drawers

Cada drawer debe:

- agregar `Ajustes` en la parte inferior
- mantener `Cerrar sesion`
- mostrar la version actual en la esquina inferior derecha

Archivos tocados:

- `lib/features/admin/presentation/pages/home/widgets/admin_app_drawer.dart`
- `lib/features/conductor/presentation/widgets/conductor_drawer.dart`
- `lib/features/rentador/presentation/widgets/rentador_drawer.dart`

## Permisos y Android

Permisos y ajustes esperados:

- `android.permission.INTERNET`
- `android.permission.ACCESS_NETWORK_STATE`
- `android.permission.REQUEST_INSTALL_PACKAGES`

Instalacion:

- se abre el APK con `open_filex`
- si Android bloquea instalaciones desconocidas, se intenta solicitar `requestInstallPackages`
- si sigue fallando, se registra el error y se muestra mensaje claro al usuario

## Logs y diagnostico

Prefijo:

- `APP_UPDATE`

Eventos a registrar:

- inicio de chequeo
- red detectada
- lectura de bootstrap local
- release seleccionado
- inicio de descarga
- progreso de descarga
- fin de descarga
- restauracion de APK descargado
- eliminacion de APK obsoleto
- intento de instalacion
- error de token
- error de GitHub
- error de red
- error de archivo
- error de instalacion

Los ultimos eventos tambien se persisten para mostrarlos en Ajustes.

## Checklist manual

1. Arrancar la app sin `bootstrap_secrets.json` y confirmar que no crashea.
2. Agregar token/owner/repo validos y confirmar siembra en secure storage.
3. Abrir la app con release nuevo en Wi-Fi y verificar descarga automatica.
4. Cerrar el dialogo durante la descarga y confirmar que el estado sigue avanzando.
5. Reabrir la app con APK ya descargado y confirmar que el dialogo muestra `Instalar`.
6. Abrir la app con datos moviles y confirmar que solo aparece `Descargar`.
7. Instalar el APK descargado y volver a abrir la app.
8. Publicar un release mas nuevo y confirmar borrado del APK viejo.
9. Forzar un error de red o token y revisar logs y mensaje en Ajustes.
