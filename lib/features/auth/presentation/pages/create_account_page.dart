import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/create_auth_user_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/usecases/register_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/upload_profile_image_usecase.dart';
import 'package:image_picker/image_picker.dart';

class PageCrearCuenta extends StatefulWidget {
  final Color background;

  const PageCrearCuenta({
    super.key,
    this.background = const Color(0xFFE1EDFF),
  });

  @override
  State<PageCrearCuenta> createState() => _PageCrearCuentaState();
}

class _PageCrearCuentaState extends State<PageCrearCuenta> {
  static const int _minPasswordLength = 8;

  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  String? _nombreError;
  String? _apellidosError;
  String? _correoError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile == null || !mounted) return;
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _signUp() async {
    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final correo = _correoController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _nombreError = nombre.isEmpty ? 'El nombre es obligatorio' : null;
      _apellidosError =
          apellidos.isEmpty ? 'Los apellidos son obligatorios' : null;
      _correoError = correo.isEmpty ? 'El correo es obligatorio' : null;
      _passwordError = _passwordErrorFor(password);
      _confirmPasswordError = _confirmPasswordErrorFor(
        password,
        confirmPassword,
      );
    });

    if (_nombreError != null ||
        _apellidosError != null ||
        _correoError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authUser = await locator<CreateAuthUserUseCase>()(
        email: correo,
        password: password,
      );

      var imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await locator<UploadProfileImageUseCase>()(
              userId: authUser.id,
              filePath: _imageFile!.path,
            ) ??
            '';
      }

      await locator<RegisterUserUseCase>()(
        Usuario(
          id: authUser.id,
          nombre: nombre,
          apellido: apellidos,
          correo: correo,
          urlimagen: imageUrl,
          tipoUsuario: 'user',
        ),
      );
      await locator<SignOutUseCase>()();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: Text(
            'La cuenta para $correo se creo correctamente. Ya puedes iniciar sesion.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => PageLogin()),
                  (route) => false,
                );
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      debugPrint('AuthException al crear cuenta: code=${e.code}, message=${e.message}');
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar(
          'Ocurrio un error inesperado. Por favor, intenta de nuevo.');
      debugPrint('Error inesperado al crear cuenta: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _passwordErrorFor(String password) {
    if (password.isEmpty) return 'La contrasena es obligatoria';
    if (password.length < _minPasswordLength) {
      return 'La contrasena debe tener al menos $_minPasswordLength caracteres';
    }
    return null;
  }

  String? _confirmPasswordErrorFor(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'La confirmacion de contrasena es obligatoria';
    }
    if (confirmPassword.length < _minPasswordLength) {
      return 'La confirmacion debe tener al menos $_minPasswordLength caracteres';
    }
    if (password != confirmPassword) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: widget.background,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'CREA TU CUENTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    'Y comencemos a ayudar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Selecciona una foto tuya o de tu credencial de estudiante',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _nombreController,
                    label: 'Nombre',
                    errorText: _nombreError,
                    onChanged: (_) => setState(() => _nombreError = null),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _apellidosController,
                    label: 'Apellidos',
                    errorText: _apellidosError,
                    onChanged: (_) => setState(() => _apellidosError = null),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _correoController,
                    label: 'Correo Electronico',
                    errorText: _correoError,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _correoError = null),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Contrasena',
                    errorText: _passwordError,
                    obscureText: _isPasswordHidden,
                    prefixIcon: Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                    onChanged: (_) => setState(() => _passwordError = null),
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmacion de contrasena',
                    errorText: _confirmPasswordError,
                    obscureText: _isConfirmPasswordHidden,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                        });
                      },
                    ),
                    onChanged: (_) {
                      setState(() => _confirmPasswordError = null);
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B396A),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => PageLogin()),
                            );
                          },
                    child: const Text('Ya tengo cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    String? errorText,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
