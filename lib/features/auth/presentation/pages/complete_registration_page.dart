// Importaciones necesarias
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_backtome/features/auth/domain/usecases/get_current_auth_user_usecase.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/usecases/register_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/upload_profile_image_usecase.dart';

class PageCompletarRegistro extends StatefulWidget {
  @override
  _PageCompletarRegistroState createState() => _PageCompletarRegistroState();
}

class _PageCompletarRegistroState extends State<PageCompletarRegistro> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  bool _isLoading = false;

  String? _nombreError;
  String? _apellidosError;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile, String uid) async {
    try {
      return await locator<UploadProfileImageUseCase>()(
        userId: uid,
        filePath: imageFile.path,
      );
    } catch (e) {
      print("Error al subir imagen: $e");
      return null;
    }
  }

  Future<void> _completeRegistration() async {
    String nombre = _nombreController.text.trim();
    String apellidos = _apellidosController.text.trim();

    bool hasError = false;

    setState(() {
      _nombreError = null;
      _apellidosError = null;
    });

    if (nombre.isEmpty) {
      setState(() {
        _nombreError = 'El nombre es obligatorio';
      });
      hasError = true;
    }

    if (apellidos.isEmpty) {
      setState(() {
        _apellidosError = 'Los apellidos son obligatorios';
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authUser = locator<GetCurrentAuthUserUseCase>()();

      if (authUser != null) {
        final uid = authUser.id;
        final email = authUser.email;

        var imageUrl = '';
        if (_imageFile != null) {
          final uploadedUrl = await _uploadImage(_imageFile!, uid);
          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
          }
        }

        final usuario = Usuario(
          id: uid,
          nombre: nombre,
          apellido: apellidos,
          correo: email,
          urlimagen: imageUrl,
          tipoUsuario: 'user',
        );

        await locator<RegisterUserUseCase>()(usuario);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', 'user');
        await prefs.setString('userData', json.encode(usuario.toMap()));

        final authState = Provider.of<AuthState>(context, listen: false);
        authState.setUser(usuario);

        _showSnackBar('Registro completado exitosamente.');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PageAppGeneral(),
          ),
        );
      } else {
        _showSnackBar('No se pudo obtener el usuario actual.');
      }
    } catch (e) {
      _showSnackBar('Error al completar el registro. Intenta de nuevo.');
      print("Error al completar registro: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completar Registro'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Selecciona una foto tuya',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      errorText: _nombreError,
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      if (_nombreError != null && value.trim().isNotEmpty) {
                        setState(() {
                          _nombreError = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _apellidosController,
                    decoration: InputDecoration(
                      labelText: 'Apellidos',
                      errorText: _apellidosError,
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      if (_apellidosError != null && value.trim().isNotEmpty) {
                        setState(() {
                          _apellidosError = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Completar Registro',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
