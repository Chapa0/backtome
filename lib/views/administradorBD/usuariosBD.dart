class Usuario {
  String id;
  String nombre;
  String apellido;
  String correo;
  String urlimagen='';



  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.urlimagen,


  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'urlimagen': urlimagen,



    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      correo: map['correo'] ?? '',
      urlimagen: map['urlimagen'] ?? '',
    );
  }

}
