import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:flutter_backtome/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:provider/provider.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/complete_registration_page.dart';
import 'package:flutter_backtome/features/auth/presentation/pages/create_account_page.dart';

class PageLogin extends StatefulWidget {
  final Color background;

  PageLogin({this.background = const Color(0xFFE1EDFF)});

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _correoError;
  String? _passwordError;

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signIn() async {
    String email = _correoController.text.trim();
    String password = _passwordController.text.trim();

    bool hasError = false;

    setState(() {
      _correoError = null;
      _passwordError = null;
    });

    if (email.isEmpty) {
      setState(() {
        _correoError = 'El correo es obligatorio';
      });
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es obligatoria';
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
      final authState = Provider.of<AuthState>(context, listen: false);
      final result = await locator<SignInUseCase>()(
        email: email,
        password: password,
      );
      if (result.requiresRegistration) {
        if (!mounted) return;
        // Redirigir a la página para completar registro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PageCompletarRegistro(),
          ),
        );
        return;
      }

      final usuario = result.user;
      if (usuario == null) {
        throw const AuthException('No se pudo cargar el usuario.');
      }

      authState.setUser(usuario);

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "Correo inválido. Por favor, verifica el formato.";
          break;
        case 'user-not-found':
          errorMessage = "No existe una cuenta con este correo.";
          break;
        case 'wrong-password':
          errorMessage = "Contraseña incorrecta. Inténtalo de nuevo.";
          break;
        case 'invalid-credential':
          errorMessage = "Correo o contrasena incorrectos. Verifica los datos.";
          break;
        case 'user-disabled':
          errorMessage = "Esta cuenta ha sido deshabilitada.";
          break;
        case 'too-many-requests':
          errorMessage = "Demasiados intentos. Por favor, intenta más tarde.";
          break;
        default:
          errorMessage =
              "Error al iniciar sesión. Por favor, intenta de nuevo.";
      }
      _showSnackBar(errorMessage);
      print("Error de autenticacion: $e");
    } catch (e) {
      _showSnackBar(
          "Ocurrió un error inesperado. Por favor, intenta de nuevo.");
      print("Error inesperado: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    String email = '';

    await showDialog(
      context: context,
      builder: (context) {
        final TextEditingController _emailController = TextEditingController();
        return AlertDialog(
          title: Text('Recuperar contraseña'),
          content: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'Ingresa tu correo electrónico',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                email = _emailController.text.trim();
                Navigator.of(context).pop();
              },
              child: Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (email.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await locator<SendPasswordResetUseCase>()(email);
        _showSnackBar(
            'Se ha enviado un correo para restablecer tu contraseña.');
      } on AuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-email':
            errorMessage = "Correo inválido. Por favor, verifica el formato.";
            break;
          case 'user-not-found':
            errorMessage = "No existe una cuenta con este correo.";
            break;
          default:
            errorMessage =
                "Error al enviar el correo. Por favor, intenta de nuevo.";
        }
        _showSnackBar(errorMessage);
        print("Error de autenticacion: $e");
      } catch (e) {
        _showSnackBar(
            "Ocurrió un error inesperado. Por favor, intenta de nuevo.");
        print("Error inesperado: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              // Para evitar overflow en pantallas pequeñas
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 60), // Espacio superior
                  Image.asset(
                    'lib/resources/itver_logo_sf.png',
                    height: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "INICIAR SESIÓN",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Campo de correo electrónico
                  TextField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Correo Electrónico",
                      errorText: _correoError,
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (_correoError != null && value.trim().isNotEmpty) {
                        setState(() {
                          _correoError = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  // Campo de contraseña
                  TextField(
                    controller: _passwordController,
                    obscureText: _isPasswordHidden,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      errorText: _passwordError,
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
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
                    ),
                    onChanged: (value) {
                      if (_passwordError != null && value.trim().isNotEmpty) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  // Botón de Iniciar Sesión
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    ),
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Botón de Crear Cuenta
                  TextButton(
                    onPressed: () {
                      // Navegar a la pantalla de Crear Cuenta
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PageCrearCuenta(background: widget.background),
                        ),
                      );
                    },
                    child: Text(
                      "Crear Cuenta",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Pantalla de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
