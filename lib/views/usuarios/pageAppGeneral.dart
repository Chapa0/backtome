// page_app_general.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_backtome/views/usuarios/registrarObjetoPerdido.dart';
import 'package:provider/provider.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/usuariosBD.dart';
import 'UserAccountPage.dart';

class PageAppGeneral extends StatefulWidget {
  @override
  _PageAppGeneralState createState() => _PageAppGeneralState();
}

class _PageAppGeneralState extends State<PageAppGeneral> {
  final Color _primaryColor = Color(0xFF1B396A);

  // Lista para almacenar los objetos perdidos
  List<LostObject> _lostObjects = [];

  // Controlador de desplazamiento para detectar cuándo llegar al final de la lista
  final ScrollController _scrollController = ScrollController();

  // Variables para manejar la paginación
  bool _isLoading = false;
  bool _hasMore = true; // Indica si hay más objetos por cargar
  DocumentSnapshot? _lastDocument; // Último documento cargado
  final int _perPage = 20; // Número de objetos a cargar por página

  @override
  void initState() {
    super.initState();
    _fetchLostObjects();

    // Añadir un listener al controlador de desplazamiento
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchLostObjects();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Función para obtener los primeros 20 objetos perdidos
  Future<void> _fetchLostObjects() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('objetos_perdidos')
          .orderBy('timestamp', descending: true)
          .limit(_perPage);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;

        List<LostObject> fetchedObjects = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return LostObject.fromMap(data, doc.id);
        }).toList();

        setState(() {
          _lostObjects.addAll(fetchedObjects);
          // Si se obtuvieron menos de _perPage documentos, ya no hay más por cargar
          if (fetchedObjects.length < _perPage) {
            _hasMore = false;
          }
        });
      } else {
        // No hay más documentos
        setState(() {
          _hasMore = false;
        });
      }
    } catch (error) {
      print("Error al cargar los objetos perdidos desde Firestore: $error");
      // Puedes mostrar un SnackBar o algún mensaje al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los objetos perdidos.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Función para refrescar la lista (pull to refresh)
  Future<void> _refreshLostObjects() async {
    setState(() {
      _lostObjects.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    await _fetchLostObjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar en la parte superior
      appBar: AppBar(
        title: Text(
          'Objetos Perdidos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Acción del botón de filtrar, por ahora sin funcionalidad
            },
            icon: Icon(Icons.filter_list, color: Colors.white),
            label:
            Text('Recientes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      // Cuerpo de la pantalla
      body: RefreshIndicator(
        onRefresh: _refreshLostObjects,
        child: _lostObjects.isEmpty
            ? _isLoading
            ? Center(child: CircularProgressIndicator())
            : Center(child: Text('No hay objetos perdidos.'))
            : ListView.builder(
          controller: _scrollController,
          itemCount: _lostObjects.length + 1, // +1 para el indicador
          itemBuilder: (context, index) {
            if (index < _lostObjects.length) {
              final lostObject = _lostObjects[index];
              return _buildLostObjectItem(lostObject);
            } else {
              // Mostrar el indicador de carga
              return _buildLoadingIndicator();
            }
          },
        ),
      ),
      // BottomAppBar con elementos interactivos
      bottomNavigationBar: BottomAppBar(
        color: _primaryColor,
        shape: CircularNotchedRectangle(), // Para el notch del FAB
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Botón de menú en la izquierda
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                // Mostrar el cajón que se despliega desde la parte inferior
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomDrawer();
                  },
                );
              },
            ),
            Spacer(),
            // Ícono de búsqueda en la derecha
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Acción de búsqueda
              },
            ),
          ],
        ),
      ),
      // FAB incrustado en el centro del BottomAppBar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () {
          // Ir a la pantalla de registro de objetos perdidos AddLostObjectPage
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddLostObjectPage()),
          );
        },
        child: Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // Widget para construir cada elemento de la lista
  Widget _buildLostObjectItem(LostObject lostObject) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: lostObject.imagenUrl.isNotEmpty
            ? Image.network(
          lostObject.imagenUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        )
            : Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        title: Text(lostObject.tipoObjeto),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción: ${lostObject.descripcion}'),
            Text('Encontrado en: ${lostObject.lugarEncontrado}'),
            Text('Fecha: ${_formatDate(lostObject.timestamp)}'),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Acción al tocar el elemento, por ejemplo, mostrar detalles
        },
      ),
    );
  }

  // Widget para el indicador de carga al final de la lista
  Widget _buildLoadingIndicator() {
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return SizedBox.shrink(); // No mostrar nada si no hay más datos
    }
  }

  // Formatear la fecha para mostrarla en la lista
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Widget para el cajón inferior (Bottom Drawer)
  Widget _buildBottomDrawer() {
    final authState = Provider.of<AuthState>(context);
    final Usuario? currentUser = authState.user;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAccountPage()),
              );
            },
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(currentUser?.urlimagen ??
                        'https://via.placeholder.com/150'),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.nombre ?? 'Usuario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          currentUser?.correo ?? ' ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.add_box),
            title: Text('Objetos perdidos agregados'),
            onTap: () {
              // Acción al seleccionar esta opción
              Navigator.pop(context); // Cerrar el cajón
              // Puedes navegar a otra página que muestre los objetos agregados por el usuario
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in),
            title: Text('Objetos reclamados'),
            onTap: () {
              // Acción al seleccionar esta opción
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página de objetos reclamados
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mapa de entrega de objetos perdidos'),
            onTap: () {
              // Acción al seleccionar esta opción
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página del mapa
            },
          ),
        ],
      ),
    );
  }
}
