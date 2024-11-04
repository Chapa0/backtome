// add_lost_object_page.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/usuariosBD.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddLostObjectPage extends StatefulWidget {
  @override
  _AddLostObjectPageState createState() => _AddLostObjectPageState();
}

class _AddLostObjectPageState extends State<AddLostObjectPage> {
  File? _imageFile;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String _objectType = '';
  String _locationFound = '';
  bool _isUploadingImage = false;
  bool _isUploadingData = false;

  Future<void> _pickImage() async {

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
          _imageFile = compressedFile;
        });
      }
    }
  }

  Future<File?> _compressFile(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitted = filePath.substring(0, lastIndex);
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
        print("Tamaño después de la compresión: ${compressedSizeMB.toStringAsFixed(2)} MB");

        final originalSizeBytes = file.lengthSync();
        final reductionPercentage = (1 - compressedSizeBytes / originalSizeBytes) * 100;
        print("Reducción del tamaño: ${reductionPercentage.toStringAsFixed(2)}%");

        return resultFile;
      }
    } catch (e) {
      print("Error al comprimir imagen: $e");
    }

    return null;
  }


  // Función para subir la imagen y los datos a Firebase
  Future<void> _uploadData() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos y selecciona una imagen.')),
      );
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isUploadingImage = true;
    });

    String imageUrl = '';
    try {
      String fileName = 'lost_objects/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_imageFile!);

      // Escuchar el estado de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        switch (snapshot.state) {
          case TaskState.running:
            print('Subiendo...');
            break;
          case TaskState.success:
            print('Subida exitosa');
            break;
          case TaskState.error:
            print('Error en la subida');
            break;
          default:
            break;
        }
      });

      // Esperar a que la subida finalice
      TaskSnapshot taskSnapshot = await uploadTask;
      imageUrl = await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      print("Error al subir la imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen.')),
      );
      return;
    }

    setState(() {
      _isUploadingImage = false;
      _isUploadingData = true;
    });

    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes iniciar sesión para subir una imagen.')),
      );
      return;
    }

    try {
      CollectionReference objects = FirebaseFirestore.instance.collection('objetos_perdidos');
      await objects.add({
        'descripcion': _description,
        'tipoObjeto': _objectType,
        'lugarEncontrado': _locationFound,
        'imagenUrl': imageUrl,
        'nombreEncontrado': currentUser.nombre,
        'uidEncontrado': currentUser.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        _isUploadingData = false;
      });
      print("Error al guardar los datos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los datos.')),
      );
      return;
    }

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
        title: Text('Agregar Objeto Perdido'),
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: _imageFile == null
                        ? Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.add_a_photo,
                          size: 50, color: Colors.grey[700]),
                    )
                        : Image.file(_imageFile!),
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
                    decoration:
                    InputDecoration(labelText: '¿Qué objeto es?'),
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
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _uploadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Guardar', style: TextStyle(color: Colors.white)),
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
}
