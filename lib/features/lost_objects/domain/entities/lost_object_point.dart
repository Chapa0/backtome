class LostObjectPoint {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double latitud;
  final double longitud;
  final bool activo;

  const LostObjectPoint({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.latitud,
    required this.longitud,
    required this.activo,
  });

  bool get permiteEntrega => tipo == 'entrega' || tipo == 'ambos';

  bool get permiteReclamacion => tipo == 'reclamacion' || tipo == 'ambos';

  String get tipoLabel {
    switch (tipo) {
      case 'entrega':
        return 'Entrega';
      case 'reclamacion':
        return 'Reclamacion';
      case 'ambos':
        return 'Entrega y reclamacion';
      default:
        return tipo;
    }
  }

  factory LostObjectPoint.fromMap(Map<String, dynamic> data, String id) {
    return LostObjectPoint(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      tipo: data['tipo'] ?? 'ambos',
      latitud: data['latitud'] != null
          ? (data['latitud'] as num).toDouble()
          : 19.1738,
      longitud: data['longitud'] != null
          ? (data['longitud'] as num).toDouble()
          : -96.1342,
      activo: data['activo'] ?? true,
    );
  }

  Map<String, dynamic> toRequestPayload() {
    return {
      if (id.isNotEmpty) 'puntoId': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'latitud': latitud,
      'longitud': longitud,
      'activo': activo,
    };
  }
}
