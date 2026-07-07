import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:provider/provider.dart';

import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/delete_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/fetch_user_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_detail_page.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';

class LostObjectsPage extends StatefulWidget {
  @override
  _LostObjectsPageState createState() => _LostObjectsPageState();
}

class _LostObjectsPageState extends State<LostObjectsPage> {
  List<LostObject> _lostObjects = [];
  bool _isLoading = false;
  bool _hasMore = false;
  final Color _primaryColor = Color(0xFF1B396A);

  @override
  void initState() {
    super.initState();
    _loadLostObjects();
  }

  Future<void> _loadLostObjects() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;
    if (_isLoading || currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final objects = await locator<FetchUserLostObjectsUseCase>()(
        currentUser.id,
      );
      setState(() {
        _lostObjects = objects;
        _hasMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar objetos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _confirmDeleteObject(LostObject lostObject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar objeto'),
        content: Text('¿Estás seguro de que deseas eliminar este objeto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cerrar el diálogo
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar el diálogo
              _deleteLostObject(lostObject);
            },
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
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

      // Remover el objeto de la lista local
      setState(() {
        _lostObjects.remove(lostObject);
      });

      // Mostrar un SnackBar confirmando la eliminación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El objeto ha sido eliminado.')),
      );
    } catch (e) {
      // Mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el objeto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: _primaryColor,
        title: Text('Objetos Perdidos Agregados',
            style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: _lostObjects.length + 1,
        itemBuilder: (context, index) {
          if (index == _lostObjects.length) {
            return _hasMore
                ? Center(child: CircularProgressIndicator())
                : Center(child: Text('No hay más objetos.'));
          }
          final lostObject = _lostObjects[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LostObjectDetailPage(lostObject: lostObject),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      lostObject.imagenUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12.0)),
                              child: CachedNetworkImage(
                                imageUrl: lostObject.imagenUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error,
                                      color: Colors.red, size: 40),
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported,
                                  size: 50, color: Colors.grey[700]),
                            ),
                      if (lostObject.estadoReclamacion == 'Pendiente')
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'En proceso de reclamación',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Icono de papelera para eliminar
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            _confirmDeleteObject(lostObject);
                          },
                          child: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lostObject.tipoObjeto,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Descripción: ${lostObject.descripcion}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Encontrado en: ${lostObject.lugarEncontrado}',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fecha: ${_formatDateTime(lostObject.timestamp)}',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _hasMore && !_isLoading
          ? FloatingActionButton(
              backgroundColor: _primaryColor,
              onPressed: _loadLostObjects,
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
