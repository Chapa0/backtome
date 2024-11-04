// page_app_general.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_backtome/views/usuarios/registrarObjetoPerdido.dart';
import 'package:provider/provider.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/usuariosBD.dart';
import 'ObjetoDetalles.dart';
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
      // Mostrar SnackBar en caso de error
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
// Widget para construir cada elemento de la lista
  Widget _buildLostObjectItem(LostObject lostObject) {
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla de detalles al tocar el card
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LostObjectDetailPage(lostObject: lostObject),
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
            // Imagen del objeto perdido
            lostObject.imagenUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: CachedNetworkImage(
                imageUrl: lostObject.imagenUrl,
                width: double.infinity,
                height: 200, // Altura fija para la imagen
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.red, size: 40),
                ),
              ),
            )
                : Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700]),
            ),
            // Datos del objeto perdido
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
                    'Fecha: ${_formatDate(lostObject.timestamp)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Eliminamos el botón "Ver Detalles"
            // Si deseas añadir algún otro elemento, puedes hacerlo aquí
          ],
        ),
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
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página correspondiente
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in),
            title: Text('Objetos reclamados'),
            onTap: () {
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página correspondiente
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mapa de entrega de objetos perdidos'),
            onTap: () {
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página correspondiente
            },
          ),
        ],
      ),
    );
  }

  // Función para mostrar detalles en un diálogo
  void _showLostObjectDetails(LostObject lostObject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.0), // Margen alrededor del diálogo
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ocupa el mínimo espacio necesario
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del objeto perdido
                  lostObject.imagenUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: CachedNetworkImage(
                      imageUrl: lostObject.imagenUrl,
                      width: double.infinity,
                      height: 200, // Altura fija para la imagen
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      ),
                    ),
                  )
                      : Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[700]),
                  ),
                  // Datos del objeto perdido
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          lostObject.descripcion,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Encontrado en:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          lostObject.lugarEncontrado,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Fecha:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(lostObject.timestamp),
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Botón para cerrar el diálogo
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar el diálogo
                        },
                        child: Text(
                          'Cerrar',
                          style: TextStyle(color: _primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
