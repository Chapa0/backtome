import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:flutter_backtome/shared/utils/mapbox_config.dart';
import 'package:flutter_backtome/shared/services/mapbox_geocoding_service.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

class MapboxLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapboxLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapboxLocationPicker> createState() => _MapboxLocationPickerState();
}

class _MapboxLocationPickerState extends State<MapboxLocationPicker> {
  mb.MapboxMap? _mapboxMap;
  mb.CircleAnnotationManager? _circleManager;
  mb.CircleAnnotation? _pinAnnotation;

  final _geocodingService = MapboxGeocodingService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<MapboxPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  double _selectedLat = 19.1738;
  double _selectedLng = -96.1342;
  bool _hasPin = false;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLat = widget.initialLatitude!;
      _selectedLng = widget.initialLongitude!;
      _hasPin = true;
    }
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (hasPermission) {
        final position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        if (widget.initialLatitude == null && widget.initialLongitude == null) {
          _selectedLat = position.latitude;
          _selectedLng = position.longitude;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLocation = false);
  }

  Future<bool> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isRestricted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onStyleLoaded(mb.StyleLoadedEventData _) async {
    _circleManager = await _mapboxMap!.annotations.createCircleAnnotationManager();
    if (_hasPin) {
      _placePin(_selectedLat, _selectedLng);
    }
  }

  void _onMapLongTap(mb.MapContentGestureContext context) {
    final point = context.point;
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();

    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _hasPin = true;
    });
    _placePin(lat, lng);
  }

  Future<void> _placePin(double lat, double lng) async {
    if (_circleManager == null) return;

    // Remove previous pin
    if (_pinAnnotation != null) {
      try { await _circleManager!.delete(_pinAnnotation!); } catch (_) {}
    }

    try {
      _pinAnnotation = await _circleManager!.create(
        mb.CircleAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(lng, lat)),
          circleColor: 0xFFE53935,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
          circleRadius: 10,
        ),
      );
    } catch (e) {
      debugPrint('Error placing pin: $e');
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim().isEmpty) {
        if (mounted) setState(() { _searchResults = []; _isSearching = false; });
        return;
      }
      if (mounted) setState(() => _isSearching = true);
      final results = await _geocodingService.search(query);
      if (!mounted) return;
      setState(() { _searchResults = results; _isSearching = false; });
    });
  }

  void _onPlaceSelected(MapboxPlace place) {
    _searchController.text = place.label;
    _searchFocusNode.unfocus();
    setState(() => _searchResults = []);

    _mapboxMap?.flyTo(
      mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(place.longitud, place.latitud)),
        zoom: 16,
      ),
      mb.MapAnimationOptions(duration: 400),
    );

    setState(() {
      _selectedLat = place.latitud;
      _selectedLng = place.longitud;
      _hasPin = true;
    });
    _placePin(place.latitud, place.longitud);
  }

  void _onConfirm() {
    if (!_hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manten presionado el mapa para colocar un pin.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'latitud': _selectedLat,
      'longitud': _selectedLng,
    });
  }

  void _onMyLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      _mapboxMap?.flyTo(
        mb.CameraOptions(
          center: mb.Point(
            coordinates: mb.Position(position.longitude, position.latitude),
          ),
          zoom: 16,
        ),
        mb.MapAnimationOptions(duration: 400),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicacion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _onConfirm,
            tooltip: 'Confirmar ubicacion',
          ),
        ],
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: mb.MapWidget(
                    key: const ValueKey('locationPickerMap'),
                    viewport: mb.CameraViewportState(
                      center: mb.Point(
                        coordinates: mb.Position(_selectedLng, _selectedLat),
                      ),
                      zoom: (widget.initialLatitude != null) ? 16 : 12,
                    ),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    onLongTapListener: _onMapLongTap,
                  ),
                ),
                // Hint text at top when no pin placed yet
                if (!_hasPin)
                  Positioned(
                    top: 8, left: 8, right: 8,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withOpacity(0.9),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text('Manten presionado el mapa para colocar un pin',
                            style: TextStyle(color: Colors.black87, fontSize: 14)),
                      ),
                    ),
                  ),
                // Search bar
                Positioned(
                  top: _hasPin ? 8 : 52,
                  left: 8,
                  right: 56,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Buscar lugar...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final place = _searchResults[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(place.nombre),
                                  subtitle: Text(place.direccion,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  onTap: () => _onPlaceSelected(place),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // My location button
                Positioned(
                  right: 8,
                  bottom: 32,
                  child: FloatingActionButton.small(
                    heroTag: 'myLocation',
                    onPressed: _onMyLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
              ],
            ),
    );
  }
}
