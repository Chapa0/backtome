// lost_object_detail_page.dart

import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:path/path.dart' as path;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/claim_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/delete_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/upload_claim_image_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_map_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_pickup_page.dart';
import 'package:flutter_backtome/shared/widgets/image_viewer_dialog.dart';

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
  List<String> imagenesUrls = []; // Inicializa con las URLs de las imágenes
  bool _isSubmitting = false;
  List<File> _selectedImages = []; // Lista de archivos locales

  // Variables para mensajes de advertencia
  final List<String> _warningMessages = [
    "Reclamar objetos perdidos que no te pertenecen puede ser considerado como robo.",
    "No reclames objetos perdidos que no son de tu propiedad.",
    "Asegúrate de que el objeto perdido sea tuyo antes de reclamarlo.",
    "Reclamar objetos sin ser el dueño legítimo puede tener consecuencias legales.",
    "Por favor, verifica que eres el propietario del objeto antes de reclamarlo."
  ];
  String _currentWarningMessage = "";
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _loadImages(widget.lostObject.imageUrls);
    print("numero de urls: ${widget.lostObject.imageUrls!.length}");

    // Inicializar el mensaje de advertencia
    _currentWarningMessage = _warningMessages[0];
  }

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
      return await locator<UploadClaimImageUseCase>()(
        objectId: widget.lostObject.id,
        filePath: imageFile.path,
      );
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

    // Mostrar el diálogo de carga con mensajes de advertencia
    _showLoadingDialog();

    DateTime startTime = DateTime.now();

    try {
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
        fotoReclamante: currentUser.urlimagen,
        nombreReclamante: currentUser.nombre,
        apellidoReclamante: currentUser.apellido,
        estadoReclamacion: 'Pendiente',
        textoReclamacion: _textoController.text.trim(),
        imagenReclamacionUrl: imageUrl,
        horaReclamacion: DateTime.now(),
      );

      await locator<ClaimLostObjectUseCase>()(
        requesterId: currentUser.id,
        object: widget.lostObject,
        claim: nuevaReclamacion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reclamación enviada exitosamente.')),
      );

      // Navegar a la página de recolección de objetos perdidos
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LostObjectPickupPage(),
        ),
      );
    } catch (e) {
      print('Error al enviar la reclamación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la reclamación.')),
      );
    }

    // Calcular el tiempo transcurrido
    DateTime endTime = DateTime.now();
    Duration elapsed = endTime.difference(startTime);

    // Determinar si se necesita esperar más tiempo
    if (elapsed < Duration(seconds: 5)) {
      await Future.delayed(Duration(seconds: 5) - elapsed);
    }

    setState(() {
      _isSubmitting = false;
    });

    // Cerrar el diálogo de carga si aún está abierto
    Navigator.of(context).pop(); // Cerrar el diálogo
    Navigator.of(context).pop(); // Cerrar la página actual
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  bool _hasUserClaimed() {
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;
    return widget.lostObject.reclamaciones
        .any((reclamacion) => reclamacion.uidReclamante == currentUser?.id);
  }

  bool _isOwner() {
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;
    return widget.lostObject.uidEncontrado == currentUser?.id;
  }

  Future<void> _loadImages(List<String>? imageUrls) async {
    if (imageUrls == null || imageUrls.isEmpty) {
      return;
    }

    List<File> imageFiles = [];
    for (String url in imageUrls) {
      try {
        File imageFile = await _urlToFile(url);
        imageFiles.add(imageFile);
      } catch (e) {
        print("Error al descargar la imagen: $e");
        // Opcionalmente, maneja el error, por ejemplo, mostrando un mensaje al usuario
      }
    }

    setState(() {
      _selectedImages = imageFiles;
      print("Imagenes cargadas: ${_selectedImages.length}");
    });
  }

  Future<File> _urlToFile(String imageUrl) async {
    // Crear una instancia de Dio
    var dio = Dio();

    // Obtener una ubicación temporal en el sistema de archivos del dispositivo donde guardar el archivo
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    // Extraer el nombre del archivo de la URL
    String fileName = path.basename(imageUrl);

    // Combinar el camino temporal con el nombre del archivo
    String filePath = path.join(tempPath, fileName);

    try {
      // Descargar el archivo de la imagen de la URL
      Response response = await dio.download(imageUrl, filePath);

      // Si la descarga fue exitosa, devolver el archivo
      if (response.statusCode == 200) {
        return File(filePath);
      } else {
        throw Exception(
            'Error al descargar la imagen: Estado HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al descargar la imagen: $e');
    }
  }

  // Método para construir los items del carousel
  List<Widget> _buildCarouselItems(BuildContext context) {
    List<Widget> items = [];
    for (var i = 0; i < _selectedImages.length; i++) {
      var file = _selectedImages[i];
      var item = Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () {
              ImageViewerDialog.show(
                context: context,
                imageFile: file,
                title: widget.lostObject.tipoObjeto,
                subtitle: widget.lostObject.lugarEncontrado,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  Image.file(file, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          // Botón para eliminar la imagen
          /*Container(
            color: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedImages.removeAt(i);
                });
              },
            ),
          ),*/
        ],
      );
      items.add(item);
    }

    // Si hay menos de 5 imágenes, añadir al final el botón para añadir más imágenes.
    /* if (_selectedImages.length < 5) {
      Widget addButton = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.grey[300],
          child: GestureDetector(
            onTap: _pickImage,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  Text("Añadir imagen"),
                ],
              ),
            ),
          ),
        ),
      );

      items.add(addButton);
    }*/

    return items;
  }

  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final Usuario? currentUser = authState.user;
    bool isOwner = widget.lostObject.uidEncontrado == currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Detalles del objeto",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
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
            // Imagenes del objeto perdido
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                ),
                items: _buildCarouselItems(context),
              ),
            ),
            // Detalles del objeto perdido dentro de un Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 0.0),
                child: Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                        if (widget.lostObject.estadoReclamacion !=
                            'No reclamado')
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
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        SizedBox(height: 16),
                        Text(
                          'Custodia actual:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _custodyDescription(),
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 16),
                        // Botón para ver la ubicación en el mapa
                        SizedBox(height: 16),
                        if (widget.lostObject.latitud != null &&
                            widget.lostObject.longitud != null)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LostObjectMapPage(
                                    latitud: widget.lostObject.latitud!,
                                    longitud: widget.lostObject.longitud!,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.map, color: Colors.white),
                            label: Text('Ver ubicación en el mapa',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                            ),
                          ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Show the claim form or appropriate message
            if (widget.lostObject.estadoReclamacion == 'Entregado')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Este objeto ha sido entregado a su dueño: ${widget.lostObject.nombreReclamado}',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            else if (isOwner)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Eres el usuario que encontró este objeto.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _deleteLostObject(widget.lostObject);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'Eliminar objeto',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            else if (_hasUserClaimed())
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ya has enviado una reclamación para este objeto.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              )
            else
              // Show the claim form
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
                      // Required text field
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
                      // Button to select optional image
                      // Button to select optional image
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.photo, color: Colors.white),
                            label: Text(
                                _imageFile == null
                                    ? 'Agrega imagen de tu objeto (opcional)'
                                    : 'Cambiar imagen seleccionada',
                                style: TextStyle(color: Colors.white)),
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_imageFile != null)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.file(
                                _imageFile!,
                                width: 200, // Puedes ajustar el tamaño aquí
                                height: 200, // Puedes ajustar el tamaño aquí
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red, // Fondo rojo
                                  shape: BoxShape
                                      .rectangle, // Rectángulo por defecto
                                  borderRadius: BorderRadius.circular(
                                      12), // Esquinas redondeadas
                                ),
                                padding: const EdgeInsets.all(
                                    4.0), // Espaciado interno para el ícono
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _imageFile = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: 24),
                      // Button to submit the claim
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 32.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Enviar reclamación',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _custodyDescription() {
    final object = widget.lostObject;
    if (object.estadoReclamacion == 'Entregado') {
      return 'Entregado a ${object.nombreReclamado ?? 'reclamante'}';
    }

    if (object.estaEnPuntoCustodia) {
      return 'En punto de entrega: ${object.puntoCustodiaNombre ?? object.custodiaLabel}';
    }

    return 'Lo tiene ${object.custodiaLabel}';
  }

  void _deleteLostObject(LostObject lostObject) async {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final currentUser = authState.user;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesion.');
      }

      await locator<DeleteLostObjectUseCase>()(
        requesterId: currentUser.id,
        object: lostObject,
      );

      // Mostrar un SnackBar confirmando la eliminación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El objeto ha sido eliminado.')),
      );

      // Regresar a la página anterior
      Navigator.of(context).pop();
    } catch (e) {
      // Mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el objeto: $e')),
      );
    }
  }

  Future<void> _showLoadingDialog() async {
    _currentWarningMessage = _warningMessages[0];
    int messageIndex = 0;
    final random = Random();

    // Iniciar la rotación de mensajes cada 2 segundos
    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        messageIndex = random.nextInt(_warningMessages.length);
        _currentWarningMessage = _warningMessages[messageIndex];
      });
    });

    await showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  _currentWarningMessage,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Cancelar el temporizador cuando el diálogo se cierre
    _messageTimer?.cancel();
  }
}
