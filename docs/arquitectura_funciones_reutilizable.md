# Arquitectura de Firebase Functions reutilizable

## Objetivo

Este documento resume la arquitectura de backend serverless usada en este
proyecto para que pueda reutilizarse en otro proyecto.

La idea principal es simple:

- la app no ejecuta reglas criticas de negocio
- la app crea solicitudes en Firestore
- Cloud Functions procesa esas solicitudes
- Cloud Functions escribe en las colecciones finales
- la app observa el estado de la solicitud hasta `ok` o `error`

Este patron sirve para operaciones que requieren consistencia, por ejemplo:

- crear o editar registros de negocio
- modificar inventario
- mover estados
- registrar pagos, deudas o gastos
- generar claves de registro
- integrar procesos externos como WhatsApp

## Tipo de arquitectura base

La base actual combina:

- Firebase Cloud Functions v2
- Firestore como cola ligera de comandos
- Firestore triggers para procesar solicitudes
- HTTP Functions para webhooks, integraciones web y endpoints publicos
- Callable Functions para consultas directas desde app cuando conviene
- Firebase Admin SDK como capa de escritura privilegiada
- TypeScript estricto compilado a JavaScript
- logica de negocio separada de los handlers
- tests unitarios sobre logica pura

No es una arquitectura de microservicios completa. Es una arquitectura
serverless pragmatica:

- cada accion importante tiene una Function concreta
- cada Function recibe un contrato pequeno
- las escrituras criticas pasan por backend
- Firestore conserva evidencia del request y del resultado
- la app queda desacoplada de transacciones complejas

## Stack tecnico

| Pieza | Uso |
| --- | --- |
| `firebase-functions` | Definir triggers `onDocumentCreated`, `onDocumentUpdated`, `onRequest` y `onCall` |
| `firebase-admin` | Acceso privilegiado a Firestore, Auth y Storage |
| `typescript` | Codigo fuente de Functions en `functions/src` |
| `nodejs22` | Runtime configurado en `firebase.json` y `functions/package.json` |
| Firestore | Cola de solicitudes, fuente de verdad y documentos de resultado |
| Firebase Storage | Archivos asociados, por ejemplo imagenes o logos |
| Firebase Hosting | Hosting web y rewrite hacia Function `webChat` |
| Node test runner | Tests unitarios con `node --test` |

## Estructura actual de `functions`

```text
functions/
  package.json
  tsconfig.json
  src/
    index.ts
    handlers/
    logic/
    services/
      audio/
      auth/
      openai/
      opencode_go/
      whatsapp/
    tools/
    utils/
  tests/
  lib/
```

### Responsabilidad de cada bloque

#### `src/index.ts`

Es el composition root del backend.

Responsabilidades:

- inicializar Firebase Admin con `initializeApp()`
- crear instancias compartidas: Firestore, Storage, Auth
- configurar Firestore con `ignoreUndefinedProperties`
- leer variables de entorno
- crear helpers, servicios y handlers
- inyectar dependencias a mano en cada fabrica
- exportar las Cloud Functions finales

Regla importante:

`index.ts` debe ensamblar dependencias, no concentrar toda la logica de negocio.
Si crece demasiado, se debe extraer a `handlers`, `services`, `logic` o `utils`.

#### `src/handlers/`

Contiene las fabricas que crean Functions.

Ejemplos:

- `pedidos_firestore_handlers.ts`
- `pedidos_operations_handlers.ts`
- `inventario_handlers.ts`
- `finanzas_handlers.ts`
- `auth_admin_handlers.ts`
- `whatsapp_http_handlers.ts`
- `whatsapp_firestore_handlers.ts`
- `web_chat_handlers.ts`
- `disponibilidad_handlers.ts`

Responsabilidades:

- definir el trigger
- leer el evento o request
- validar datos basicos del contrato
- llamar logica o servicios
- ejecutar transacciones cuando aplica
- escribir `estado: ok` o `estado: error`
- registrar errores operativos con `console.error`

Patron recomendado:

```ts
export const createMiFeatureHandlers = (deps: MiFeatureHandlersDeps) => {
  const procesarSolicitudMiAccion = onDocumentCreated(
    "solicitudes_mi_accion/{solicitudId}",
    async (event) => {
      // leer snapshot
      // validar estado pendiente
      // ejecutar logica/transaccion
      // actualizar solicitud
    }
  );

  return { procesarSolicitudMiAccion };
};
```

#### `src/logic/`

Contiene reglas puras de negocio.

Ejemplos:

- validaciones de solicitud
- calculos de pago
- normalizacion de estados
- disponibilidad de inventario
- calculos de jornadas
- armado de payloads

Reglas:

- debe ser facil de testear sin Firebase
- no debe depender de request HTTP ni snapshots de Firestore
- debe recibir datos normales y devolver resultados normales
- si una regla empieza a necesitar mocks complejos, probablemente pertenece a `services` o `handlers`

#### `src/services/`

Contiene integraciones o servicios de dominio que no son un trigger directo.

Ejemplos:

- WhatsApp Cloud API
- OpenAI
- transcripcion de audio
- generacion de codigos de registro
- helpers de estado de conversacion

Regla:

Un servicio puede tener dependencias externas, pero debe exponer una API pequena
para que el handler no se llene de detalles tecnicos.

#### `src/utils/`

Utilidades transversales:

- coercion de tipos
- fechas
- archivos de Storage
- variables locales

Estas funciones deben ser neutrales al dominio. Si una utilidad conoce reglas de
negocio, debe moverse a `logic/`.

#### `src/tools/`

Scripts operativos y simuladores.

Uso actual:

- seed de datos
- simuladores de WhatsApp
- probes contra produccion
- reset de inventario de prueba

No forman parte del runtime de las Functions exportadas, pero ayudan a operar y
validar el backend.

#### `tests/`

Tests unitarios de la logica compilada en `lib/`.

El script `npm test` primero ejecuta `npm run build` y despues corre:

```bash
node --test tests/*.js
```

## Flujo principal: solicitud Firestore

Este es el patron mas importante de la arquitectura.

```text
Flutter UI
  -> Bloc recibe evento
  -> UseCase crea solicitud
  -> DataSource escribe en solicitudes_*
  -> Firestore confirma commit de servidor
  -> Bloc observa la solicitud

Cloud Function
  -> onDocumentCreated detecta solicitud pendiente
  -> valida contrato
  -> ejecuta logica/transaccion
  -> escribe colecciones finales
  -> actualiza solicitud a ok o error

Flutter UI
  -> stream detecta ok/error
  -> Bloc emite success o failure
  -> UI muestra resultado confirmado
```

### Contrato minimo de una solicitud

Una solicitud debe tener al menos:

```text
estado: "pendiente"
idCuenta: "<cuenta o tenant>"
payload: { ... }
createdAt: serverTimestamp o fecha cliente
```

La Function debe actualizarla a:

```text
estado: "ok"
updatedAt: serverTimestamp
<ids generados o datos de salida>
```

o:

```text
estado: "error"
errorMensaje: "<mensaje de negocio u operacion>"
updatedAt: serverTimestamp
```

### Por que usar documentos `solicitudes_*`

Ventajas:

- deja auditoria de lo que pidio el cliente
- permite observar resultado con streams
- desacopla UI de transacciones backend
- evita que el cliente escriba directo en colecciones criticas
- permite reintentar manualmente desde UI si falla
- funciona bien con BLoC y Clean Architecture

Costos:

- cada accion requiere contrato de solicitud
- el cliente debe manejar estado `pending`
- hay que cuidar timeouts y mensajes de error
- las reglas Firestore deben permitir crear solicitud pero no modificarla

## Tipos de Functions usados

### 1. Firestore `onDocumentCreated`

Es el tipo dominante.

Se usa cuando la app crea una solicitud en una coleccion `solicitudes_*`.

Ejemplos:

- `procesarSolicitudPedido`
- `procesarSolicitudEdicionPedido`
- `procesarSolicitudEstadoPedido`
- `procesarSolicitudMovimientoPedido`
- `procesarSolicitudCancelarPedido`
- `procesarSolicitudActualizarInventario`
- `procesarSolicitudAgregarInventario`
- `procesarSolicitudPagarDeuda`
- `procesarSolicitudRegistroAdmin`
- `procesarSolicitudAgregarPaquete`

Patron de seguridad:

- el cliente solo crea documentos con `estado: pendiente`
- Cloud Functions usa Admin SDK para actualizar la solicitud
- el cliente observa el resultado, pero no lo modifica

### 2. Firestore `onDocumentUpdated`

Se usa cuando el evento relevante es un cambio de estado, no la creacion.

Ejemplo:

- `procesarRespuestaSolicitudPedidoWhatsapp`

Uso recomendado:

- confirmar una respuesta externa
- reaccionar a una actualizacion especifica
- evitarlo para comandos simples donde `onCreate` es suficiente

### 3. HTTP `onRequest`

Se usa para integraciones externas, webhooks y endpoints web.

Ejemplos:

- `whatsappWebhook`
- `webChat`
- `iniciarEmbeddedSignupWhatsapp`
- `registrarEmbeddedSignupWhatsapp`

Responsabilidades extra:

- validar metodo HTTP
- limitar payload
- validar tokens o identidad
- responder siempre con status HTTP claro
- no exponer errores internos al cliente externo

### 4. Callable `onCall`

Se usa para invocacion directa desde cliente cuando no hace falta crear una
solicitud persistente.

Ejemplo:

- `calcularDisponibilidadInventario`

Uso recomendado:

- consultas calculadas
- resultados inmediatos
- operaciones sin efecto secundario critico

Si la accion escribe varias colecciones o modifica dinero/inventario/estados,
conviene usar `solicitudes_*` en lugar de callable.

## Arquitectura de una accion critica

Para agregar una nueva accion reutilizando esta base:

```text
lib/features/mi_feature/
  data/
    datasources/
      solicitud_mi_accion_firestore_datasource.dart
    models/
      solicitud_mi_accion_model.dart
    repositories/
      solicitud_mi_accion_repository_impl.dart
  domain/
    entities/
      solicitud_mi_accion_entity.dart
    repositories/
      solicitud_mi_accion_repository.dart
    usecases/
      crear_solicitud_mi_accion_usecase.dart
      watch_solicitud_mi_accion_usecase.dart
  presentation/
    blocs/
      solicitud_mi_accion/
        solicitud_mi_accion_bloc.dart
        solicitud_mi_accion_event.dart
        solicitud_mi_accion_state.dart

functions/src/
  handlers/
    mi_feature_handlers.ts
  logic/
    mi_accion.ts
  index.ts

functions/tests/
  mi_accion.test.js
```

### Flujo en Flutter

El datasource:

- crea el documento en `solicitudes_mi_accion`
- espera confirmacion de commit de servidor
- devuelve `solicitudId`
- expone un stream para observar la solicitud

El BLoC:

- valida conectividad si la accion es online obligatoria
- emite `submitting`
- crea solicitud
- emite `pending`
- escucha hasta `ok` o `error`
- cancela la suscripcion en `close()`

Estados recomendados:

```text
initial
submitting
pending
success
error
```

### Flujo en Functions

El handler:

1. recibe `onDocumentCreated`
2. ignora si no hay snapshot
3. lee `data`
4. ignora si `estado` existe y no es `pendiente`
5. valida contrato
6. ejecuta transaccion si toca varias colecciones
7. escribe resultado final
8. marca solicitud como `ok`
9. captura errores y marca solicitud como `error`

### Cuando usar transacciones

Usar `db.runTransaction` si una accion toca:

- inventario + pedidos
- pagos + deuda
- jornada + movimientos
- documentos agregados + documento principal
- historial + actualizacion actual
- cualquier operacion que deba ser atomica

Si solo se escribe un documento independiente, puede bastar con `batch` o `set`.

## Seguridad Firestore

La politica actual sostiene la arquitectura:

- las colecciones `solicitudes_*` permiten `create` si `estado == "pendiente"`
- no permiten `update` ni `delete` desde cliente
- las colecciones de negocio no aceptan escritura directa desde cliente
- Cloud Functions escribe con Admin SDK

Efecto:

```text
Cliente
  puede crear solicitud pendiente
  puede observar resultado
  no puede aprobarse a si mismo
  no puede saltarse reglas de negocio

Cloud Functions
  valida
  aplica negocio
  escribe resultado
```

En un proyecto nuevo, esta regla debe copiarse desde el principio. Si se permite
que el cliente escriba directo en colecciones finales, se pierde el beneficio
principal de esta arquitectura.

## Variables de entorno y secretos

Las Functions leen configuracion desde variables de entorno.

Ejemplos actuales:

- `META_APP_ID`
- `META_EMBEDDED_SIGNUP_CONFIG_ID`
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_VERIFY_TOKEN`
- `WHATSAPP_GRAPH_API_VERSION`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `OPENCODE_GO_API_KEY`
- `OPENCODE_GO_MODEL`
- `QWEN_API_KEY`
- `QWEN_MODEL`
- `QWEN_CHAT_COMPLETIONS_URL`
- `OPENAI_TRANSCRIPTION_API_KEY`

El repositorio incluye un helper:

```powershell
scripts/set-functions-env.ps1
```

Ese script genera:

```text
functions/.env.<alias>
```

Para otro proyecto, conviene conservar la idea pero cambiar:

- alias del proyecto
- variables reales requeridas
- modelos y proveedores externos
- tokens de integraciones

Regla:

No versionar archivos `.env` reales ni secretos.

## Configuracion Firebase

La raiz define el backend en `firebase.json`:

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs22"
  }
}
```

Tambien se despliegan reglas e indices de Firestore:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

Y Hosting puede redirigir una ruta a una Function:

```json
{
  "source": "/api/webChat",
  "function": "webChat"
}
```

Esto permite exponer un endpoint HTTP sin crear un servidor separado.

## Build, pruebas y deploy

### Instalar dependencias

```bash
cd functions
npm install
```

### Compilar TypeScript

```bash
cd functions
npm run build
```

Compila:

```text
src/ -> lib/
```

El entrypoint publicado es:

```text
functions/lib/index.js
```

### Ejecutar pruebas

```bash
cd functions
npm test
```

El script ejecuta:

```bash
npm run build && node --test tests/*.js
```

Para una prueba puntual:

```bash
cd functions
node --test tests/01_agregar_pedido.test.js
```

### Servir emulador

```bash
cd functions
npm run serve
```

Internamente:

```bash
npm run build && firebase emulators:start --only functions
```

### Desplegar Functions

Desde `functions/`:

```bash
npm run deploy
```

Internamente:

```bash
firebase deploy --only functions
```

Desde la raiz, si tambien se quieren reglas:

```bash
firebase deploy --only "functions,firestore:rules" --project almeet --non-interactive
```

Para otro proyecto, cambiar `almeet` por el id real.

### Ver logs

```bash
cd functions
npm run logs
```

o:

```bash
firebase functions:log --project almeet
```

### Operacion desde Google Cloud Shell

Cloud Shell es util cuando se quiere operar desde un entorno ya autenticado:

```bash
firebase deploy --only functions --project almeet
firebase deploy --only firestore:rules --project almeet
firebase functions:log --project almeet
gcloud functions list
gcloud config get-value project
```

La fuente de verdad sigue siendo el repositorio. Cloud Shell es una consola
operativa, no un lugar para editar codigo sin traerlo de vuelta al repo.

## Documentacion operativa

El proyecto mantiene documentacion viva en:

```text
docs/funcions/
  00_proceso.md
  buenas_practicas_nueva_function.md
  politica_offline_online.md
  procedimiento_implementacion_online_offline.md
  matriz_prioridad_online_offline.md
  reglas_firestore_implementadas.md
  operacion_cloud_shell.md
  planes/
  migrados/
  seguimiento/
    estado_deploy.md
    estado_migracion.md
    estado_pruebas.md
```

Para cada nueva Function importante:

1. crear plan en `docs/funcions/planes/`
2. crear detalle tecnico en `docs/funcions/migrados/`
3. actualizar `seguimiento/estado_migracion.md`
4. actualizar `seguimiento/estado_pruebas.md`
5. actualizar `seguimiento/estado_deploy.md` si se desplego

Este proceso evita que el backend quede como una caja negra.

## Politica online/offline

La arquitectura distingue dos tipos de accion.

### Online obligatorio

Usar cuando el cambio afecta:

- inventario
- dinero
- deuda
- jornadas
- estados globales
- permisos
- datos compartidos entre usuarios

Flujo:

```text
validar conexion
crear solicitud pendiente
esperar ok/error
mostrar exito solo si el servidor confirma
```

### Offline permitido

Usar solo cuando el cambio es reconciliable y no rompe consistencia.

Flujo:

```text
aplicar cambio local
marcar pendingSync
crear solicitud
limpiar pendingSync si llega ok
marcar syncError o revertir si llega error
```

Regla practica:

Si un doble envio, un desfase o una escritura local falsa puede romper negocio,
la accion debe ser online obligatoria.

## Convenciones de naming

### Colecciones de solicitud

Usar plural y prefijo `solicitudes_`:

```text
solicitudes_pedidos
solicitudes_edicion_pedidos
solicitudes_actualizar_inventario
solicitudes_pagar_deuda
solicitudes_registro_admin
```

### Functions

Usar verbo `procesarSolicitud...` para triggers de solicitud:

```text
procesarSolicitudPedido
procesarSolicitudActualizarInventario
procesarSolicitudPagarDeuda
```

Usar nombres directos para HTTP/callable:

```text
whatsappWebhook
webChat
calcularDisponibilidadInventario
```

### App Flutter

Mantener consistencia entre:

```text
SolicitudPedidoEntity
SolicitudPedidoModel
SolicitudPedidoRepository
CrearSolicitudPedidoUseCase
WatchSolicitudPedidoUseCase
SolicitudPedidoBloc
```

La consistencia de nombres es importante porque hay varias piezas por cada
accion.

## Manejo de errores

Reglas recomendadas:

- los errores de contrato deben convertirse en `estado: error`
- el mensaje para UI debe vivir en `errorMensaje`
- los errores tecnicos deben registrarse con `console.error`
- no devolver stack traces al cliente
- en HTTP, responder con status adecuado
- en transacciones, lanzar `Error` con mensaje claro de negocio

Ejemplo de actualizacion de error:

```ts
await solicitudRef.set(
  {
    estado: "error",
    errorMensaje,
    updatedAt: FieldValue.serverTimestamp(),
  },
  { merge: true }
);
```

## Patrones que conviene replicar tal cual

- `functions/src/index.ts` como composition root
- handlers creados con fabricas `createXHandlers(deps)`
- dependencias inyectadas explicitamente
- reglas puras en `logic/`
- servicios externos en `services/`
- utilidades comunes en `utils/`
- solicitudes Firestore para operaciones criticas
- estado de solicitud `pendiente -> ok/error`
- transacciones para cambios atomicos
- tests unitarios en `functions/tests`
- documentacion por plan, migrado y seguimiento
- deploy con `npm run deploy` o `firebase deploy --only functions`

## Decisiones que se pueden mejorar en otro proyecto

Sin romper la base, se puede evolucionar:

- usar tipos mas estrictos en lugar de `any` para Firestore y Admin SDK
- crear helpers comunes para marcar solicitud `ok/error`
- centralizar validacion de `estado: pendiente`
- agregar logger estructurado
- agregar validacion de auth por `request.auth` o claims
- cerrar `read` por cuenta/rol en Firestore rules
- separar integraciones IA/WhatsApp en modulos opcionales
- agregar CI para `npm run build` y `npm test`
- agregar emuladores a pruebas de integracion cuando haga falta

## Checklist para crear una nueva Function

1. Definir si es `online obligatorio` u `offline permitido`.
2. Definir coleccion `solicitudes_*`.
3. Definir contrato de entrada.
4. Definir salida `ok/error`.
5. Agregar reglas Firestore para permitir solo `create pendiente`.
6. Crear entidad/modelo/repositorio/usecases en Flutter.
7. Crear BLoC que cree y observe solicitud.
8. Crear archivo en `functions/src/logic`.
9. Crear tests unitarios de logica.
10. Crear handler en `functions/src/handlers`.
11. Registrar fabrica en `functions/src/index.ts`.
12. Exportar Function desde `index.ts`.
13. Ejecutar `npm run build`.
14. Ejecutar `npm test`.
15. Probar flujo real en app.
16. Desplegar con `npm run deploy`.
17. Actualizar documentacion de seguimiento.

## Resumen ejecutivo

Para reutilizar esta arquitectura en otro proyecto, copia la idea central:

1. Firebase Functions v2 con Node 22 y TypeScript.
2. `index.ts` arma dependencias y exporta Functions.
3. `handlers/` define triggers.
4. `logic/` concentra reglas testeables.
5. `services/` encapsula integraciones externas.
6. `utils/` guarda helpers tecnicos.
7. La app crea documentos `solicitudes_*` con `estado: pendiente`.
8. Firestore triggers procesan y actualizan a `ok` o `error`.
9. La app observa la solicitud para confirmar UI.
10. Firestore rules bloquean escrituras directas a colecciones finales.
11. Las operaciones criticas usan transacciones.
12. El deploy se hace con `firebase deploy --only functions`.

Con esto se obtiene una base reutilizable para backend serverless donde el
cliente sigue siendo simple y las reglas criticas quedan del lado del servidor.
