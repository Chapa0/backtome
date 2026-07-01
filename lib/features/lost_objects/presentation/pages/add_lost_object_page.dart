// add_lost_object_page.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/create_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/upload_lost_object_images_usecase.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:flutter_backtome/features/lost_objects/presentation/pages/fullscreen_image_detail_page.dart';
import 'package:flutter_backtome/shared/widgets/location/mapbox_location_picker.dart';

class AddLostObjectPage extends StatefulWidget {
  @override
  _AddLostObjectPageState createState() => _AddLostObjectPageState();
}

class _AddLostObjectPageState extends State<AddLostObjectPage> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String _objectType = '';
  String _locationFound = '';
  bool _isUploadingImage = false;
  bool _isUploadingData = false;
  final List<File> _selectedImages = [];
  double? _selectedLat;
  double? _selectedLng;

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Máximo 5 imágenes permitidas.')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Convertir XFile a File
      final File file = File(pickedFile.path);

      // Obtener el tamaño del archivo antes de la compresión y convertirlo a MB
      final originalSizeBytes = await pickedFile.length();
      final originalSizeMB = originalSizeBytes / 1048576;
      print("Tamaño original: ${originalSizeMB.toStringAsFixed(2)} MB");

      // Comprimir la imagen
      final compressedFile = await _compressFile(file);

      if (compressedFile != null) {
        setState(() {
          _selectedImages.add(compressedFile);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al comprimir la imagen.')),
        );
      }
    }
  }

  Future<File?> _compressFile(File file) async {
    final filePath = file.absolute.path;
    final dotIndex = filePath.lastIndexOf('.');
    final splitted = dotIndex > 0 ? filePath.substring(0, dotIndex) : filePath;
    final outPath = "${splitted}_compressed.jpg";

    try {
      // Asumiendo que FlutterImageCompress.compressAndGetFile devuelve un File.
      var compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        minWidth: 1280,
        minHeight: 720,
        quality: 30,
      );

      if (compressedFile != null) {
        File resultFile = File(compressedFile.path);

        final compressedSizeBytes = resultFile.lengthSync();
        final compressedSizeMB = compressedSizeBytes / 1048576;
        print(
            "Tamaño después de la compresión: ${compressedSizeMB.toStringAsFixed(2)} MB");

        final originalSizeBytes = file.lengthSync();
        final reductionPercentage =
            (1 - compressedSizeBytes / originalSizeBytes) * 100;
        print(
            "Reducción del tamaño: ${reductionPercentage.toStringAsFixed(2)}%");

        return resultFile;
      }
    } catch (e) {
      print("Error al comprimir imagen: $e");
    }

    return null;
  }

  List<Widget> _buildCarouselItems(BuildContext context) {
    List<Widget> items = [];
    for (var i = 0; i < _selectedImages.length; i++) {
      var file = _selectedImages[i];
      var item = Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    images: _selectedImages,
                    initialIndex: i,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  Image.file(file, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          // Botón para eliminar la imagen
          Container(
            color: Colors.black.withOpacity(0.5),
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedImages.removeAt(i);
                });
              },
            ),
          ),
        ],
      );
      items.add(item);
    }

    // Si hay menos de 5 imágenes, añadir al final el botón para añadir más imágenes.
    if (_selectedImages.length < 5) {
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
    }

    return items;
  }

  // Función para subir la imagen y los datos a Firebase
  Future<void> _uploadData() async {
    if (_isUploadingData) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, añade al menos una imagen.",
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    _formKey.currentState!.save();

    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes iniciar sesiÃ³n para subir una imagen.')),
      );
      return;
    }

    setState(() {
      _isUploadingData = true;
    });

    List<String> imageUrls = [];
    try {
      if (mounted) {
        setState(() {
          _isUploadingImage = true;
        });
      }
      imageUrls = await locator<UploadLostObjectImagesUseCase>()(
        _selectedImages.map((file) => file.path).toList(),
      );
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagenes subidas exitosamente.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(
        () {
          _isUploadingData = false;
          _isUploadingImage = false;
        },
      );
      print("Error al subir las imágenes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir las imágenes.')),
      );
      return;
    }

    try {
      await locator<CreateLostObjectUseCase>()(
        requesterId: currentUser.id,
        description: _description,
        objectType: _objectType,
        foundPlace: _locationFound,
        imageUrls: imageUrls,
        latitude: _selectedLat,
        longitude: _selectedLng,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingData = false;
        });
      }
      print("Error al guardar los datos: $e");
      final message = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploadingData = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Objeto perdido agregado exitosamente.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFF1B396A);
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Agregar Objeto Perdido',
            style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 200,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: true,
                    ),
                    items: _buildCarouselItems(context),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: 'Descripción del objeto'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una descripción';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _description = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: '¿Qué objeto es?'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el tipo de objeto';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _objectType = value!;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: '¿Dónde fue encontrado?'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el lugar donde fue encontrado';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _locationFound = value!;
                    },
                  ),
                  // Inside your build method, in the ListView children
                  SizedBox(height: 16),
                  Text(
                    _selectedLat != null
                        ? 'Ubicacion seleccionada (${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)})'
                        : 'No se ha seleccionado ubicacion en el mapa.',
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _selectLocationOnMap,
                    child: Text('Seleccionar ubicación en el mapa'),
                  ),

                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isUploadingData ? null : _uploadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isUploadingData
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Guardar',
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploadingImage || _isUploadingData)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _selectLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapboxLocationPicker(
          initialLatitude: _selectedLat ?? 19.1738,
          initialLongitude: _selectedLng ?? -96.1342,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLat = result['latitud'] as double;
        _selectedLng = result['longitud'] as double;
      });
    }
  }
}
