import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_backtome/views/administradores/userLIstPage.dart';
import 'package:flutter_backtome/views/usuarios/registrarObjetoPerdido.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Importar intl para formatear fechas

import '../../services/usuarioRegistrado.dart';
import '../administradorBD/objetosPerdidosBD.dart';
import '../administradorBD/usuariosBD.dart';
import '../usuarios/ClaimedObjectsPage.dart';
import '../usuarios/ObjetoDetalles.dart';
import '../usuarios/UserAccountPage.dart';
import '../usuarios/listaObjetosAgregados.dart';
import 'detallesEntregaObjeto.dart';

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

  StreamSubscription<QuerySnapshot>? _lostObjectsSubscription;

  Map<String, List<dynamic>> _events = {};
  int _totalPublishedObjects = 0;



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
    _loadAllLostObjectsForCalendar();
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
    // que muestre el dia y el mes abreviado
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

      // Determinar el tipo de consulta según los filtros activos
      if (_searchQuery.isNotEmpty && _rangeStart != null && _rangeEnd != null) {
        // **Caso 3: Filtrado por fecha y búsqueda por objeto**
        // Realizar una consulta solo por fecha y luego filtrar localmente

        DateTime startOfStart = _getStartOfDay(_rangeStart!);
        DateTime endOfEnd = _getEndOfDay(_rangeEnd!);
        setState(() {
          _isLoading = true;
        });

        Query query = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true);

        // Obtener los datos una sola vez (no en tiempo real)
        _lostObjectsSubscription = query.snapshots().listen((QuerySnapshot querySnapshot) {
          final newObjects = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (querySnapshot.docs.isNotEmpty) {
              _lastDocument = querySnapshot.docs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }, onError: (error) {
          print("Error al cargar los objetos perdidos desde Firestore: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else if (_searchQuery.isNotEmpty) {
        // **Caso 2: Solo búsqueda por objeto**
        // Configurar la consulta con el término de búsqueda

        Query query = FirebaseFirestore.instance.collection('objetos_perdidos');

        String searchLower = _searchQuery.toLowerCase();
        query = query
            .orderBy('tipoObjeto')
            .startAt([searchLower])
            .endAt([searchLower + '\uf8ff'])
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }

        if (_lastDocument != null && !isRefresh) {
          query = query.startAfterDocument(_lastDocument!);
        }

        _lostObjectsSubscription = query.snapshots().listen((QuerySnapshot querySnapshot) {
          final newObjects = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (querySnapshot.docs.isNotEmpty) {
              _lastDocument = querySnapshot.docs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }, onError: (error) {
          print("Error al cargar los objetos perdidos desde Firestore: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else if (_rangeStart != null && _rangeEnd != null) {
        // **Caso 1: Solo filtrado por fecha**
        // Configurar la consulta con el rango de fechas

        DateTime startOfStart = _getStartOfDay(_rangeStart!);
        DateTime endOfEnd = _getEndOfDay(_rangeEnd!);

        Query query = FirebaseFirestore.instance.collection('objetos_perdidos')
            .where('timestamp', isGreaterThanOrEqualTo: startOfStart)
            .where('timestamp', isLessThanOrEqualTo: endOfEnd)
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }
        // Si no es una actualización, continuar desde el último documento
        if (_lastDocument != null && !isRefresh) {
          query = query.startAfterDocument(_lastDocument!);
        }
        // Escuchar los cambios en tiempo real
        _lostObjectsSubscription = query.snapshots().listen((QuerySnapshot querySnapshot) {
          final newObjects = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {
            if (isRefresh) {
              _lostObjects = newObjects;
            } else {
              _lostObjects.addAll(newObjects);
            }

            if (querySnapshot.docs.isNotEmpty) {
              _lastDocument = querySnapshot.docs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
          });
        }, onError: (error) {
          print("Error al cargar los objetos perdidos desde Firestore: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar los objetos perdidos.')),
          );
          setState(() {
            _isLoading = false;
          });
        });

      } else {
        // **Caso 0: Sin filtros**
        // Configurar la consulta por defecto

        Query query = FirebaseFirestore.instance.collection('objetos_perdidos')
            .orderBy('timestamp', descending: true)
            .limit(_perPage);

        if (isRefresh) {
          _lastDocument = null;
          _hasMore = true;
          _lostObjects = [];
        }

        if (_lastDocument != null && !isRefresh) {
          query = query.startAfterDocument(_lastDocument!);
        }

        _lostObjectsSubscription = query.snapshots().listen((QuerySnapshot querySnapshot) {
          final newObjects = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return LostObject.fromMap(data, doc.id);
          }).toList();

          setState(() {

            _lostObjects = newObjects;


            if (querySnapshot.docs.isNotEmpty) {
              _lastDocument = querySnapshot.docs.last;
              _hasMore = newObjects.length == _perPage;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
            print('Objetos perdidos cargados: ${_lostObjects.length}');
          });
        }, onError: (error) {
          print("Error al cargar los objetos perdidos desde Firestore: $error");
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
          'Administrar objetos perdidos',
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
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return _buildBottomDrawer();
                  },
                );
              },
            ),
            Expanded(
              child: Text(
                'Objetos publicados: $_totalPublishedObjects',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (_isSearching) {
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  } else {
                    _searchQuery = '';
                    _searchController.clear();
                    _setupLostObjectsListener(isRefresh: true);
                    FocusScope.of(context).unfocus();
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
        // Navegar a la pantalla de detalles al tocar el card
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LostObjectDetailPageAdmin(lostObject: lostObject),
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
                // Icono y texto para aprobación o eliminación
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (lostObject.aprobado == false || lostObject.aprobado == null) {
                        _showApprovalOrDeleteDialog(lostObject);
                      } else {
                        _confirmDeleteObject(lostObject);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: (lostObject.aprobado ?? false)
                            ? Colors.red.withOpacity(0.8)
                            : Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (lostObject.aprobado ?? false) ? Icons.delete : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 4),
                          Text(
                            (lostObject.aprobado ?? false) ? 'Eliminar' : 'Aprobar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
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
                  // Mostrar el nombre del usuario que encontró el objeto
                  Text(
                    'Encontrado por: ${lostObject.nombreEncontrado}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  // Mostrar información de reclamaciones
                  if (lostObject.reclamaciones.isNotEmpty)
                    Builder(
                      builder: (context) {
                        if (lostObject.reclamaciones.length == 1) {
                          // Mostrar el nombre del único reclamante
                          return Text(
                            'Reclamado por: ${lostObject.reclamaciones.first.nombreReclamante}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          );
                        } else {
                          // Mostrar el número de reclamantes
                          return Text(
                            'Reclamado por: ${lostObject.reclamaciones.length} personas',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalOrDeleteDialog(LostObject lostObject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar o Eliminar'),
        content: Text('¿Deseas aprobar o eliminar este objeto?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteLostObject(lostObject);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _approveLostObject(lostObject);
            },
            child: Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _approveLostObject(LostObject lostObject) async {
    try {
      // Actualizar el campo 'aprobado' en Firestore
      await FirebaseFirestore.instance
          .collection('objetos_perdidos')
          .doc(lostObject.id)
          .update({'aprobado': true});

      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El objeto ha sido aprobado.')),
      );

      // Actualizar el estado localmente
      setState(() {
        lostObject.aprobado = true;
      });
    } catch (e) {
      // Mostrar un mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aprobar el objeto: $e')),
      );
    }
  }

  void _deleteLostObject(LostObject lostObject) async {
    try {
      // Eliminar el documento de Firestore
      await FirebaseFirestore.instance.collection('objetos_perdidos').doc(lostObject.id).delete();

      // Eliminar la imagen del objeto del Storage
      if (lostObject.imagenUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(lostObject.imagenUrl).delete();
      }

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClaimedObjectsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Usuarios registrados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserListPage()),
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
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          rangeStartDay: _rangeStart,
          rangeEndDay: _rangeEnd,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
          ),
          eventLoader: (day) {
            String dateKey = DateFormat('yyyy-MM-dd').format(day);
            return _events[dateKey] ?? [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: _buildEventsMarker(),
                );
              }
              return SizedBox();
            },
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

  Widget _buildEventsMarker() {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red, // Color del marcador
      ),
    );
  }


  Future<void> _loadAllLostObjectsForCalendar() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('objetos_perdidos')
          .get();

      Map<String, List<dynamic>> events = {};
      int totalObjects = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lostObject = LostObject.fromMap(data, doc.id);

        // Incrementar el contador total
        totalObjects++;

        // Obtener la fecha del objeto en formato 'yyyy-MM-dd'
        String dateKey = DateFormat('yyyy-MM-dd').format(lostObject.timestamp);

        // Agrupar los objetos por fecha
        if (events.containsKey(dateKey)) {
          events[dateKey]!.add(lostObject);
        } else {
          events[dateKey] = [lostObject];
        }
      }

      setState(() {
        _events = events;
        _totalPublishedObjects = totalObjects;
      });
    } catch (e) {
      print("Error al cargar los objetos perdidos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los objetos perdidos.')),
      );
    }
  }
}
