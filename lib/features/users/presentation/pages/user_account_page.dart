// user_account_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/usecases/update_user_usecase.dart';
import 'package:flutter_backtome/features/users/domain/usecases/upload_profile_image_usecase.dart';

import 'package:flutter_backtome/features/support/presentation/pages/support_page.dart';

class UserAccountPage extends StatefulWidget {
  @override
  _UserAccountPageState createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final _formKey = GlobalKey<FormState>();
  String? _nombre;
  String? _apellido;
  bool _isEditingName = false;
  bool _isEditingApellido = false;
  bool _isEditingPassword = false;
  bool _isLoading = false;
  bool _passwordVisible = false; // Nueva variable para controlar la visibilidad

  final ImagePicker _picker = ImagePicker();

  Future<void> _updateUser(Usuario user) {
    return locator<UpdateUserUseCase>()(user);
  }

  Future<void> _changeProfilePicture(Usuario currentUser) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final downloadUrl = await locator<UploadProfileImageUseCase>()(
          userId: currentUser.id,
          filePath: pickedFile.path,
        );
        if (downloadUrl == null) {
          throw Exception('No se pudo subir la imagen');
        }

        // Actualizar la URL de la imagen en Firebase Firestore o Realtime Database
        currentUser.urlimagen = downloadUrl;
        await _updateUser(currentUser);

        // Actualizar el estado del usuario en la aplicación
        Provider.of<AuthState>(context, listen: false).updateUser(currentUser);
      } catch (e) {
        print('Error al subir la imagen: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword(String email) async {
    try {
      await locator<SendPasswordResetUseCase>()(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Se ha enviado un enlace para restablecer la contraseña a tu correo.')),
      );
    } catch (e) {
      print('Error al enviar el email de restablecimiento de contraseña: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el email de restablecimiento')),
      );
    }
  }

  // Función para mostrar el diálogo de restablecimiento de contraseña
  Future<void> _showPasswordResetDialog(String email) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reautenticación Necesaria'),
          content: Text(
              'Para cambiar tu contraseña, necesitas reautenticarse. ¿Deseas recibir un correo para restablecer tu contraseña?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _changePassword(email); // Enviar el correo de restablecimiento
              },
              child: Text('Enviar Correo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final Usuario? currentUser = authState.user;

    final String userName = currentUser?.nombre ?? 'Usuario';
    final String userApellido = currentUser?.apellido ?? 'Apellido';
    final String userEmail = currentUser?.correo ?? 'correo@ejemplo.com';
    final String userPhotoUrl =
        (currentUser?.urlimagen != null && currentUser!.urlimagen.isNotEmpty)
            ? currentUser.urlimagen
            : '';

    final Color primaryColor = Color(0xFF1B396A);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Cuenta',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor:
            primaryColor, // Define primaryColor según tu esquema de colores
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                // Navega a la pantalla Soporte
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Soporte()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8C8984), // Color oscuro suave
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4.0,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.support_agent, // Ícono de soporte
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: primaryColor.withOpacity(0.12),
                          backgroundImage: userPhotoUrl.isNotEmpty
                              ? NetworkImage(userPhotoUrl)
                              : null,
                          child: userPhotoUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 64,
                                  color: primaryColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              if (currentUser != null) {
                                _changeProfilePicture(currentUser);
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: primaryColor,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre
                          TextFormField(
                            initialValue: userName,
                            readOnly: !_isEditingName, // Usar readOnly
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isEditingName ? Icons.check : Icons.edit,
                                  color: _isEditingName
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                onPressed: () async {
                                  if (_isEditingName) {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      currentUser?.nombre =
                                          _nombre ?? currentUser.nombre;
                                      await _updateUser(currentUser!);
                                      authState.updateUser(currentUser);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Nombre actualizado exitosamente'),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _isEditingName = false;
                                    });
                                  } else {
                                    setState(() {
                                      _isEditingName = true;
                                    });
                                  }
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isEditingName
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu nombre';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _nombre = value;
                            },
                          ),
                          SizedBox(height: 20),
                          // Apellido
                          TextFormField(
                            initialValue: userApellido,
                            readOnly: !_isEditingApellido, // Usar readOnly
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isEditingApellido ? Icons.check : Icons.edit,
                                  color: _isEditingApellido
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                onPressed: () async {
                                  if (_isEditingApellido) {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      currentUser?.apellido =
                                          _apellido ?? currentUser.apellido;
                                      await _updateUser(currentUser!);
                                      authState.updateUser(currentUser);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Apellido actualizado exitosamente'),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _isEditingApellido = false;
                                    });
                                  } else {
                                    setState(() {
                                      _isEditingApellido = true;
                                    });
                                  }
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isEditingApellido
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu apellido';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _apellido = value;
                            },
                          ),
                          SizedBox(height: 20),
                          // Contraseña
                          TextFormField(
                            obscureText:
                                !_passwordVisible, // Controla la visibilidad
                            readOnly: !_isEditingPassword, // Usar readOnly
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: '********',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isEditingPassword ? Icons.check : Icons.edit,
                                  color: _isEditingPassword
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                                onPressed: () async {
                                  if (_isEditingPassword) {
                                    _showPasswordResetDialog(userEmail);
                                    setState(() {
                                      _isEditingPassword = false;
                                    });
                                  } else {
                                    setState(() {
                                      _isEditingPassword = true;
                                    });
                                  }
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isEditingPassword
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (_isEditingPassword) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, ingresa una nueva contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10), // Espacio antes de la Checkbox
                          // Checkbox para mostrar/ocultar contraseña
                          Row(
                            children: [
                              Checkbox(
                                value: _passwordVisible,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _passwordVisible = value ?? false;
                                  });
                                },
                              ),
                              Text('Mostrar contraseña'),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Eliminar el botón de "Cambiar contraseña vía email"
                          // ElevatedButton(
                          //   onPressed: () {
                          //     _changePassword(userEmail);
                          //   },
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.grey,
                          //   ),
                          //   child: Text('Cambiar contraseña vía email'),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await locator<SignOutUseCase>()();
                        authState.logout();

                        if (!mounted) return;
                        navigator.popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
