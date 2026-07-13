import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';

class LostObject {
  // Campos existentes
  final String id;
  final String descripcion;
  final String tipoObjeto;
  final String tipoOBjetoBusqueda;
  final String lugarEncontrado;
  final String imagenUrl;
  final String nombreEncontrado;
  final String uidEncontrado;
  final DateTime timestamp;
  late bool? aprobado;
  bool? rechazado;
  final List<String>? imageUrls;
  String? estadoReclamacion;
  List<Reclamacion> reclamaciones;

  // Ubicacion real (lat/lng)
  double? latitud;
  double? longitud;

  // Nuevos campos
  String? uidReclamado;
  String? nombreReclamado;
  String? custodiaEstado;
  String? custodiaUid;
  String? custodiaNombre;
  String? puntoCustodiaId;
  String? puntoCustodiaNombre;
  double? puntoCustodiaLatitud;
  double? puntoCustodiaLongitud;
  DateTime? fechaRecepcionPunto;

  LostObject({
    required this.id,
    required this.descripcion,
    required this.tipoObjeto,
    required this.tipoOBjetoBusqueda,
    required this.lugarEncontrado,
    required this.imagenUrl,
    required this.nombreEncontrado,
    required this.uidEncontrado,
    required this.timestamp,
    required this.aprobado,
    this.rechazado,
    required this.imageUrls,
    required this.reclamaciones,
    required this.estadoReclamacion,
    this.latitud,
    this.longitud,
    this.uidReclamado,
    this.nombreReclamado,
    this.custodiaEstado,
    this.custodiaUid,
    this.custodiaNombre,
    this.puntoCustodiaId,
    this.puntoCustodiaNombre,
    this.puntoCustodiaLatitud,
    this.puntoCustodiaLongitud,
    this.fechaRecepcionPunto,
  });

  bool get estaEnPuntoCustodia => custodiaEstado == 'en_punto';

  bool get canBeDeleted {
    final hasClaimLifecycle = reclamaciones.isNotEmpty ||
        estadoReclamacion == 'Pendiente' ||
        estadoReclamacion == 'Entregado';
    final hasCustodyLifecycle =
        estaEnPuntoCustodia || fechaRecepcionPunto != null;
    return !hasClaimLifecycle && !hasCustodyLifecycle;
  }

  String get deletionBlockedReason {
    if (estadoReclamacion == 'Entregado') {
      return 'Este objeto ya fue entregado y debe conservarse como historial.';
    }
    if (estaEnPuntoCustodia || fechaRecepcionPunto != null) {
      return 'Este objeto esta en un punto de entrega y no puede eliminarse.';
    }
    if (reclamaciones.isNotEmpty || estadoReclamacion == 'Pendiente') {
      return 'Este objeto tiene reclamaciones y no puede eliminarse.';
    }
    return '';
  }

  String get custodiaLabel {
    if (estaEnPuntoCustodia && (puntoCustodiaNombre ?? '').isNotEmpty) {
      return puntoCustodiaNombre!;
    }

    if ((custodiaNombre ?? '').isNotEmpty) {
      return custodiaNombre!;
    }

    return nombreEncontrado;
  }

  factory LostObject.fromMap(Map<String, dynamic> data, String documentId) {
    // Parsear la lista de reclamaciones
    List<Reclamacion> reclamaciones = [];
    if (data['reclamaciones'] != null) {
      var list = data['reclamaciones'] as List;
      reclamaciones = list.map((item) => Reclamacion.fromMap(item)).toList();
    }

    return LostObject(
      id: documentId,
      descripcion: data['descripcion'] ?? '',
      tipoObjeto: data['tipoObjeto'] ?? '',
      tipoOBjetoBusqueda: data['tipoObjetoBusqueda'] ?? '',
      lugarEncontrado: data['lugarEncontrado'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      nombreEncontrado: data['nombreEncontrado'] ?? '',
      uidEncontrado: data['uidEncontrado'] ?? '',
      timestamp: _parseDate(data['timestamp']) ?? DateTime.now(),
      aprobado: data['aprobado'],
      rechazado: data['rechazado'],
      imageUrls:
          data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : [],
      reclamaciones: reclamaciones,
      estadoReclamacion: data['estadoReclamacion'] ?? '',
      latitud:
          data['latitud'] != null ? (data['latitud'] as num).toDouble() : null,
      longitud: data['longitud'] != null
          ? (data['longitud'] as num).toDouble()
          : null,
      uidReclamado: data['uidReclamado'],
      nombreReclamado: data['nombreReclamado'],
      custodiaEstado: data['custodiaEstado'] ?? 'con_usuario',
      custodiaUid: data['custodiaUid'] ?? data['uidEncontrado'],
      custodiaNombre: data['custodiaNombre'] ?? data['nombreEncontrado'],
      puntoCustodiaId: data['puntoCustodiaId'],
      puntoCustodiaNombre: data['puntoCustodiaNombre'],
      puntoCustodiaLatitud: data['puntoCustodiaLatitud'] != null
          ? (data['puntoCustodiaLatitud'] as num).toDouble()
          : null,
      puntoCustodiaLongitud: data['puntoCustodiaLongitud'] != null
          ? (data['puntoCustodiaLongitud'] as num).toDouble()
          : null,
      fechaRecepcionPunto: _parseDate(data['fechaRecepcionPunto']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'tipoObjeto': tipoObjeto,
      'tipoObjetoBusqueda': tipoOBjetoBusqueda,
      'lugarEncontrado': lugarEncontrado,
      'imagenUrl': imagenUrl,
      'nombreEncontrado': nombreEncontrado,
      'uidEncontrado': uidEncontrado,
      'timestamp': timestamp,
      'aprobado': aprobado,
      'rechazado': rechazado,
      'imageUrls': imageUrls,
      'reclamaciones':
          reclamaciones.map((reclamacion) => reclamacion.toMap()).toList(),
      'estadoReclamacion': estadoReclamacion,
      'latitud': latitud,
      'longitud': longitud,
      'uidReclamado': uidReclamado,
      'nombreReclamado': nombreReclamado,
      'custodiaEstado': custodiaEstado,
      'custodiaUid': custodiaUid,
      'custodiaNombre': custodiaNombre,
      'puntoCustodiaId': puntoCustodiaId,
      'puntoCustodiaNombre': puntoCustodiaNombre,
      'puntoCustodiaLatitud': puntoCustodiaLatitud,
      'puntoCustodiaLongitud': puntoCustodiaLongitud,
      'fechaRecepcionPunto': fechaRecepcionPunto,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final dynamic candidate = value;
    try {
      final converted = candidate.toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
