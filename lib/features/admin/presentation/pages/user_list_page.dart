import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/admin/presentation/pages/user_detail_page.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/users/domain/usecases/fetch_users_usecase.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final Color _primaryColor = Color(0xFF1B396A);
  List<Usuario> _usuarios = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
  }

  Future<void> _loadUsuarios() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final usuarios = await locator<FetchUsersUseCase>()(
        onlyRegularUsers: true,
      );
      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los usuarios.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Usuarios registrados (${_usuarios.length})',
            style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final usuario = _usuarios[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: usuario.urlimagen.isNotEmpty
                        ? NetworkImage(usuario.urlimagen)
                        : AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                  title: Text(usuario.nombre),
                  subtitle: Text(usuario.correo),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailPage(usuario: usuario),
                      ),
                    );

                    if (result == true) {
                      // El usuario fue eliminado, actualizar la lista
                      setState(() {
                        _usuarios.removeAt(index);
                      });
                    }
                  },
                );
              },
            ),
    );
  }
}
