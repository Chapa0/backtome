import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_backtome/views/usuarios/registrarObjetoPerdido.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Importar intl para formatear fechas

import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/usuariosBD.dart';
import 'ClaimedObjectsPage.dart';
import 'ObjetoDetalles.dart';
import 'UserAccountPage.dart';
import 'listaObjetosAgregados.dart';
import 'lostObjectPickupPage.dart';

class PageAppGeneral extends StatefulWidget {
  @override
  _PageAppGeneralState createState() => _PageAppGeneralState();
}

class _PageAppGeneralState extends State<PageAppGeneral>
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

  StreamSubscription<QuerySnapshot>? _lostObjectsSubscription;

  @override
  void initState() {
    super.initState();
    // Inicializar el AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Configurar el listener inicialmente
    _setupLostObjectsListener();

    // Añadir un listener al controlador de desplazamiento
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          !(_searchQuery.isNotEmpty &&
              _rangeStart != null &&
              _rangeEnd != null)) {
        _setupLostObjectsListener();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _lostObjectsSubscription?.cancel(); // Cancelar la suscripción al listener
    super.dispose();
  }

  // Función para verificar si dos fechas son el mismo día, mes y año
  bool _isSameDate(DateTime a, DateTime b) {
    return a.day == b.day && a.month == b.month && a.year == b.year;
  }

  // Función para obtener el inicio del día
  DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  // Función para obtener el fin del día
  DateTime _getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Función para formatear la fecha como "día mes" (ejemplo: 15 Septiembre)
  String _formatDate(DateTime date) {
    // que muestr el dia y el mes abrebiado
    final DateFormat formatter = DateFormat('d MMM');
    return formatter.format(date);
  }

  // Función para formatear la fecha y hora para mostrar en la lista
  String _formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('d MMM y, HH:mm');
    return formatter.format(date);
  }

  // Función para obtener los objetos perdidos con filtrado por fecha y/o búsqueda
  void _setupLostObjectsListener({bool isRefresh = false}) {
    try {
      // Cancelar cualquier suscripción previa si existe
      if (_lostObjectsSubscription != null) {
        _lostObjectsSubscription?.cancel();
        _lostObjectsSubscription = null;
      }

      // Obtener el usuario actual
      final authState = Provider.of<AuthState>(context, listen: false);
      final Usuario? currentUser = authState.user;

      // Determinar el tipo de consulta según los filtros activos
      if (_searchQuery.isNotEmpty && _rangeStart != null && _rangeEnd != null) {
        // **Caso 3: Filtrado por fecha y búsqueda por objeto**

        DateTime startOfStart = _getStartOfDay(_rangeStart!);
        DateTime endOfEnd = _getEndOfDay(_rangeEnd!);
        setState(() {
          _isLoading = true;
        });

        // Consultas para objetos aprobados y propios no aprobados dentro del rango de fechas y con el término de búsqueda
        Query queryApproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('aprobado', isEqualTo: true)
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true);

        Query queryOwnUnapproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('uidEncontrado', isEqualTo: currentUser?.id)
            .where('aprobado', isEqualTo: false)
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true);

        Future.wait([
          queryApproved.get(),
          queryOwnUnapproved.get(),
        ]).then((List<QuerySnapshot> results) {
          final approvedDocs = results[0].docs;
          final ownUnapprovedDocs = results[1].docs;

          // Combinar y eliminar duplicados
          final allDocs = {for (var doc in approvedDocs) doc.id: doc};
          for (var doc in ownUnapprovedDocs) {
            allDocs[doc.id] = doc;
          }

          // Filtrar por término de búsqueda
          final combinedDocs = allDocs.values.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final tipoObjeto = data['tipoObjeto']?.toString().toLowerCase() ?? '';
            return tipoObjeto.contains(_searchQuery.toLowerCase());
          }).toList();

          // Convertir a instancias de LostObject
          final newObjects = combinedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (combinedDocs.isNotEmpty) {
              _lastDocument = combinedDocs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }).catchError((error) {
          print("Error al cargar los objetos perdidos: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else if (_searchQuery.isNotEmpty) {
        // **Caso 2: Solo búsqueda por objeto**

        Query queryApproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('aprobado', isEqualTo: true)
            .orderBy('tipoObjeto')
            .startAt([_searchQuery.toLowerCase()])
            .endAt([_searchQuery.toLowerCase() + '\uf8ff'])
            .limit(_perPage);

        Query queryOwnUnapproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('uidEncontrado', isEqualTo: currentUser?.id)
            .where('aprobado', isEqualTo: false)
            .orderBy('tipoObjeto')
            .startAt([_searchQuery.toLowerCase()])
            .endAt([_searchQuery.toLowerCase() + '\uf8ff'])
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }

        Future.wait([
          queryApproved.get(),
          queryOwnUnapproved.get(),
        ]).then((List<QuerySnapshot> results) {
          final approvedDocs = results[0].docs;
          final ownUnapprovedDocs = results[1].docs;

          // Combinar y eliminar duplicados
          final allDocs = {for (var doc in approvedDocs) doc.id: doc};
          for (var doc in ownUnapprovedDocs) {
            allDocs[doc.id] = doc;
          }

          final combinedDocs = allDocs.values.toList();

          final newObjects = combinedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (combinedDocs.isNotEmpty) {
              _lastDocument = combinedDocs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }).catchError((error) {
          print("Error al cargar los objetos perdidos: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else if (_rangeStart != null && _rangeEnd != null) {
        // **Caso 1: Solo filtrado por fecha**

        DateTime startOfStart = _getStartOfDay(_rangeStart!);
        DateTime endOfEnd = _getEndOfDay(_rangeEnd!);

        Query queryApproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('aprobado', isEqualTo: true)
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        Query queryOwnUnapproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('uidEncontrado', isEqualTo: currentUser?.id)
            .where('aprobado', isEqualTo: false)
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }

        Future.wait([
          queryApproved.get(),
          queryOwnUnapproved.get(),
        ]).then((List<QuerySnapshot> results) {
          final approvedDocs = results[0].docs;
          final ownUnapprovedDocs = results[1].docs;

          // Combinar y eliminar duplicados
          final allDocs = {for (var doc in approvedDocs) doc.id: doc};
          for (var doc in ownUnapprovedDocs) {
            allDocs[doc.id] = doc;
          }

          final combinedDocs = allDocs.values.toList();

          final newObjects = combinedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (combinedDocs.isNotEmpty) {
              _lastDocument = combinedDocs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }).catchError((error) {
          print("Error al cargar los objetos perdidos: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else {
        // **Caso 0: Sin filtros**

        Query queryApproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('aprobado', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        Query queryOwnUnapproved = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('uidEncontrado', isEqualTo: currentUser?.id)
            .where('aprobado', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }

        Future.wait([
          queryApproved.get(),
          queryOwnUnapproved.get(),
        ]).then((List<QuerySnapshot> results) {
          final approvedDocs = results[0].docs;
          final ownUnapprovedDocs = results[1].docs;

          // Combinar y eliminar duplicados
          final allDocs = {for (var doc in approvedDocs) doc.id: doc};
          for (var doc in ownUnapprovedDocs) {
            allDocs[doc.id] = doc;
          }

          final combinedDocs = allDocs.values.toList();

          final newObjects = combinedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (combinedDocs.isNotEmpty) {
              _lastDocument = combinedDocs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }).catchError((error) {
          print("Error al cargar los objetos perdidos: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });
      }
    } catch (error) {
      print("Error al configurar el listener de objetos perdidos: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al configurar la escucha de objetos perdidos.')),
      );
    }
  }

  // Función para refrescar la lista (pull to refresh)
  Future<void> _refreshLostObjects() async {
    _setupLostObjectsListener(isRefresh: true);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rangeStart = selectedDay; // Asignar la fecha seleccionada sin conversión
      _rangeEnd = selectedDay; // Asignar la misma fecha para indicar un solo día
      _isCalendarVisible = false;
      _animationController.reverse(); // Contraer el calendario
    });
    _setupLostObjectsListener(isRefresh: true); // Recargar los objetos con el nuevo filtro
  }

  // Funciones del calendario

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null; // Limpiamos la selección individual
      _focusedDay = focusedDay;

      if (start != null) {
        _rangeStart = start; // Asignar la fecha de inicio sin conversión
      }

      if (end != null) {
        _rangeEnd = end;       // Fin del último día del rango
        _isCalendarVisible = false;
        _animationController.reverse(); // Contraer el calendario
      } else if (start != null) {
        _rangeEnd = start;     // Si no hay fin, usar el inicio
      }

    });
    _setupLostObjectsListener(isRefresh: true); // Recargar los objetos con el nuevo filtro
  }

  @override
  Widget build(BuildContext context) {
    // Definir los objetos a mostrar según los filtros activos
    List<LostObject> displayObjects;
    if (_searchQuery.isNotEmpty && _rangeStart != null && _rangeEnd != null) {
      // **Caso 3: Filtrado por fecha y búsqueda por objeto**
      // Filtrar localmente los objetos cargados por búsqueda
      displayObjects = _lostObjects
          .where((obj) =>
          obj.tipoObjeto.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else {
      // **Caso 0, 1 y 2: Sin filtros combinados**
      displayObjects = _lostObjects;
    }

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
            icon: Icon(Icons.calendar_month_outlined, color: Colors.white),
            label: Text(
              _rangeStart != null && _rangeEnd != null
                  ? _isSameDate(_rangeStart!, _rangeEnd!)
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
                      _setupLostObjectsListener(isRefresh: true);
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
                  _setupLostObjectsListener(isRefresh: true);
                },
              ),
            ),
          // Calendario animado
          _buildAnimatedCalendar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLostObjects,
              child: _isLoading && displayObjects.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : displayObjects.isEmpty
                  ? Center(
                child: Text(
                  _isSearching
                      ? 'No hay resultados para "$_searchQuery"'
                      : 'No hay objetos perdidos.',
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: displayObjects.length +
                    (_hasMore &&
                        !(_searchQuery.isNotEmpty &&
                            _rangeStart != null &&
                            _rangeEnd != null)
                        ? 1
                        : 0),
                itemBuilder: (context, index) {
                  if (index < displayObjects.length) {
                    final lostObject = displayObjects[index];
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
                    _setupLostObjectsListener(isRefresh: true);
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
    // Obtener el usuario actual
    final authState = Provider.of<AuthState>(context, listen: false);
    final Usuario? currentUser = authState.user;

    // Definir GlobalKeys para los iconos
    final GlobalKey iconKey = GlobalKey();

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
                if (lostObject.estadoReclamacion == 'Entregado')
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Entregado',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // **Nuevos Iconos de Aprobación en la esquina superior derecha**
                // Icono de aprobación pendiente
                if (lostObject.aprobado == false && lostObject.uidEncontrado == currentUser?.id)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      key: iconKey, // Asignar el GlobalKey
                      onTap: () {
                        _showApprovalInfo(context, approved: false, iconKey: iconKey);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.8), // Fondo naranja semi-transparente
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_empty,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                // Icono de aprobado
                if (lostObject.aprobado == true && lostObject.uidEncontrado == currentUser?.id)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      key: iconKey, // Asignar el GlobalKey
                      onTap: () {
                        _showApprovalInfo(context, approved: true, iconKey: iconKey);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8), // Fondo verde semi-transparente
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
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

  // Función para mostrar el contenedor flotante con animación
  void _showApprovalInfo(BuildContext context, {required bool approved, required GlobalKey iconKey}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Obtener la posición del icono utilizando el GlobalKey
    RenderBox renderBox = iconKey.currentContext?.findRenderObject() as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero);
    Size size = renderBox.size;

    overlayEntry = OverlayEntry(
      builder: (context) => ApprovalInfoOverlay(
        approved: approved,
        position: position,
        size: size,
        onClose: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay?.insert(overlayEntry);
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
                        'https://www.gravatar.com/avatar/15'),
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LostObjectsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.assignment_turned_in),
            title: Text('Objetos reclamados'),
            onTap: () {
              Navigator.pop(context); // Cerrar el cajón
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClaimedObjectsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.map),
            title: Text('Mapa de entrega de objetos perdidos'),
            onTap: () {
              Navigator.pop(context); // Cerrar el cajón
              // Navegar a la página correspondiente
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LostObjectPickupPage()),
              );
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

class ApprovalInfoOverlay extends StatefulWidget {
  final bool approved;
  final Offset position;
  final Size size;
  final VoidCallback onClose;

  ApprovalInfoOverlay({
    required this.approved,
    required this.position,
    required this.size,
    required this.onClose,
  });

  @override
  _ApprovalInfoOverlayState createState() => _ApprovalInfoOverlayState();
}

class _ApprovalInfoOverlayState extends State<ApprovalInfoOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Cerrar el overlay al tocar fuera o después de 5 segundos
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla
    final screenSize = MediaQuery.of(context).size;

    // Calcular la posición del contenedor flotante
    // Ajusta los valores según necesites
    double containerTop = widget.position.dy - 10;
    double containerRight = screenSize.width - widget.position.dx - widget.size.width - 10;

    // Asegurar que el contenedor no salga de la pantalla
    if (containerTop < 0) containerTop = 10;
    if (containerRight < 0) containerRight = 10;

    return GestureDetector(
      onTap: () {
        widget.onClose();
      },
      child: Material(
        color: Colors.transparent, // Fondo transparente para permitir ver la animación
        child: Stack(
          children: [
            // Animación de Ripple
            Positioned(
              top: widget.position.dy + widget.size.height / 2 - 50 * _rippleAnimation.value,
              right: screenSize.width - widget.position.dx - widget.size.width / 2 - 50 * _rippleAnimation.value,
              child: AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100 * _rippleAnimation.value,
                    height: 100 * _rippleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.approved
                          ? Colors.green.withOpacity(0.5)
                          : Colors.orange.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),
            // Contenedor con el mensaje
            Positioned(
              top: containerTop,
              right: containerRight,
              child: FadeTransition(
                opacity: _animationController,
                child: ScaleTransition(
                  scale: _animationController,
                  child: Container(
                    width: 250, // Ajusta el ancho según tus necesidades
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: widget.approved ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      widget.approved
                          ? 'Este objeto ha sido aprobado y ahora es visible para todos.'
                          : 'Este objeto está en proceso de aceptación y no será mostrado hasta que sea aprobado.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




