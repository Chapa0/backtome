import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_backtome/shared/utils/mapbox_config.dart';

class MapboxGeocodingService {
  final Dio _dio = Dio();

  Future<List<MapboxPlace>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final token = MapboxConfig.accessToken;
    final response = await _dio.get(
      'https://api.mapbox.com/search/geocode/v6/forward',
      queryParameters: {
        'q': query,
        'language': 'es',
        'limit': 6,
        'access_token': token,
      },
    );

    final features = response.data['features'] as List? ?? [];
    return features.map((f) => MapboxPlace.fromFeature(f)).toList();
  }
}

class MapboxPlace {
  final double latitud;
  final double longitud;
  final String nombre;
  final String direccion;

  MapboxPlace({
    required this.latitud,
    required this.longitud,
    required this.nombre,
    required this.direccion,
  });

  String get label => direccion.isNotEmpty ? '$nombre, $direccion' : nombre;

  factory MapboxPlace.fromFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final coords = feature['geometry']?['coordinates'] as List? ?? [0, 0];

    return MapboxPlace(
      longitud: (coords[0] as num).toDouble(),
      latitud: (coords[1] as num).toDouble(),
      nombre: props['name']?.toString() ?? '',
      direccion: props['place_formatted']?.toString() ?? '',
    );
  }
}
