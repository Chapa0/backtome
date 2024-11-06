// lost_object_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/reclamaciones.dart';
import '../administradorBD/usuariosBD.dart';
import 'fullscreen_image_detail.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LostObjectDetailPage extends StatefulWidget {
  final LostObject lostObject;

  LostObjectDetailPage({required this.lostObject});

  @override
  _LostObjectDetailPageState createState() => _LostObjectDetailPageState();
}

class _LostObjectDetailPageState extends State<LostObjectDetailPage> {
  final Color _primaryColor = Color(0xFF1B396A);

  // Controladores y variables para el formulario de reclamación
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  // Formatear la fecha
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Función para seleccionar imagen de la galería
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Función para subir la imagen a Firebase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reclamaciones/${widget.lostObject.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
      return null;
    }
  }

  // Función para enviar la reclamación
  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    // Obtener información del usuario actual
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;

    // Crear una nueva reclamación
    Reclamacion nuevaReclamacion = Reclamacion(
      uidReclamante: currentUser!.id,
      nombreReclamante: currentUser.nombre,
      estadoReclamacion: 'Pendiente',
      textoReclamacion: _textoController.text.trim(),
      imagenReclamacionUrl: imageUrl,
    );

    // Añadir la reclamación a la lista existente
    List<Reclamacion> nuevasReclamaciones = List.from(widget.lostObject.reclamaciones)
      ..add(nuevaReclamacion);

    // Actualizar el objeto en Firestore
    try {
      await FirebaseFirestore.instance
          .collection('objetos_perdidos')
          .doc(widget.lostObject.id)
          .update({
        'reclamaciones': nuevasReclamaciones.map((r) => r.toMap()).toList(),
        'estadoReclamacion': 'Pendiente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reclamación enviada exitosamente.')),
      );

      Navigator.of(context).pop(); // Regresar a la pantalla anterior
    } catch (e) {
      print('Error al enviar la reclamación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la reclamación.')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  bool _hasUserClaimed() {
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;
    return widget.lostObject.reclamaciones.any((reclamacion) => reclamacion.uidReclamante == currentUser?.id);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detalles del objeto",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        // Incluir la fecha en el AppBar
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(20.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _formatDate(widget.lostObject.timestamp),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Imagen del objeto perdido con GestureDetector
            GestureDetector(
              onTap: () {
                // Abrir imagen en pantalla completa
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FullscreenImageDialog(
                      imageUrl: widget.lostObject.imagenUrl,
                    );
                  },
                );
              },
              child: widget.lostObject.imagenUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: widget.lostObject.imagenUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red, size: 40),
                ),
              )
                  : Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700]),
              ),
            ),
            // Detalles del objeto perdido dentro de un Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: // Reemplaza este código en tu widget
              Container(
                width: double.infinity, // Asegura que el Card ocupe todo el ancho disponible
                padding: EdgeInsets.symmetric(horizontal: 0.0), // Padding de 16 a los lados
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: EdgeInsets.zero, // Elimina cualquier margen adicional del Card
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Padding interno del contenido
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título del objeto
                        Text(
                          widget.lostObject.tipoObjeto,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Descripción
                        Text(
                          'Descripción:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.lostObject.descripcion,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        // Lugar encontrado
                        Text(
                          'Encontrado en:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.lostObject.lugarEncontrado,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        // Estado de la reclamación (si existe)
                        if (widget.lostObject.estadoReclamacion != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado de la reclamación:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _primaryColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                widget.lostObject.estadoReclamacion!,
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Formulario de reclamación
            if (!_hasUserClaimed())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Para reclamar este objeto, por favor proporciona una descripción detallada y evidencia si es posible.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      // Campo de texto obligatorio
                      TextFormField(
                        controller: _textoController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Descripción de la reclamación',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Este campo es obligatorio.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Botón para seleccionar imagen opcional
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            // que sea color blanco

                            onPressed: _pickImage,
                            icon: Icon(Icons.photo, color: Colors.white),
                            label: _imageFile != null
                                ? Text('Imagen seleccionada', style: TextStyle(color: Colors.white))
                                : Text('No se ha seleccionado ninguna imagen', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                          ),

                        ],
                      ),
                      SizedBox(height: 24),
                      // Botón para enviar la reclamación
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text(
                          'Enviar reclamación',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
            // Mostrar mensaje si el usuario ya ha reclamado el objeto
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ya has enviado una reclamación para este objeto.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
