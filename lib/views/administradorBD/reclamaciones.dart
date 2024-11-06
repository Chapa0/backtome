class Reclamacion {
  final String uidReclamante;
  final String nombreReclamante;
  final String estadoReclamacion;
  final String textoReclamacion;
  final String? imagenReclamacionUrl;

  Reclamacion({
    required this.uidReclamante,
    required this.nombreReclamante,
    required this.estadoReclamacion,
    required this.textoReclamacion,
    this.imagenReclamacionUrl,
  });

  factory Reclamacion.fromMap(Map<String, dynamic> data) {
    return Reclamacion(
      uidReclamante: data['uidReclamante'],
      nombreReclamante: data['nombreReclamante'],
      estadoReclamacion: data['estadoReclamacion'],
      textoReclamacion: data['textoReclamacion'],
      imagenReclamacionUrl: data['imagenReclamacionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uidReclamante': uidReclamante,
      'nombreReclamante': nombreReclamante,
      'estadoReclamacion': estadoReclamacion,
      'textoReclamacion': textoReclamacion,
      'imagenReclamacionUrl': imagenReclamacionUrl,
    };
  }
}
