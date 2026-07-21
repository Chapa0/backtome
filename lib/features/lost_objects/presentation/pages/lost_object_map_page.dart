import 'package:flutter/material.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/shared/widgets/location/delivery_point_marker_image.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

class LostObjectMapPage extends StatefulWidget {
  final LostObject lostObject;

  const LostObjectMapPage({
    super.key,
    required this.lostObject,
  });

  @override
  State<LostObjectMapPage> createState() => _LostObjectMapPageState();
}

class _LostObjectMapPageState extends State<LostObjectMapPage> {
  mb.MapboxMap? _mapboxMap;
  mb.CircleAnnotationManager? _foundLocationManager;
  mb.PointAnnotationManager? _deliveryPointManager;

  bool get _hasFoundLocation =>
      widget.lostObject.latitud != null && widget.lostObject.longitud != null;

  bool get _hasPickupPoint =>
      widget.lostObject.estaEnPuntoCustodia &&
      widget.lostObject.puntoCustodiaLatitud != null &&
      widget.lostObject.puntoCustodiaLongitud != null;

  mb.CameraViewportState get _initialViewport {
    final latitude = widget.lostObject.latitud ??
        widget.lostObject.puntoCustodiaLatitud ??
        19.1738;
    final longitude = widget.lostObject.longitud ??
        widget.lostObject.puntoCustodiaLongitud ??
        -96.1342;
    return mb.CameraViewportState(
      center: mb.Point(coordinates: mb.Position(longitude, latitude)),
      zoom: 15,
    );
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null) return;

    _foundLocationManager =
        await map.annotations.createCircleAnnotationManager();
    _deliveryPointManager =
        await map.annotations.createPointAnnotationManager();

    await _renderLocations();
    await _fitCameraToLocations();
  }

  Future<void> _renderLocations() async {
    if (_hasFoundLocation && _foundLocationManager != null) {
      await _foundLocationManager!.create(
        mb.CircleAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(
              widget.lostObject.longitud!,
              widget.lostObject.latitud!,
            ),
          ),
          circleColor: 0xFFEF5350,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 4,
          circleRadius: 12,
          circleSortKey: 1,
        ),
      );
    }

    if (_hasPickupPoint && _deliveryPointManager != null) {
      final marker = await DeliveryPointMarkerImage.build(highlighted: true);
      await _deliveryPointManager!.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(
              widget.lostObject.puntoCustodiaLongitud!,
              widget.lostObject.puntoCustodiaLatitud!,
            ),
          ),
          image: marker,
          iconAnchor: mb.IconAnchor.BOTTOM,
          iconSize: 0.72,
          symbolSortKey: 3,
        ),
      );
    }
  }

  Future<void> _fitCameraToLocations() async {
    final map = _mapboxMap;
    if (map == null) return;

    final coordinates = <mb.Point>[];
    if (_hasFoundLocation) {
      coordinates.add(
        mb.Point(
          coordinates: mb.Position(
            widget.lostObject.longitud!,
            widget.lostObject.latitud!,
          ),
        ),
      );
    }
    if (_hasPickupPoint) {
      coordinates.add(
        mb.Point(
          coordinates: mb.Position(
            widget.lostObject.puntoCustodiaLongitud!,
            widget.lostObject.puntoCustodiaLatitud!,
          ),
        ),
      );
    }
    if (coordinates.isEmpty) return;

    if (coordinates.length == 1) {
      await map.setCamera(
        mb.CameraOptions(center: coordinates.first, zoom: 16),
      );
      return;
    }

    final camera = await map.cameraForCoordinatesPadding(
      coordinates,
      mb.CameraOptions(),
      mb.MbxEdgeInsets(top: 80, left: 56, bottom: 250, right: 56),
      15,
      null,
    );
    await map.setCamera(camera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ubicaciones del objeto',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B396A),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: mb.MapWidget(
              key: ValueKey('lostObjectMap-${widget.lostObject.id}'),
              viewport: _initialViewport,
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _LocationSummary(
              object: widget.lostObject,
              hasFoundLocation: _hasFoundLocation,
              hasPickupPoint: _hasPickupPoint,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  final LostObject object;
  final bool hasFoundLocation;
  final bool hasPickupPoint;

  const _LocationSummary({
    required this.object,
    required this.hasFoundLocation,
    required this.hasPickupPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasFoundLocation)
              _LegendRow(
                marker: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
                title: 'Lugar donde fue encontrado',
                subtitle: object.lugarEncontrado,
              ),
            if (hasFoundLocation && hasPickupPoint) const Divider(height: 24),
            if (hasPickupPoint)
              _LegendRow(
                marker: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D77),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: 'Recógelo en el punto de entrega',
                subtitle: object.puntoCustodiaNombre ?? 'Punto de entrega',
              )
            else
              _LegendRow(
                marker: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1B396A),
                  size: 28,
                ),
                title: 'Aún no está en un punto de entrega',
                subtitle: 'Custodia actual: ${object.custodiaLabel}',
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Widget marker;
  final String title;
  final String subtitle;

  const _LegendRow({
    required this.marker,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 40, child: Center(child: marker)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }
}
