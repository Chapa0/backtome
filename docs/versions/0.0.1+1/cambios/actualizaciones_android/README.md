# Actualizaciones Android

## Resumen

Se implemento la base del sistema de actualizaciones Android para BackToMe.
El sistema consulta releases de GitHub, detecta si existe una version mayor,
descarga el APK y permite abrir el instalador desde la app.

## Componentes agregados

| Componente | Archivo | Descripcion |
|---|---|---|
| `AppUpdateService` | `lib/features/app_updates/data/services/app_update_service.dart` | Servicio central de chequeo, descarga, instalacion, persistencia y logs |
| `AppUpdateGate` | `lib/features/app_updates/presentation/widgets/app_update_gate.dart` | Widget global que dispara el chequeo al entrar con sesion activa y muestra el dialogo |
| `SettingsPage` | `lib/features/app_updates/presentation/pages/settings_page.dart` | Pantalla compartida para consultar estado, buscar, descargar, instalar, limpiar APK y revisar logs |
| `LocalBootstrapSecretsService` | `lib/shared/utils/local_bootstrap_secrets_service.dart` | Lectura del asset local y siembra de credenciales GitHub en almacenamiento seguro |

## Flujo implementado

- Al arrancar la app se inicializa Firebase, DI y el servicio de
  actualizaciones.
- El asset `assets/local/bootstrap_secrets.json` puede sembrar:
  - `github_token`
  - `github_owner`
  - `github_repo`
- Si el usuario ya tiene sesion activa, despues del primer frame se consulta el
  release mas reciente.
- Si el release contiene un asset `.apk` y su tag semver es mayor que la
  version instalada, la app lo marca como disponible.
- Si el dispositivo esta en Wi-Fi o ethernet, la descarga puede iniciar de forma
  automatica.
- Si el APK ya esta descargado y sigue correspondiendo al release mas reciente,
  el dialogo ofrece instalar.
- Si el APK local desaparece o queda obsoleto, se limpia la metadata.

## Reglas tecnicas

- Tags aceptados: `0.0.2` o `v0.0.2`.
- La comparacion usa `major.minor.patch`; el build number se muestra pero no
  decide la actualizacion.
- Los prereleases se ignoran.
- El release debe tener al menos un asset `.apk`.
- Los logs recientes se guardan para mostrarse en Ajustes.

## Dependencias agregadas

- `flutter_secure_storage: 9.2.4`
- `connectivity_plus: 6.1.5`
- `package_info_plus: ^9.0.1`
- `open_filex: ^4.7.0`

Se fijaron versiones compatibles con el Android Gradle Plugin actual del
proyecto.

## Permisos Android

Se agregaron permisos para:

- Internet.
- Estado de red.
- Solicitud de instalacion de paquetes.
- Visibilidad del intent para abrir APKs.

## Pendiente para prueba real

- Configurar `github_owner` y `github_repo`.
- Configurar `github_token` si el repositorio es privado.
- Crear un release GitHub no prerelease con asset `.apk`.
- Probar en un dispositivo Android real el permiso de instalar apps
  desconocidas.

## Ajuste de build release

Durante la preparacion del primer APK release, R8 fallo leyendo metadata de
dependencias Kotlin 2.1 con el Android Gradle Plugin actual. Para poder generar
la primera entrega sin cambiar toda la cadena Gradle, el build `release`
mantiene firma debug y desactiva `minifyEnabled` y `shrinkResources`.

Este ajuste debe revisarse antes de una publicacion productiva firmada con
keystore definitivo.

## Correcciones

### Progreso de descarga

Se corrigio un error donde el servicio podia recibir `0` o `1` como enteros al
actualizar `downloadProgress`, pero el snapshot esperaba estrictamente un
`double`. Ahora el helper convierte cualquier valor numerico (`int` o `double`)
a `double` antes de guardar el estado.
