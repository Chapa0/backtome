import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

class MapboxLocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const MapboxLocationPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<MapboxLocationPicker> createState() => _MapboxLocationPickerState();
}

class _MapboxLocationPickerState extends State<MapboxLocationPicker> {
  mb.MapboxMap? _mapboxMap;
  mb.PointAnnotationManager? _pointManager;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onStyleLoaded(mb.StyleLoadedEventData _) async {
    if (_mapboxMap == null) return;
    _pointManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    await _pointManager!.create(
      mb.PointAnnotationOptions(
        geometry: mb.Point(
          coordinates: mb.Position(widget.initialLongitude, widget.initialLatitude),
        ),
        iconImage: 'pin',
      ),
    );
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'latitud': widget.initialLatitude,
      'longitud': widget.initialLongitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicacion'),
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          mb.MapWidget(
            key: const ValueKey('pickerMap'),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),
          const IgnorePointer(
            child: Center(
              child: Icon(Icons.location_on, color: Colors.red, size: 48),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.check),
        label: const Text('Confirmar'),
        onPressed: _onConfirm,
      ),
    );
  }
}
