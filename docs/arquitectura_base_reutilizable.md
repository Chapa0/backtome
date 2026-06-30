# Arquitectura base reutilizable para nuevos proyectos Flutter

## Objetivo

Este documento resume la base tecnica reusable del proyecto actual, pero sin amarrarla al dominio de negocio que hoy existe. La idea es que sirva como plantilla para arrancar un nuevo proyecto con el mismo estilo de trabajo:

- arquitectura modular por feature
- Clean Architecture pragmatica
- BLoC como orquestador de UI y flujos
- DI centralizada con `get_it`
- entidades, contratos y casos de uso en `domain/`
- implementaciones y acceso a datos en `data/`
- paginas, widgets y BLoCs en `presentation/`

Quedan fuera de este documento las integraciones externas y especificas de plataforma o backend, por ejemplo servicios tipo Firebase, mapas, permisos, storage, autenticacion externa o carga de imagenes. Aqui solo se documenta la base estructural y las librerias que sostienen esa arquitectura.

## Tipo de arquitectura base

La base actual es una combinacion de:

- `Feature-first architecture`
- `Clean Architecture`
- `BLoC pattern`
- `Service Locator / Dependency Injection`
- `Shared UI + Core cross-cutting modules`

No es una Clean Architecture "academica" al 100%. Es una version pragmatica y productiva:

- la mayor parte de la logica vive por feature
- cada feature importante se separa en `data`, `domain` y `presentation`
- algunos modulos agregadores viven principalmente en `presentation/` y consumen casos de uso de varios features
- la navegacion esta centralizada, pero usa el router nativo de Flutter, no un paquete externo de routing

## Estructura base recomendada

```text
lib/
  main.dart
  app.dart
  core/
    di/
    router/
    theme/
  features/
    feature_a/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        blocs/
        pages/
        widgets/
    feature_b/
      ...
  shared/
    utils/
    widgets/
  utilities/
```

### Responsabilidad de cada bloque

#### `main.dart`

Punto de arranque tecnico:

- inicializa bindings de Flutter
- configura locale y recursos globales
- inicializa servicios base si el proyecto los necesita
- ejecuta `setupLocator()`
- recupera sesion o configuracion persistida
- llama a `runApp(...)`

#### `app.dart`

Casco principal de la aplicacion:

- monta `MaterialApp`
- define tema y localizacion
- inyecta BLoCs globales con `MultiBlocProvider` cuando aplica
- decide la pantalla inicial segun estado de sesion, rol o bootstrap
- conecta `onGenerateRoute`

#### `core/`

Codigo transversal que no pertenece a una feature concreta:

- `di/`: registro de dependencias
- `router/`: definicion de rutas y creacion de paginas
- `theme/`: `ThemeData`, tokens base y configuracion visual

`core/` no debe contener reglas de negocio de una feature.

#### `features/`

Es el centro real del proyecto. Cada modulo funcional serio vive aqui y se organiza por capas.

#### `shared/`

Reutilizables comunes entre varias features:

- widgets compartidos
- helpers de presentacion
- utilidades neutrales al dominio

Si algo solo lo usa una feature, no debe ir aqui.

#### `utilities/`

Reservado para codigo tecnico auxiliar, generado o de infraestructura ligera. No deberia convertirse en un cajon de sastre para logica de negocio.

## Capas por feature

La unidad base de trabajo no es "todo data por un lado y todo UI por otro", sino una feature completa con sus tres capas.

### 1. `domain/`

Es la capa mas estable y la que define el contrato del modulo.

Contiene:

- `entities/`: objetos de negocio inmutables o casi inmutables
- `repositories/`: contratos abstractos, no implementaciones
- `usecases/`: acciones de negocio y reglas puras

Reglas:

- no debe importar `presentation/`
- idealmente tampoco debe depender de detalles concretos de infraestructura
- debe ser la capa mas facil de testear
- un `usecase` debe tener una responsabilidad clara

Ejemplos de responsabilidad validos en `domain/`:

- observar registros
- filtrar resultados
- clasificar estados
- calcular disponibilidad
- ejecutar una accion de negocio

### 2. `data/`

Implementa lo que `domain/` define.

Contiene:

- `datasources/`: acceso a base de datos, API, cache local o proveedor externo
- `models/`: DTOs, normalizacion, `fromMap`, `toMap`, serializacion
- `repositories/`: implementaciones concretas de los contratos de `domain/`

Reglas:

- `datasource` habla con la fuente de datos
- `repository_impl` traduce la necesidad del dominio hacia el datasource
- los modelos resuelven formato tecnico, no reglas de negocio

Patron actual importante:

- los `Model` suelen extender la `Entity`
- esto reduce mapeo y simplifica consumo
- es practico, pero hace que `data` y `domain` queden un poco mas acoplados

Si quieres copiar exactamente la base actual, puedes mantener ese patron. Si quieres una separacion mas estricta, puedes usar composicion en lugar de herencia.

### 3. `presentation/`

Aqui vive la orquestacion del flujo visual.

Contiene:

- `blocs/`: eventos, estados y orquestacion
- `pages/`: pantallas
- `widgets/`: componentes visuales del modulo
- `models/` de UI solo si son necesarios para la capa visual

Reglas:

- una `Page` no debe resolver la logica de negocio pesada
- la `Page` dispara eventos
- el `Bloc` coordina casos de uso y streams
- los widgets renderizan el estado

## Librerias base que sostienen esta arquitectura

### Librerias esenciales

| Libreria | Rol dentro de la base | Nivel |
| --- | --- | --- |
| `flutter` | framework de UI, widgets, navegacion nativa, `MaterialApp`, `Navigator`, `ThemeData` | obligatoria |
| `dart` | lenguaje, tipos, clases, colecciones, async, streams | obligatoria |
| `flutter_bloc` | manejo de estado y eventos, `Bloc`, `BlocProvider`, `BlocConsumer`, `context.read()` | esencial |
| `equatable` | igualdad por valor en entidades, eventos y estados | esencial |
| `get_it` | inyeccion de dependencias y service locator central | esencial |
| `shared_preferences` | persistencia ligera de sesion, flags o configuracion local | soporte base |
| `intl` | formateo de fechas, montos y locale | soporte base |
| `flutter_localizations` | soporte oficial de localizacion de Flutter | soporte base |

### Librerias de presentacion que hoy existen, pero no forman parte del nucleo arquitectonico

Estas librerias son utiles para UI, pero no definen la arquitectura:

| Libreria | Uso tipico |
| --- | --- |
| `table_calendar` | calendarios y rangos de fecha |
| `flutter_sticky_header` | headers pegajosos |
| `carousel_slider` | sliders o carruseles |
| `animations` | transiciones y animaciones predefinidas |
| `sliding_up_panel` | paneles deslizables |

### Tooling de desarrollo que tambien forma parte de la base

| Libreria | Rol |
| --- | --- |
| `flutter_test` | pruebas unitarias y de widgets |
| `flutter_lints` | reglas base de analisis estatico y convenciones |

### Decisiones tecnicas igual de importantes que una libreria

Tambien hay decisiones de base que importan aunque no vengan de un paquete:

- routing con `Navigator` + `onGenerateRoute`
- tema centralizado en `core/theme`
- DI centralizada en `core/di/service_locator.dart`
- sesiones ligeras con cache local
- helpers de UI y widgets compartidos en `shared/`
- casos de uso puros para reglas que deben poder probarse aisladamente

## Librerias y tecnologias que NO se consideran parte de esta base

Se omiten a proposito porque son integraciones externas o de infraestructura especifica:

- cualquier stack de backend o BaaS
- autenticacion externa
- almacenamiento remoto
- mapas y geocodificacion
- permisos del dispositivo
- selectores de imagen o archivos

En un nuevo proyecto estas piezas se agregan despues, sobre la arquitectura base, no antes.

## Flujo tecnico que sigue la aplicacion

### 1. Flujo de arranque

El flujo base de bootstrap es este:

```text
main.dart
  -> inicializa entorno
  -> configura locale y servicios base
  -> ejecuta setupLocator()
  -> recupera sesion/config local
  -> runApp(App)

App
  -> monta providers globales
  -> configura MaterialApp
  -> aplica theme y localizacion
  -> conecta AppRouter
  -> selecciona pantalla inicial
```

Este flujo conviene mantenerlo simple. Si el bootstrap crece demasiado, debe extraerse a servicios o coordinadores, no seguir inflando `main.dart`.

### 2. Flujo de lectura normal

Para consultas u observacion continua de datos:

```text
Page/Widget
  -> dispatch Event al Bloc
Bloc
  -> ejecuta UseCase
UseCase
  -> llama Repository (contrato)
RepositoryImpl
  -> usa DataSource
DataSource
  -> devuelve Future o Stream
Bloc
  -> emite State
UI
  -> renderiza
```

En la base actual hay mucho uso de `Stream`, por eso los BLoCs suelen:

- abrir suscripciones al iniciar
- escuchar varios flujos en paralelo
- transformar resultados en eventos internos
- cancelar suscripciones en `close()`

### 3. Flujo de escritura asincrona importante

Hay un patron recurrente que vale la pena conservar cuando una accion no se confirma de inmediato:

```text
UI
  -> BlocEvent submitted
Bloc
  -> CrearSolicitudUseCase
  -> obtiene requestId / solicitudId
Bloc
  -> WatchSolicitudUseCase(requestId)
  -> espera resultado final
Bloc
  -> emite success o failure
UI
  -> muestra confirmacion, error o estado pendiente
```

Este patron es muy util para:

- operaciones largas
- acciones que requieren confirmacion del backend
- procesos donde no basta con "mandar guardar" y asumir exito

Aunque el backend cambie, la idea arquitectonica sigue siendo valida: separar el comando de la confirmacion.

## Rol exacto del BLoC en esta base

El BLoC no es solo un `setState` con esteroides. En esta base cumple varias funciones concretas:

- recibe eventos de UI
- coordina uno o varios casos de uso
- escucha `StreamSubscription`
- centraliza carga, exito, error y estado vacio
- traduce errores tecnicos a mensajes de UI
- evita que la pagina hable directo con repositorios o datasources

### Estructura recomendada de un BLoC

```text
presentation/
  blocs/
    mi_feature/
      mi_feature_bloc.dart
      mi_feature_event.dart
      mi_feature_state.dart
```

Buenas practicas observadas en el proyecto actual:

- `Event` y `State` extienden `Equatable`
- el `Bloc` recibe dependencias por constructor
- los nombres de estados son explicitos: `Initial`, `Loading`, `Pending`, `Success`, `Failure`
- las suscripciones se cancelan en `close()`
- la UI dispara un evento inicial al montar la pagina

## Inyeccion de dependencias con `get_it`

La aplicacion centraliza todo en un `setupLocator()`.

### Orden recomendado de registro

1. dependencias tecnicas globales
2. cache o storage local
3. datasources
4. repositories
5. usecases
6. blocs

### Convencion util

- `registerLazySingleton` para servicios, datasources, repositories y usecases
- `registerFactory` para BLoCs

Motivo:

- un servicio de datos o repositorio suele ser compartido
- un BLoC normalmente debe crearse nuevo por pantalla o flujo

### Regla clave

La DI debe ser el unico lugar donde se "conoce" la implementacion concreta. Fuera del locator, la app deberia depender de contratos o de abstracciones de uso.

## Navegacion base

La base actual usa navegacion nativa:

- constantes de ruta en `AppRouter`
- `onGenerateRoute`
- `Navigator.pushNamed(...)`
- envio de argumentos por `RouteSettings.arguments`

Esto significa que, si quieres replicar exactamente la base actual, no necesitas introducir `go_router` ni otro paquete de rutas.

Ventajas del enfoque actual:

- simple
- facil de seguir
- centralizado
- suficiente para apps medianas

Si el proyecto nuevo va a tener deep links complejos, shells anidados o navegacion web muy fuerte, ahi si convendria evaluar otra estrategia. Pero eso ya seria una evolucion, no parte de la base actual.

## Tema, locale y sesion

### Tema

Hay una centralizacion simple de tema en `core/theme/app_theme.dart`.

Base recomendada:

- `ThemeData` central
- definicion de modo claro/oscuro si aplica
- evitar colores hardcodeados en muchas pantallas

### Locale

La base usa `intl` y `flutter_localizations` para:

- formato de fechas
- formato regional
- consistencia de idioma

### Sesion ligera

La base actual persiste datos cortos de sesion en storage local y los hidrata al iniciar la app.

Esto sirve para:

- recordar rol
- recuperar `uid` o identificador de sesion
- reanudar flujo inicial

### Nota tecnica importante

Existe tambien un helper global con estado estatico para datos rapidos de sesion. Ese patron funciona, pero en un proyecto nuevo conviene mantenerlo minimo o encapsularlo dentro de un `SessionService` para no multiplicar estado global mutable.

## Convenciones de codigo que conviene conservar

- archivos en `snake_case.dart`
- clases en `PascalCase`
- miembros en `camelCase`
- eventos, estados y entidades con `Equatable`
- metodos cortos y responsabilidades claras
- mapeo y serializacion escritos a mano; hoy no hay code generation base tipo `freezed` o `json_serializable`
- reglas de negocio fuera de la `Page`
- casos de uso pequenos y testeables
- widgets compartidos solo cuando realmente se reutilizan
- naming consistente por feature

## Esqueleto recomendado para una nueva feature

```text
lib/features/mi_feature/
  data/
    datasources/
      mi_feature_remote_datasource.dart
    models/
      mi_feature_model.dart
    repositories/
      mi_feature_repository_impl.dart
  domain/
    entities/
      mi_feature_entity.dart
    repositories/
      mi_feature_repository.dart
    usecases/
      fetch_mi_feature_usecase.dart
      watch_mi_feature_usecase.dart
      create_mi_feature_usecase.dart
  presentation/
    blocs/
      mi_feature/
        mi_feature_bloc.dart
        mi_feature_event.dart
        mi_feature_state.dart
    pages/
      mi_feature_page.dart
    widgets/
      ...
```

## Flujo recomendado para crear una feature nueva

### Orden de implementacion

1. definir la `Entity`
2. definir el contrato de `Repository` en `domain/`
3. crear los `UseCase`
4. implementar `DataSource`
5. crear `Model` y serializacion
6. implementar `RepositoryImpl`
7. registrar todo en `setupLocator()`
8. crear `Bloc`, `Event` y `State`
9. crear `Page` y widgets
10. agregar pruebas

### Preguntas que deberias contestar antes de empezar

- la feature solo lee, o tambien escribe
- la escritura confirma exito de inmediato o requiere observacion posterior
- la regla principal es de UI o de negocio
- la logica debe vivir como `usecase` puro
- hay piezas compartibles entre features o no

## Estrategia de pruebas para esta base

La estructura actual ya refleja una idea correcta: probar primero donde la logica tiene menos ruido de infraestructura.

### Prioridad recomendada

1. `domain/usecases`
2. `data/models`
3. `presentation/blocs`
4. widgets criticos

### Que se debe probar

- reglas puras
- filtros
- clasificaciones
- calculos
- mapeos `fromMap` / `toMap`
- normalizacion de datos
- transiciones de estados del BLoC

### Comandos base

```bash
flutter analyze
flutter test
flutter test --coverage
```

## Decisiones que vale la pena replicar tal cual

- organizar por feature, no por capa global
- usar `domain/` como frontera del negocio
- usar `flutter_bloc` para orquestar la UI
- centralizar dependencias en `get_it`
- separar `core/` de `shared/`
- mantener el router concentrado en un solo punto
- escribir casos de uso pequenos, directos y testeables
- usar `Stream` cuando el dato es observable

## Decisiones que puedes mejorar sin romper la base

Estas mejoras no cambian la esencia de la arquitectura:

- mover el estado global estatico a un servicio de sesion
- endurecer la separacion entre `Model` y `Entity`
- agregar pruebas especificas para BLoCs
- extraer sub-modulos cuando una feature crezca demasiado
- formalizar mas los errores de dominio

## Resumen ejecutivo

Si tuvieras que reconstruir esta base en un proyecto nuevo, la receta seria:

1. Flutter + Dart
2. `flutter_bloc` para estado
3. `equatable` para igualdad por valor
4. `get_it` para DI
5. `shared_preferences` para sesion ligera
6. `intl` + `flutter_localizations` para locale
7. `Navigator` + `onGenerateRoute` para navegacion
8. estructura `core/`, `features/`, `shared/`, `utilities/`
9. cada feature con `data/`, `domain/`, `presentation/`
10. flujo UI -> Bloc -> UseCase -> Repository -> DataSource -> Bloc -> UI

Con eso replicas la base arquitectonica real que hoy se esta usando, pero sin cargar todavia integraciones externas ni detalles del negocio actual.
