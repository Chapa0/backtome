import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/users/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_backtome/shared/widgets/action_loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class UserDetailPage extends StatelessWidget {
  final Usuario usuario;
  final Color _primaryColor = Color(0xFF1B396A);

  UserDetailPage({required this.usuario});

  void _confirmDeleteUser(BuildContext context) {
    // Capturamos el contexto original
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminar usuario'),
        content: Text(
            '¿Estás seguro de que deseas eliminar este usuario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _deleteUser(parentContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context) async {
    try {
      final authState = Provider.of<AuthState>(context, listen: false);
      final currentUser = authState.user;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesion.');
      }

      await ActionLoadingOverlay.run<void>(
        context,
        message: 'Eliminando usuario...',
        action: () => locator<DeleteUserUseCase>()(
          requesterId: currentUser.id,
          user: usuario,
        ),
      );

      if (!context.mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario eliminado exitosamente.')),
      );

      // Regresar a la pantalla anterior
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error al eliminar el usuario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el usuario.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Detalle del usuario'),
        backgroundColor: _primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: usuario.urlimagen.isNotEmpty
                    ? NetworkImage(usuario.urlimagen)
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
              ),
              SizedBox(height: 20),
              Text(
                '${usuario.nombre} ${usuario.apellido}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                usuario.correo,
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _confirmDeleteUser(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('Eliminar usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
