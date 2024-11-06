import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_backtome/views/usuarios/registrarObjetoPerdido.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/usuariosBD.dart';
import '../usuarios/UserAccountPage.dart';

class PageAppGeneralAdmin extends StatefulWidget {
  @override
  _PageAppGeneralAdminState createState() => _PageAppGeneralAdminState();
}

class _PageAppGeneralAdminState extends State<PageAppGeneralAdmin>
    with SingleTickerProviderStateMixin {
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

  // Variables para el filtrado por fecha
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  CalendarFormat _calendarFormat = CalendarFormat.month; // Formato inicial

  // Controladores para el calendario
  bool _isCalendarVisible = false; // Controla la visibilidad del calendario

  // AnimationController para el calendario
  late AnimationController _animationController;

  // Variables para la funcionalidad de búsqueda
  bool _isSearching = false; // Indica si la barra de búsqueda está visible
  String _searchQuery = ''; // Consulta de búsqueda actual
  TextEditingController _searchController = TextEditingController(); // Controlador para el campo de búsqueda
  FocusNode _searchFocusNode = FocusNode(); // Nodo de enfoque para manejar el teclado


  @override
  void initState() {
    super.initState();

    // Inicializar el AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

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
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }



  // Función para obtener los objetos perdidos con filtrado por fecha
  Future<void> _fetchLostObjects({bool isRefresh = false}) async {
    if (_isLoading) return;

    if (isRefresh) {
      setState(() {
        _lostObjects.clear();
        _lastDocument = null;
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('objetos_perdidos');

      // Aplicar filtrado por rango de fechas si está seleccionado
      if (_rangeStart != null && _rangeEnd != null) {
        query = query
            .where('timestamp', isGreaterThanOrEqualTo: _rangeStart)
            .where('timestamp', isLessThanOrEqualTo: _rangeEnd);
      }

      // Aplicar filtrado por búsqueda si hay una consulta
      if (_searchQuery.isNotEmpty) {
        String searchLower = _searchQuery.toLowerCase();

        // Asumiendo que 'tipoObjeto' se almacena en minúsculas
        query = query
            .orderBy('tipoObjeto')
            .startAt([searchLower])
            .endAt([searchLower + '\uf8ff']);
      } else {
        query = query.orderBy('timestamp', descending: true);
      }

      query = query.limit(_perPage);

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
    await _fetchLostObjects(isRefresh: true);
  }

  // Función para obtener el inicio del día
  DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0, 0);
  }

// Función para obtener el fin del día
  DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }


  // Funciones del calendario
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rangeStart = _getStartOfDay(selectedDay); // Inicio del día seleccionado
      _rangeEnd = _getEndOfDay(selectedDay);     // Fin del día seleccionado
      _isCalendarVisible = false;
      _animationController.reverse(); // Contraer el calendario
    });
    _fetchLostObjects(isRefresh: true); // Recargar los objetos con el nuevo filtro
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null; // Limpiamos la selección individual
      _focusedDay = focusedDay;

      if (start != null) {
        _rangeStart = _getStartOfDay(start); // Inicio del primer día del rango
      }

      if (end != null) {
        _rangeEnd = _getEndOfDay(end);       // Fin del último día del rango
      } else if (start != null) {
        _rangeEnd = _getEndOfDay(start);     // Si no hay fin, usar el inicio
      }

      _isCalendarVisible = false;
      _animationController.reverse(); // Contraer el calendario
    });
    _fetchLostObjects(isRefresh: true); // Recargar los objetos con el nuevo filtro
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
        // Dentro del AppBar
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isCalendarVisible = !_isCalendarVisible;
                if (_isCalendarVisible) {
                  _animationController.forward(); // Expandir el calendario
                } else {
                  _animationController.reverse(); // Contraer el calendario
                }
              });
            },
            icon: Icon(Icons.filter_list, color: Colors.white),
            label: Text(
              _rangeStart != null && _rangeEnd != null
                  ? _rangeStart!.isAtSameMomentAs(_rangeEnd!)
                  ? _formatDate(_rangeStart!) // Si es el mismo día, muestra una fecha
                  : '${_formatDate(_rangeStart!)} - ${_formatDate(_rangeEnd!)}' // Si es un rango, muestra ambas fechas
                  : 'Recientes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      // Cuerpo de la pantalla
      body: Column(
        children: [
          // Barra de búsqueda
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar objetos perdidos...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _fetchLostObjects(isRefresh: true);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                  _fetchLostObjects(isRefresh: true);
                },
              ),
            ),
          // Calendario animado
          _buildAnimatedCalendar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLostObjects,
              child: _lostObjects.isEmpty
                  ? _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                child: Text(
                  _isSearching
                      ? 'No hay resultados para "$_searchQuery"'
                      : 'No hay objetos perdidos.',
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: _lostObjects.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _lostObjects.length) {
                    final lostObject = _lostObjects[index];
                    return _buildLostObjectItem(lostObject);
                  } else {
                    // Mostrar el indicador de carga o mensaje
                    return _buildLoadingIndicator();
                  }
                },
              ),
            ),
          ),
        ],
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
                setState(() {
                  _isSearching = !_isSearching;
                  if (_isSearching) {
                    // Enfocar el campo de búsqueda
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  } else {
                    // Limpiar la búsqueda y recargar los objetos
                    _searchQuery = '';
                    _searchController.clear();
                    _fetchLostObjects(isRefresh: true);
                    FocusScope.of(context).unfocus(); // Ocultar el teclado
                  }
                });
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
    return GestureDetector(
      onTap: () {
        // Navegar a la pantalla
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
            // Envolvemos la imagen y el overlay en un Stack
            Stack(
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
                // Overlay amarillo si el objeto está en proceso de reclamación
                if (lostObject.estadoReclamacion == 'Pendiente')
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
              ],
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
                    'Fecha: ${_formatDateTime(lostObject.timestamp)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'Ya no hay más objetos perdidos que coincidan con "$_searchQuery".'
                : 'Ya no hay más objetos perdidos.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
  }

  // Formatear la fecha para mostrarla en la lista
  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Formatear solo la fecha
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
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

  // Widget para el calendario animado
  Widget _buildAnimatedCalendar() {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
      child: Container(
        color: Colors.white,
        child: TableCalendar(
          firstDay: DateTime.utc(2010, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          onDaySelected: _onDaySelected,
          onRangeSelected: _onRangeSelected,
          rangeSelectionMode: RangeSelectionMode.toggledOn, // Modo de selección de rango activado
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
          ),
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ),
    );
  }
}

