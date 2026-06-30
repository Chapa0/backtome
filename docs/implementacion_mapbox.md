# Implementacion de Mapbox en Almeet

> Documento de referencia tecnica para replicar la integracion de Mapbox en otros proyectos Flutter.
> Cubre unicamente la capa de infraestructura: como se renderiza el mapa, se gestionan marcadores, se obtiene la ubicacion y se trazan rutas.

---

## 1. Dependencias

### Pubspec (`pubspec.yaml`)

```yaml
mapbox_maps_flutter: ^2.23.1   # SDK oficial Mapbox para Flutter (renderer GL JS v3)
geolocator: ^12.0.0            # GPS / posicion del dispositivo
permission_handler: ^11.3.1    # Permisos de ubicacion
dio: ^5.7.0                    # HTTP client para APIs REST de Mapbox
```

- `mapbox_maps_flutter` v2.x usa Metal/Vulkan como backend de renderizado y requiere **OpenGL ES 3.0** en Android.
- Soporte: se verifica en runtime via method channel `almeet/device_capabilities` (clase `DeviceCapabilitiesService`). Solo en Android; en iOS/otros retorna `true`.

### Archivos clave de configuracion

| Archivo | Proposito |
|---|---|
| `lib/shared/utils/mapbox_config.dart` | Singleton del access token |
| `lib/shared/utils/mapbox_ornaments.dart` | Configuracion de logos/atribucion en el mapa |
| `lib/shared/services/device_capabilities_service.dart` | Verifica OpenGL ES 3.0 en Android |
| `lib/core/update/services/local_bootstrap_secrets_service.dart` | Siembra inicial del token desde `assets/local/bootstrap_secrets.json` |
| `lib/core/update/services/update_storage_keys.dart` | Clave `mapbox_access_token` en secure storage |

---

## 2. Inicializacion del Access Token

### Flujo de arranque (`lib/main.dart`)

```
main()
  → seedSecureStorageFromLocalAsset() carga token desde assets/local/bootstrap_secrets.json (primer arranque)
  → FlutterSecureStorage.read(key: 'mapbox_access_token')
  → MapboxConfig.configure(accessToken: token)
  → MapboxOptions.setAccessToken(token)   ← SDK-level
```

### Singleton `MapboxConfig` (`lib/shared/utils/mapbox_config.dart`)

```dart
class MapboxConfig {
  static const _mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const _legacyToken  = String.fromEnvironment('ACCESS_TOKEN');
  static String _runtimeToken = '';

  static void configure({required String accessToken}) {
    _runtimeToken = accessToken.trim();
  }

  static String get accessToken {
    if (_runtimeToken.isNotEmpty) return _runtimeToken;
    if (_mapboxToken.isNotEmpty)  return _mapboxToken;
    return _legacyToken;
  }

  static bool get hasToken => accessToken.isNotEmpty;
}
```

**Prioridad de resolucion:**
1. Token seteado en runtime (`configure()`)
2. Variable de compilacion `MAPBOX_ACCESS_TOKEN`
3. Variable de compilacion `ACCESS_TOKEN`

---

## 3. Widget del Mapa (`MapWidget`)

### Constructor base (usado en los 3 lugares del proyecto)

```dart
MapWidget(
  key: const ValueKey('identificadorUnico'),
  styleUri: MapboxStyles.MAPBOX_STREETS,  // estilo de calles estandar
  viewport: _initialViewport,              // CameraViewportState
  onMapCreated: (mapboxMap) => _onMapCreated(mapboxMap),
  onStyleLoadedListener: (_) => _onStyleLoaded(),
);
```

- **`styleUri`**: Siempre `MapboxStyles.MAPBOX_STREETS` (estilo de calles built-in).
- **`viewport`**: `CameraViewportState` con centro y zoom inicial.
- **`onMapCreated`**: Callback que recibe la instancia `MapboxMap` — punto de entrada para toda interaccion con el mapa.
- **`onStyleLoadedListener`**: Se dispara cuando el estilo termino de cargarse — momento seguro para crear annotation managers.

### Coordenadas por defecto

Todos los mapas usan el mismo fallback (zona de Veracruz, Mexico):

```dart
const double _defaultMapLatitude  = 19.1738;
const double _defaultMapLongitude = -96.1342;
```

---

## 4. Ornamentos (Logo y Atribucion)

`MapboxOrnaments.applyDefaultSettings()` — llamado en cada `onMapCreated`:

```dart
static Future<void> applyDefaultSettings(MapboxMap mapboxMap) async {
  await mapboxMap.logo.updateSettings(
    LogoSettings(position: OrnamentPosition.BOTTOM_RIGHT, marginRight: 4, marginBottom: 4),
  );
  await mapboxMap.attribution.updateSettings(
    AttributionSettings(
      position: OrnamentPosition.BOTTOM_RIGHT,
      marginRight: 96,
      marginBottom: 4,
      clickable: false,
    ),
  );
}
```

---

## 5. Annotation Managers (Marcadores y Lineas)

Se crean **3 managers** una sola vez en `onStyleLoaded` y se reusan durante toda la vida del mapa:

```dart
_circleManager    = await mapboxMap.annotations.createCircleAnnotationManager();
_pointManager     = await mapboxMap.annotations.createPointAnnotationManager();
_routeLineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
```

| Manager | Uso |
|---|---|
| `CircleAnnotationManager` | Puntos circulares de pedidos (entrega/recogida) y halo de seleccion |
| `PointAnnotationManager` | Etiquetas de texto sobre los circulos (`E` / `R`) y punto de ubicacion actual |
| `PolylineAnnotationManager` | Linea de ruta entre pedidos |

### Listeners de tap

```dart
_circleManager.tapEvents(onTap: _onCircleMarkerTapped);
_pointManager.tapEvents(onTap: _onPointMarkerTapped);
```

Ambos extraen `customData['pedidoId']` y `customData['tipo']` para identificar que pedido fue tocado y disparar la seleccion.

---

## 6. Marcadores de Pedidos

Cada `PedidoMapaItem` en el mapa genera **2 circulos + 1 punto de texto**.

### Circulo principal

```dart
CircleAnnotationOptions(
  geometry: Point(coordinates: Position(lng, lat)),
  circleColor: tipo == entrega ? 0xFF1769E0 : 0xFF13A36B,  // azul / verde
  circleStrokeColor: Colors.white.toARGB32(),
  circleStrokeWidth: 3,
  circleRadius: seleccionado ? 16 : 12,
  circleSortKey: seleccionado ? 4 : 1,
  customData: { 'pedidoId': item.pedido.id, 'tipo': item.tipo.name },
);
```

| Tipo | Color | Etiqueta |
|---|---|---|
| Entrega (delivery) | Azul `#1769E0` | `E` |
| Recogida (pickup) | Verde `#13A36B` | `R` |

### Halo de seleccion

Cuando un marcador esta seleccionado, se dibuja un anillo dorado adicional:

```dart
CircleAnnotationOptions(
  circleColor: 0x1AF59E0B,       // dorado translucido
  circleStrokeColor: 0xFFF59E0B, // dorado solido
  circleStrokeWidth: 4,
  circleRadius: 24,
  circleSortKey: 3,              // entre el normal (1) y el seleccionado (4)
);
```

### Etiqueta de texto

```dart
PointAnnotationOptions(
  geometry: Point(coordinates: Position(lng, lat)),
  text: tipo == entrega ? 'E' : 'R',
  textColor: Colors.white,
  textSize: seleccionado ? 14 : 12,
  textHaloColor: seleccionado ? dorado : colorMarcador,
  textHaloWidth: 1,
  textIgnorePlacement: true,
);
```

### Marcador de posicion actual (conductor)

Doble circulo azul en la ubicacion GPS del dispositivo:

```dart
// Exterior (translucido)
CircleAnnotationOptions(
  circleColor: 0x3340A9FF,
  circleRadius: 20,
  circleStrokeColor: 0x662F80ED,
  circleStrokeWidth: 2,
  circleSortKey: 0,
);
// Interior (solido)
CircleAnnotationOptions(
  circleColor: 0xFF2F80ED,
  circleRadius: 8,
  circleStrokeColor: Colors.white,
  circleStrokeWidth: 3,
  circleSortKey: 5,  // por encima de todo
);
```

---

## 7. Location Puck (Indicador nativo de ubicacion)

Ademas del marcador de doble circulo, se activa el componente nativo de localizacion del SDK:

```dart
await mapboxMap.location.updateSettings(
  LocationComponentSettings(
    enabled: true,
    pulsingEnabled: true,
    pulsingColor: const Color(0xFF2F80ED).toARGB32(),
    showAccuracyRing: true,
    accuracyRingColor: const Color(0x3340A9FF).toARGB32(),
    accuracyRingBorderColor: const Color(0x662F80ED).toARGB32(),
  ),
);
```

---

## 8. Obtencion de la Ubicacion (GPS)

Usa `geolocator` (`package:geolocator/geolocator.dart` as `geo`):

```dart
// 1. Verificar servicios de ubicacion activados
final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();

// 2. Verificar/solicitar permiso
final permission = await geo.Geolocator.checkPermission();
if (permission == geo.LocationPermission.denied) {
  await geo.Geolocator.requestPermission();
}

// 3. Obtener posicion (8s timeout)
final position = await geo.Geolocator.getCurrentPosition(
  desiredAccuracy: geo.LocationAccuracy.high,
).timeout(const Duration(seconds: 8));

// 4. Convertir a Point de Mapbox
final point = Point(coordinates: Position(position.longitude, position.latitude));
```

### Seguimiento en tiempo real (cuando hay ruta activa)

```dart
geo.Geolocator.getPositionStream(
  locationSettings: const geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 25,  // metros — actualiza cada 25m
  ),
).listen((position) {
  // recalcula ruta si el conductor se desvia >50m o >80m de la geometria
});
```

---

## 9. Polylinea de Ruta

### Trazado de la linea en el mapa

```dart
await _routeLineManager.create(
  PolylineAnnotationOptions(
    geometry: LineString(coordinates: [
      Position(lng1, lat1),
      Position(lng2, lat2),
      // ...
    ]),
    lineColor: const Color(0xFF111827).toARGB32(),  // gris oscuro
    lineWidth: 5,
    lineSortKey: 0,  // detras de los marcadores
  ),
);
```

### Obtencion de la geometria (API Directions)

`MapboxDirectionsService` consulta:

```
GET https://api.mapbox.com/directions/v5/mapbox/driving-traffic/{coords}
  ?geometries=geojson
  &overview=full
  &access_token={token}
```

Donde `{coords}` es una lista de `lng,lat` separados por `;`.

La respuesta se parsea a `RutaDirectionsEntity` que contiene `List<Position>` (geometria decodificada).

---

## 10. Operaciones de Camara

### Viewport inicial

```dart
CameraViewportState(
  center: Point(coordinates: Position(longitud, latitud)),
  zoom: 12,  // 11 por defecto, 15 si hay ubicacion conocida
)
```

### Metodos de camara usados

| Metodo | Animacion | Uso |
|---|---|---|
| `mapboxMap.setCamera(CameraOptions(...))` | Instantaneo | Ajustar vista a todos los pedidos |
| `mapboxMap.easeTo(camera, MapAnimationOptions(duration: 300))` | Suave 300ms | Centrar en ubicacion, centrar ruta |
| `mapboxMap.flyTo(camera, MapAnimationOptions(duration: 500))` | Vuelo 500ms | Location picker al seleccionar punto |
| `mapboxMap.cameraForCoordinatesPadding(points, CameraOptions(), padding, maxZoom, null)` | — | Calcular encuadre optimo que contenga todos los puntos |

### Paddings tipicos

| Contexto | Padding |
|---|---|
| Ajustar todos los pedidos | `top:56, left:48, bottom:300, right:48` |
| Centrar ruta completa | `top:80, left:40, bottom:360, right:40` |
| Centrar en usuario | zoom 16, sin padding extra |

---

## 11. Location Picker (Seleccion de ubicacion con busqueda)

Widget reutilizable: `MapboxLocationPicker` (`lib/shared/widgets/location/mapbox_location_picker.dart`).

### Funcionalidades

- **Busqueda por texto**: Campo con debounce de 450ms que consulta `MapboxGeocodingService`.
- **Long press en el mapa**: Crea un `PedidoUbicacion` con label `"Pin seleccionado"` en las coordenadas del tap.
- **Marcador rojo**: Circulo rojo (radio 8, borde blanco 3px) en la ubicacion seleccionada.
- **Retorno**: Al confirmar, hace `Navigator.pop(context, ubicacion)`.

### API de Geocoding

`MapboxGeocodingService` consulta:

```
GET https://api.mapbox.com/search/geocode/v6/forward
  ?q={query}
  &language=es
  &country=mx
  &limit=6
  &proximity=-99.1332,19.4326   ← centroide CDMX
  &access_token={token}
```

Retorna `List<PedidoUbicacion>` con `latitud`, `longitud` y `label` (formato `"name, place_formatted"`).

---

## 12. Resumen del Flujo Completo

```
APP INICIA
  │
  ├─ SecureStorage → MapboxConfig.configure(token)
  ├─ MapboxOptions.setAccessToken(token)
  │
  ▼
PAGINA DEL MAPA (ConductorMapaPage)
  │
  ├─ initState()
  │   ├─ _initialViewport (coords default, zoom 12)
  │   ├─ _loadMapboxRendererSupport() → OpenGL ES 3.0 check
  │   └─ BLoC → emite PedidosMapaConductorStarted
  │
  ├─ build() → MapWidget
  │   ├─ onMapCreated → _onMapCreated
  │   │   ├─ guarda MapboxMap
  │   │   ├─ MapboxOrnaments.applyDefaultSettings()
  │   │   └─ crea 3 annotation managers
  │   │
  │   └─ onStyleLoaded → _onStyleLoaded
  │       ├─ _ensureAnnotationManagers()
  │       ├─ _renderMarkers()        ← circulos + textos de pedidos
  │       ├─ _renderRouteLine()      ← polylinea de ruta
  │       └─ _fitInitialCamera()     ← encuadre de todos los puntos
  │
  ├─ BLoC escucha Firestore
  │   ├─ stream entregas + recogidas
  │   ├─ emite List<PedidoMapaItem>
  │   └─ _onStateChanged → re-render markers + route
  │
  ├─ GPS (geolocator)
  │   ├─ getCurrentPosition() → _currentLocationPoint
  │   ├─ _enableLocationPuck()
  │   ├─ _drawCurrentLocationMarker()
  │   └─ getPositionStream() → tracking en vivo
  │
  └─ Interaccion
      ├─ Tap en marcador → _selectItem → re-render con halo dorado
      ├─ Boton "Mi ubicacion" → easeTo zoom 16
      └─ Ruta activa → RutaOrderPlanner → DirectionsService → polylinea
```

---

## 13. Archivos Clave de Referencia

| Archivo | Responsabilidad |
|---|---|
| `lib/shared/utils/mapbox_config.dart` | Token singleton |
| `lib/shared/utils/mapbox_ornaments.dart` | Logo/atribucion |
| `lib/shared/services/mapbox_geocoding_service.dart` | Geocoding forward |
| `lib/shared/services/mapbox_directions_service.dart` | Driving directions |
| `lib/shared/services/device_capabilities_service.dart` | OpenGL ES 3.0 check |
| `lib/shared/widgets/location/mapbox_location_picker.dart` | Picker de ubicacion con busqueda |
| `lib/features/conductor/presentation/pages/home/conductor_mapa_page.dart` | Pagina principal del mapa (1066 lines) |
| `lib/features/conductor/presentation/pages/pedidos/widgets/pedido_map_preview.dart` | Preview de una ubicacion |
| `lib/features/conductor/presentation/blocs/pedidos_mapa_conductor/` | BLoC del mapa (eventos, estados, planner de ruta) |
| `lib/shared/domain/entities/pedido_ubicacion.dart` | Modelo de ubicacion (`latitud`, `longitud`, `label`, `sourceMapboxPin`) |
| `lib/features/conductor/domain/entities/ruta_directions_entity.dart` | Entidad de ruta con geometria |
| `lib/main.dart` | Inicializacion del token al arranque |
| `lib/core/update/services/local_bootstrap_secrets_service.dart` | Siembra inicial del token |
