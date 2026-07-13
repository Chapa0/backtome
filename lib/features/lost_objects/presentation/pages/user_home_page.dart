import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/add_lost_object_page.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/core/router/app_router.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';
import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_object_points_firestore_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/approve_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/deliver_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/receive_lost_object_at_point_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/reject_lost_object_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/watch_visible_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/users/domain/entities/usuario.dart';
import 'package:flutter_backtome/features/claims/presentation/pages/claimed_objects_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/lost_object_detail_page.dart';
import 'package:flutter_backtome/features/users/presentation/pages/user_account_page.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/pages/user_lost_objects_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_backtome/shared/widgets/image_viewer_dialog.dart';

class PageAppGeneral extends StatefulWidget {
  @override
  _PageAppGeneralState createState() => _PageAppGeneralState();
}

class _PageAppGeneralState extends State<PageAppGeneral>
    with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF1B396A);

  // ─── Datos ───────────────────────────────────────────────
  List<LostObject> _lostObjects = [];
  LostObject? _selectedObject;
  StreamSubscription<List<LostObject>>? _lostObjectsSubscription;

  bool _isLoading = false;
  bool _hasMore = false;

  // ─── Filtros ─────────────────────────────────────────────
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  bool _isCalendarVisible = false;
  late AnimationController _animController;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // ─── Scroll ──────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();

  // ─── Mapa Mapbox ─────────────────────────────────────────
  mb.MapboxMap? _mapboxMap;
  mb.CircleAnnotationManager? _circleManager;
  final Map<String, mb.CircleAnnotation> _circleAnnotations = {};
  final mb.CameraViewportState _initialMapViewport = mb.CameraViewportState(
    center: mb.Point(coordinates: mb.Position(-96.1342, 19.1738)),
    zoom: 12,
  );
  bool _mapStyleLoaded = false;

  // ─── Panel ───────────────────────────────────────────────
  static const double _panelPeekSize = 0.075;
  static const double _panelListSize = 0.42;
  static const double _panelFullSize = 0.96;
  double _panelSize = _panelPeekSize;
  bool _panelOpen = false;
  bool _panelShowingDetail = false;
  bool _panelDragging = false;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _setupLostObjectsListener();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        !(_searchQuery.isNotEmpty &&
            _rangeStart != null &&
            _rangeEnd != null)) {
      _setupLostObjectsListener();
    }
  }

  @override
  void dispose() {
    _lostObjectsSubscription?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // DATOS DESDE FIRESTORE
  // ═══════════════════════════════════════════════════════════

  void _setupLostObjectsListener({bool isRefresh = false}) {
    if (_lostObjectsSubscription != null) {
      if (mounted) setState(() {});
      _renderMarkers();
      return;
    }

    final user = Provider.of<AuthState>(context, listen: false).user;
    setState(() => _isLoading = true);

    _lostObjectsSubscription = locator<WatchVisibleLostObjectsUseCase>()(
      user: user,
    ).listen(
      (objects) async {
        if (!mounted) return;
        setState(() {
          _lostObjects = objects;
          _hasMore = false;
          _isLoading = false;
          _syncSelectedObject(objects);
        });
        await _renderMarkers();
      },
      onError: (Object error) {
        _showError(error.toString());
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _syncSelectedObject(List<LostObject> objects) {
    final selectedObject = _selectedObject;
    if (selectedObject == null) return;

    for (final object in objects) {
      if (object.id == selectedObject.id) {
        _selectedObject = object;
        return;
      }
    }

    _selectedObject = null;
    _panelShowingDetail = false;
  }

  void _showError(String msg) {
    debugPrint(msg);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los objetos perdidos.')),
      );
    }
  }

  bool get _isAdminUser {
    final user = Provider.of<AuthState>(context, listen: false).user;
    return user?.tipoUsuario == 'admin';
  }

  Reclamacion? _currentUserClaim(LostObject object) {
    final user = Provider.of<AuthState>(context, listen: false).user;
    if (user == null) return null;

    for (final claim in object.reclamaciones) {
      if (claim.uidReclamante == user.id) return claim;
    }
    return null;
  }

  String _formatClaimDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  List<LostObject> get _visibleObjects {
    final filteredObjects =
        _lostObjects.where(_matchesSearchAndDateFilters).toList();

    if (!_isAdminUser) {
      return filteredObjects
          .where((object) => object.rechazado != true)
          .toList();
    }

    switch (_statusFilter) {
      case 'pendingApproval':
        return filteredObjects
            .where(
                (object) => object.aprobado == false || object.aprobado == null)
            .where((object) => object.rechazado != true)
            .toList();
      case 'rejected':
        return filteredObjects
            .where((object) => object.rechazado == true)
            .toList();
      case 'approved':
        return filteredObjects
            .where((object) => object.aprobado == true)
            .toList();
      case 'claimed':
        return filteredObjects
            .where((object) => object.estadoReclamacion == 'Pendiente')
            .toList();
      case 'delivered':
        return filteredObjects
            .where((object) => object.estadoReclamacion == 'Entregado')
            .toList();
      default:
        return filteredObjects;
    }
  }

  bool _matchesSearchAndDateFilters(LostObject object) {
    final normalizedSearch = _searchQuery.trim().toLowerCase();
    final matchesSearch = normalizedSearch.isEmpty ||
        object.tipoObjeto.toLowerCase().contains(normalizedSearch) ||
        object.descripcion.toLowerCase().contains(normalizedSearch);

    if (_rangeStart == null || _rangeEnd == null) return matchesSearch;

    final start = DateTime(
      _rangeStart!.year,
      _rangeStart!.month,
      _rangeStart!.day,
    );
    final end = DateTime(
      _rangeEnd!.year,
      _rangeEnd!.month,
      _rangeEnd!.day,
      23,
      59,
      59,
      999,
    );
    return matchesSearch &&
        !object.timestamp.isBefore(start) &&
        !object.timestamp.isAfter(end);
  }

  // ═══════════════════════════════════════════════════════════
  // MAPA MAPBOX
  // ═══════════════════════════════════════════════════════════

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  void _onStyleLoaded(mb.StyleLoadedEventData _) {
    _mapStyleLoaded = true;
    _setupAnnotationsAndRender();
  }

  Future<void> _setupAnnotationsAndRender() async {
    await _initAnnotationManagers();
    await _renderMarkers();
    await _fitCameraToMarkers();
  }

  Future<void> _initAnnotationManagers() async {
    if (_mapboxMap == null) return;
    _circleManager =
        await _mapboxMap!.annotations.createCircleAnnotationManager();
    _circleManager!.tapEvents(onTap: _onCircleTapped);
  }

  Future<void> _renderMarkers() async {
    if (!_mapStyleLoaded || _circleManager == null) return;

    // Remove existing circle annotations
    for (final a in _circleAnnotations.values) {
      try {
        await _circleManager!.delete(a);
      } catch (_) {}
    }
    _circleAnnotations.clear();

    // Create new circle annotations
    for (final obj in _visibleObjects) {
      final lat = _markerLatitude(obj);
      final lng = _markerLongitude(obj);
      if (lat == null || lng == null) continue;
      final color =
          _markerColorForState(obj.estadoReclamacion ?? 'No reclamado');
      final isSelected = _selectedObject?.id == obj.id;
      try {
        final annotation = await _circleManager!.create(
          mb.CircleAnnotationOptions(
            geometry: mb.Point(coordinates: mb.Position(lng, lat)),
            circleColor: color,
            circleStrokeColor: isSelected ? 0xFFFFFFFF : color,
            circleStrokeWidth: isSelected ? 4 : 2,
            circleRadius: isSelected ? 16 : 10,
            circleSortKey: isSelected ? 2 : 1,
            customData: {'objectId': obj.id},
          ),
        );
        _circleAnnotations[obj.id] = annotation;
      } catch (e) {
        debugPrint('Error creating marker for ${obj.id}: $e');
      }
    }
  }

  int _markerColorForState(String estado) {
    switch (estado) {
      case 'Pendiente':
        return 0xFFFFA726; // naranja - en proceso
      case 'Entregado':
        return 0xFF66BB6A; // verde - entregado
      default:
        return 0xFFEF5350; // rojo - no reclamado (perdido)
    }
  }

  void _onCircleTapped(mb.CircleAnnotation annotation) {
    final objectId = annotation.customData?['objectId'] as String?;
    if (objectId == null) return;
    LostObject? obj;
    for (final candidate in _lostObjects) {
      if (candidate.id == objectId) {
        obj = candidate;
        break;
      }
    }
    if (obj != null) _selectObject(obj);
  }

  Future<void> _fitCameraToMarkers() async {
    final objects = _visibleObjects;
    if (_mapboxMap == null || objects.isEmpty) return;
    final pts = objects
        .where((o) => _markerLatitude(o) != null && _markerLongitude(o) != null)
        .map(
          (o) => mb.Point(
            coordinates: mb.Position(_markerLongitude(o)!, _markerLatitude(o)!),
          ),
        )
        .toList();
    if (pts.isEmpty) return;

    try {
      final cam = await _mapboxMap!.cameraForCoordinatesPadding(
        pts,
        mb.CameraOptions(),
        mb.MbxEdgeInsets(top: 48, left: 48, bottom: 300, right: 48),
        15,
        null,
      );
      await _mapboxMap!.setCamera(cam);
    } catch (_) {}
  }

  Future<void> _focusOnObject(LostObject obj) async {
    final lat = _markerLatitude(obj);
    final lng = _markerLongitude(obj);
    if (_mapboxMap == null || lat == null || lng == null) return;
    try {
      await _mapboxMap!.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lng, lat)),
          zoom: 16,
        ),
        mb.MapAnimationOptions(duration: 500),
      );
    } catch (_) {}
  }

  Future<void> _focusOnCustodyPoint(LostObject obj) async {
    if (_mapboxMap == null ||
        obj.puntoCustodiaLatitud == null ||
        obj.puntoCustodiaLongitud == null) {
      return;
    }
    try {
      await _mapboxMap!.flyTo(
        mb.CameraOptions(
          center: mb.Point(
            coordinates: mb.Position(
              obj.puntoCustodiaLongitud!,
              obj.puntoCustodiaLatitud!,
            ),
          ),
          zoom: 16,
        ),
        mb.MapAnimationOptions(duration: 500),
      );
    } catch (_) {}
  }

  String _custodyDescription(LostObject obj) {
    if (obj.estadoReclamacion == 'Entregado') {
      return 'Entregado a ${obj.nombreReclamado ?? 'reclamante'}';
    }

    if (obj.estaEnPuntoCustodia) {
      return 'En punto de entrega: ${obj.puntoCustodiaNombre ?? obj.custodiaLabel}';
    }

    return 'Lo tiene ${obj.custodiaLabel}';
  }

  // ═══════════════════════════════════════════════════════════
  // SELECCIÓN / PANEL
  // ═══════════════════════════════════════════════════════════

  void _selectObject(LostObject obj) {
    setState(() {
      _selectedObject = obj;
      _panelOpen = true;
      _panelShowingDetail = true;
    });
    _animatePanelTo(_panelFullSize);
    _renderMarkers();
    _focusOnObject(obj);
  }

  void _deselectObject() {
    setState(() {
      _selectedObject = null;
      _panelShowingDetail = false;
    });
    _renderMarkers();
  }

  void _closePanel() {
    setState(() {
      _panelSize = _panelPeekSize;
      _panelOpen = false;
      _panelShowingDetail = false;
      _selectedObject = null;
    });
    debugPrint('[UP_PANEL] close target=$_panelPeekSize');
  }

  Future<void> _animatePanelTo(double size) {
    final nextSize = size.clamp(_panelPeekSize, _panelFullSize);
    debugPrint(
      '[UP_PANEL] animate from=${_panelSize.toStringAsFixed(3)} '
      'to=${nextSize.toStringAsFixed(3)}',
    );
    setState(() {
      _panelSize = nextSize;
      _panelOpen = nextSize > _panelPeekSize + 0.02;
      if (!_panelOpen) {
        _panelShowingDetail = false;
        _selectedObject = null;
      }
    });
    return Future.value();
  }

  void _applyAdminStatusFilter(String filter) {
    setState(() {
      _statusFilter = filter;
      if (_selectedObject != null &&
          !_visibleObjects.any((object) => object.id == _selectedObject!.id)) {
        _selectedObject = null;
        _panelShowingDetail = false;
      }
    });
    _renderMarkers();
  }

  void _dragPanel(DragUpdateDetails details) {
    final panelHeight = _availablePanelHeight(context);
    final nextSize = (_panelSize - (details.primaryDelta ?? 0) / panelHeight)
        .clamp(_panelPeekSize, _panelFullSize);
    debugPrint(
      '[UP_PANEL] drag update delta=${details.primaryDelta?.toStringAsFixed(1)} '
      'from=${_panelSize.toStringAsFixed(3)} '
      'to=${nextSize.toStringAsFixed(3)}',
    );
    setState(() {
      _panelDragging = true;
      _panelSize = nextSize;
      _panelOpen = nextSize > _panelPeekSize + 0.02;
      if (!_panelOpen) {
        _panelShowingDetail = false;
        _selectedObject = null;
      }
    });
  }

  double _availablePanelHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = AppBar().preferredSize.height;
    const bottomBarHeight = kBottomNavigationBarHeight;
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        appBarHeight -
        bottomBarHeight;

    return availableHeight.clamp(320.0, mediaQuery.size.height);
  }

  void _snapPanel(DragEndDetails details) {
    final current = _panelSize;
    final velocity = details.primaryVelocity ?? 0;
    double target;

    if (velocity < -700) {
      target = current < _panelListSize ? _panelListSize : _panelFullSize;
    } else if (velocity > 700) {
      target = current > _panelListSize ? _panelListSize : _panelPeekSize;
    } else {
      final snapPoints = [_panelPeekSize, _panelListSize, _panelFullSize];
      target = snapPoints
          .reduce((a, b) => (current - a).abs() < (current - b).abs() ? a : b);
    }

    debugPrint(
      '[UP_PANEL] drag end current=${current.toStringAsFixed(3)} '
      'velocity=${velocity.toStringAsFixed(1)} '
      'target=${target.toStringAsFixed(3)}',
    );

    if (target <= _panelPeekSize + 0.01) {
      setState(() => _panelDragging = false);
      _closePanel();
      return;
    }

    setState(() {
      _panelDragging = false;
      _panelOpen = true;
    });
    _animatePanelTo(target);
  }

  Widget _buildPanelHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) {
        debugPrint(
          '[UP_PANEL] drag start size=${_panelSize.toStringAsFixed(3)}',
        );
        setState(() => _panelDragging = true);
      },
      onVerticalDragUpdate: _dragPanel,
      onVerticalDragEnd: _snapPanel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FILTROS DE FECHA
  // ═══════════════════════════════════════════════════════════

  void _onDaySelected(DateTime day, DateTime focused) {
    setState(() {
      _selectedDay = day;
      _focusedDay = focused;
      _rangeStart = day;
      _rangeEnd = day;
      _isCalendarVisible = false;
      _animController.reverse();
    });
    _setupLostObjectsListener(isRefresh: true);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focused) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focused;
      if (start != null) _rangeStart = start;
      if (end != null) _rangeEnd = end;
      if (start != null && end != null) {
        _isCalendarVisible = false;
        _animController.reverse();
      }
    });
    _setupLostObjectsListener(isRefresh: true);
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _isAdminUser ? 'Administrar objetos perdidos' : 'Objetos Perdidos',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
      ),
      body: Stack(
        children: [
          // ── Mapa de fondo ──
          Positioned.fill(
            child: mb.MapWidget(
              key: const ValueKey('homeMap'),
              viewport: _initialMapViewport,
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: _onStyleLoaded,
            ),
          ),

          // ── Panel inferior deslizable ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: _panelDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: _availablePanelHeight(context) * _panelSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2))
                ],
              ),
              child: _panelShowingDetail && _selectedObject != null
                  ? _buildDetailPanel()
                  : _buildListPanel(),
            ),
          ),
        ],
      ),

      // ── BottomAppBar ──
      bottomNavigationBar: BottomAppBar(
        color: _primaryColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _buildBottomDrawer(),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  _isCalendarVisible = !_isCalendarVisible;
                  if (_isCalendarVisible) {
                    _animatePanelTo(_panelFullSize);
                    _animController.forward();
                  } else {
                    _animController.reverse();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchQuery = '';
                    _searchCtrl.clear();
                    _setupLostObjectsListener(isRefresh: true);
                    _searchFocus.unfocus();
                  } else {
                    _animatePanelTo(_panelFullSize);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocus.requestFocus();
                    });
                  }
                });
              },
            ),
          ],
        ),
      ),

      // ── FAB para agregar ──
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => AddLostObjectPage()))
            .then((_) => _setupLostObjectsListener(isRefresh: true)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PANEL: LISTA
  // ═══════════════════════════════════════════════════════════

  Widget _buildListPanel() {
    final objects = _visibleObjects;
    return Column(
      children: [
        _buildPanelHandle(),
        if (_isSearching && _panelOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar objetos perdidos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                    });
                    _setupLostObjectsListener(isRefresh: true);
                  },
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v.trim());
                _setupLostObjectsListener(isRefresh: true);
              },
            ),
          ),
        if (_isCalendarVisible && _panelOpen) _buildAnimatedCalendar(),
        if (_panelOpen) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${objects.length} objetos',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          if (_isAdminUser) _buildAdminStatusFilters(),
          const Divider(height: 1),
          Expanded(
            child: objects.isEmpty
                ? const Center(child: Text('No hay objetos perdidos.'))
                : NotificationListener<ScrollNotification>(
                    onNotification: _handleListScrollNotification,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: objects.length +
                          (_hasMore || objects.isEmpty ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i < objects.length) {
                          return _buildLostObjectItem(objects[i]);
                        }
                        return _buildLoadingIndicator();
                      },
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  bool _handleListScrollNotification(ScrollNotification notification) {
    final atTop =
        notification.metrics.pixels <= notification.metrics.minScrollExtent;

    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        atTop &&
        notification.dragDetails!.delta.dy > 0) {
      _dragPanel(
        DragUpdateDetails(
          delta: Offset(0, notification.dragDetails!.delta.dy),
          primaryDelta: notification.dragDetails!.delta.dy,
          globalPosition: notification.dragDetails!.globalPosition,
          localPosition: notification.dragDetails!.localPosition,
        ),
      );
      return true;
    }

    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        atTop &&
        notification.dragDetails!.delta.dy > 0) {
      _dragPanel(
        DragUpdateDetails(
          delta: Offset(0, notification.dragDetails!.delta.dy),
          primaryDelta: notification.dragDetails!.delta.dy,
          globalPosition: notification.dragDetails!.globalPosition,
          localPosition: notification.dragDetails!.localPosition,
        ),
      );
      return true;
    }

    if (notification is ScrollEndNotification && _panelDragging) {
      _snapPanel(DragEndDetails(primaryVelocity: 0));
      return true;
    }

    return false;
  }

  Widget _buildAdminStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _buildAdminStatusChip('all', 'Todos', _lostObjects.length),
          _buildAdminStatusChip(
            'pendingApproval',
            'Pendientes',
            _lostObjects
                .where((object) =>
                    object.aprobado == false || object.aprobado == null)
                .where((object) => object.rechazado != true)
                .length,
          ),
          _buildAdminStatusChip(
            'rejected',
            'Rechazados',
            _lostObjects.where((object) => object.rechazado == true).length,
          ),
          _buildAdminStatusChip(
            'approved',
            'Aprobados',
            _lostObjects.where((object) => object.aprobado == true).length,
          ),
          _buildAdminStatusChip(
            'claimed',
            'Reclamados',
            _lostObjects
                .where((object) => object.estadoReclamacion == 'Pendiente')
                .length,
          ),
          _buildAdminStatusChip(
            'delivered',
            'Entregados',
            _lostObjects
                .where((object) => object.estadoReclamacion == 'Entregado')
                .length,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatusChip(String value, String label, int count) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => _applyAdminStatusFilter(value),
        selectedColor: _primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _primaryColor,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: selected ? _primaryColor : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildLostObjectItem(LostObject lostObject) {
    return GestureDetector(
      onTap: () => _selectObject(lostObject),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                lostObject.imagenUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
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
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: const Text('En proceso de reclamación',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (lostObject.estadoReclamacion == 'Entregado')
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: const Text('Entregado',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildApprovalBadge(lostObject),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lostObject.tipoObjeto,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                  const SizedBox(height: 8),
                  Text('Descripcion: ${lostObject.descripcion}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Encontrado en: ${lostObject.lugarEncontrado}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Custodia: ${_custodyDescription(lostObject)}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Fecha: ${_formatDateTime(lostObject.timestamp)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveLostObject(LostObject lostObject) async {
    final decision = await _showApprovalDialog(lostObject);
    /*
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar publicacion'),
        content: Text(
            '¿Deseas aprobar la publicacion de "${lostObject.tipoObjeto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    */
    if (decision == null) return;

    try {
      final currentUser = Provider.of<AuthState>(context, listen: false).user;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesion.');
      }

      await locator<ApproveLostObjectUseCase>()(
        requesterId: currentUser.id,
        object: lostObject,
        custodyPoint: decision.custodyPoint,
      );

      if (!mounted) return;
      setState(() {
        lostObject.aprobado = true;
        if (decision.custodyPoint != null) {
          _applyCustodyPoint(lostObject, decision.custodyPoint!);
        }
      });
      _renderMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El objeto ha sido aprobado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aprobar el objeto: $e')),
      );
    }
  }

  Future<_ApprovalDecision?> _showApprovalDialog(LostObject lostObject) async {
    final points = await locator<LostObjectPointsFirestoreDataSource>()
        .fetchActiveDropOffPoints();

    if (!mounted) return null;

    bool receiveAtPoint = false;
    LostObjectPoint? selectedPoint = points.isNotEmpty ? points.first : null;

    return showDialog<_ApprovalDecision>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Aprobar publicacion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Deseas aprobar la publicacion de "${lostObject.tipoObjeto}"?',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: receiveAtPoint,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Registrar recepcion en punto'),
                  subtitle: const Text(
                    'Si no se marca, el objeto seguira indicado con el usuario que lo publico.',
                  ),
                  onChanged: points.isEmpty
                      ? null
                      : (value) {
                          setDialogState(
                            () => receiveAtPoint = value ?? false,
                          );
                        },
                ),
                if (receiveAtPoint) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<LostObjectPoint>(
                    value: selectedPoint,
                    decoration: const InputDecoration(
                      labelText: 'Punto de entrega',
                      border: OutlineInputBorder(),
                    ),
                    items: points
                        .map(
                          (point) => DropdownMenuItem(
                            value: point,
                            child: Text(point.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (point) {
                      setDialogState(() => selectedPoint = point);
                    },
                  ),
                ],
                if (points.isEmpty)
                  const Text(
                    'No hay puntos de entrega activos configurados.',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    _ApprovalDecision(
                      custodyPoint: receiveAtPoint ? selectedPoint : null,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Aprobar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _receiveLostObjectAtPoint(LostObject lostObject) async {
    final point = await _selectDropOffPoint();
    if (point == null) return;

    try {
      final currentUser = Provider.of<AuthState>(context, listen: false).user;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesion.');
      }

      await locator<ReceiveLostObjectAtPointUseCase>()(
        requesterId: currentUser.id,
        object: lostObject,
        custodyPoint: point,
      );

      if (!mounted) return;
      setState(() => _applyCustodyPoint(lostObject, point));
      _renderMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Objeto recibido en ${point.nombre}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar recepcion: $e')),
      );
    }
  }

  double? _markerLatitude(LostObject obj) {
    if (obj.estaEnPuntoCustodia && obj.puntoCustodiaLatitud != null) {
      return obj.puntoCustodiaLatitud;
    }
    return obj.latitud;
  }

  double? _markerLongitude(LostObject obj) {
    if (obj.estaEnPuntoCustodia && obj.puntoCustodiaLongitud != null) {
      return obj.puntoCustodiaLongitud;
    }
    return obj.longitud;
  }

  Future<LostObjectPoint?> _selectDropOffPoint() async {
    final points = await locator<LostObjectPointsFirestoreDataSource>()
        .fetchActiveDropOffPoints();

    if (!mounted) return null;

    if (points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay puntos de entrega activos configurados.'),
        ),
      );
      return null;
    }

    LostObjectPoint selectedPoint = points.first;

    return showDialog<LostObjectPoint>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Registrar recepcion'),
            content: DropdownButtonFormField<LostObjectPoint>(
              value: selectedPoint,
              decoration: const InputDecoration(
                labelText: 'Punto de entrega',
                border: OutlineInputBorder(),
              ),
              items: points
                  .map(
                    (point) => DropdownMenuItem(
                      value: point,
                      child: Text(point.nombre),
                    ),
                  )
                  .toList(),
              onChanged: (point) {
                if (point != null) {
                  setDialogState(() => selectedPoint = point);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selectedPoint),
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _applyCustodyPoint(LostObject object, LostObjectPoint point) {
    object.custodiaEstado = 'en_punto';
    object.custodiaUid = null;
    object.custodiaNombre = point.nombre;
    object.puntoCustodiaId = point.id;
    object.puntoCustodiaNombre = point.nombre;
    object.puntoCustodiaLatitud = point.latitud;
    object.puntoCustodiaLongitud = point.longitud;
    object.fechaRecepcionPunto = DateTime.now();
  }

  Future<void> _rejectLostObject(LostObject lostObject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar publicacion'),
        content: Text(
            '¿Deseas rechazar la publicacion de "${lostObject.tipoObjeto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = Provider.of<AuthState>(context, listen: false).user;
      if (currentUser == null) {
        throw Exception('Debes iniciar sesion.');
      }

      await locator<RejectLostObjectUseCase>()(
        requesterId: currentUser.id,
        object: lostObject,
      );

      if (!mounted) return;
      setState(() {
        lostObject.rechazado = true;
        lostObject.aprobado = false;
      });
      _renderMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El objeto ha sido rechazado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar el objeto: $e')),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('d MMM y, HH:mm');
    return formatter.format(date);
  }

  Widget _buildLoadingIndicator() {
    if (_hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            _searchQuery.isNotEmpty
                ? 'Ya no hay mas objetos perdidos que coincidan con "$_searchQuery".'
                : 'Ya no hay mas objetos perdidos.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM DRAWER
  // ═══════════════════════════════════════════════════════════

  Widget _buildDetailPanel() {
    final obj = _selectedObject!;
    final isAdmin = _isAdminUser;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHandle(),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _deselectObject,
                ),
                Expanded(
                  child: Text(obj.tipoObjeto,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                _buildEstadoChip(obj),
              ],
            ),
          ),
          // Imagen
          if (obj.imagenUrl.isNotEmpty)
            GestureDetector(
              onTap: () => ImageViewerDialog.showNetwork(
                context: context,
                url: obj.imagenUrl,
                title: obj.tipoObjeto,
                subtitle: obj.lugarEncontrado,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: obj.imagenUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, size: 48),
                  ),
                ),
              ),
            ).paddingAll(16),
          // Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripcion',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(obj.descripcion, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Text('Lugar encontrado',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(obj.lugarEncontrado, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Text('Encontrado por',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(obj.nombreEncontrado,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Text('Custodia actual',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(_custodyDescription(obj),
                    style: const TextStyle(fontSize: 15)),
                if (obj.estaEnPuntoCustodia &&
                    obj.puntoCustodiaLatitud != null &&
                    obj.puntoCustodiaLongitud != null)
                  TextButton.icon(
                    onPressed: () => _focusOnCustodyPoint(obj),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Ver punto en el mapa'),
                  ),
                const SizedBox(height: 12),
                Text('Fecha',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(DateFormat('d MMM y, HH:mm').format(obj.timestamp)),
                const SizedBox(height: 12),
                if (obj.latitud != null && obj.longitud != null) ...[
                  Text('Ubicacion',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text(
                      '${obj.latitud!.toStringAsFixed(6)}, ${obj.longitud!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Centrar en el mapa'),
                    onPressed: () => _focusOnObject(obj),
                  ),
                ],
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  if (obj.rechazado == true)
                    const SizedBox(
                      width: double.infinity,
                      child: Card(
                        color: Colors.orange,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Esta publicacion fue rechazada',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if ((obj.aprobado == false || obj.aprobado == null) &&
                      obj.rechazado != true)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Rechazar publicacion',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: () => _rejectLostObject(obj),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if ((obj.aprobado == false || obj.aprobado == null) &&
                      obj.rechazado != true)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Aprobar publicacion',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: () => _approveLostObject(obj),
                      ),
                    ),
                  if (obj.aprobado == true &&
                      obj.rechazado != true &&
                      !obj.estaEnPuntoCustodia &&
                      obj.estadoReclamacion != 'Entregado') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Registrar recepcion en punto'),
                        onPressed: () => _receiveLostObjectAtPoint(obj),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildAdminClaimSection(obj),
                ],
                // Boton reclamar
                if (!isAdmin &&
                    obj.estadoReclamacion == 'No reclamado' &&
                    _currentUserClaim(obj) == null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.assignment, color: Colors.white),
                      label: const Text('Reclamar este objeto',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LostObjectDetailPage(lostObject: obj),
                          ),
                        ).then(
                            (_) => _setupLostObjectsListener(isRefresh: true));
                      },
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(LostObject obj) {
    final estado = obj.estadoReclamacion ?? 'No reclamado';
    final currentUserClaim = _currentUserClaim(obj);
    final estadoLabel = currentUserClaim != null ? 'Reclamado por ti' : estado;
    Color bg;
    Color fg;
    switch (estado) {
      case 'Pendiente':
        bg = const Color(0xFFFFA726);
        fg = Colors.black;
        break;
      case 'Entregado':
        bg = const Color(0xFF66BB6A);
        fg = Colors.white;
        break;
      default:
        bg = const Color(0xFFEF5350);
        fg = Colors.white;
    }
    final chip = Chip(
      label: Text(estadoLabel,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );

    if (currentUserClaim?.horaReclamacion == null) return chip;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        chip,
        const SizedBox(height: 2),
        Text(
          _formatClaimDateTime(currentUserClaim!.horaReclamacion!),
          style: TextStyle(fontSize: 10, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildApprovalBadge(LostObject obj) {
    if (obj.rechazado == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Rechazado',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (obj.aprobado == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text('Aprobado',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text('Pendiente',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAdminClaimSection(LostObject obj) {
    if (obj.estadoReclamacion == 'Entregado') {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entregado a: ${obj.nombreReclamado ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (obj.reclamaciones.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 8),
              Text('Sin reclamaciones', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${obj.reclamaciones.length} reclamacion(es)',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _primaryColor),
          ),
        ),
        _buildClaimantList(obj),
      ],
    );
  }

  Widget _buildClaimantList(LostObject obj) {
    return Column(
      children: obj.reclamaciones.map((reclamacion) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: reclamacion.fotoReclamante.isNotEmpty
                  ? NetworkImage(reclamacion.fotoReclamante)
                  : const AssetImage('assets/default_avatar.png')
                      as ImageProvider,
            ),
            title: Text(
                '${reclamacion.nombreReclamante} ${reclamacion.apellidoReclamante}'),
            subtitle: Text(reclamacion.textoReclamacion,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: ElevatedButton(
              onPressed: () => _deliverObjectToClaimant(obj, reclamacion),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Entregar'),
            ),
            onTap: () => _showClaimDetailsDialog(reclamacion),
          ),
        );
      }).toList(),
    );
  }

  void _showClaimDetailsDialog(Reclamacion reclamacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la reclamacion'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reclamante: ${reclamacion.nombreReclamante} ${reclamacion.apellidoReclamante}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                  'Fecha: ${reclamacion.horaReclamacion != null ? _formatDateTime(reclamacion.horaReclamacion!) : ''}'),
              const SizedBox(height: 8),
              const Text('Descripcion:'),
              Text(reclamacion.textoReclamacion),
              if (reclamacion.imagenReclamacionUrl != null &&
                  reclamacion.imagenReclamacionUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => ImageViewerDialog.showNetwork(
                    context: context,
                    url: reclamacion.imagenReclamacionUrl!,
                    title: 'Evidencia de reclamacion',
                    subtitle:
                        '${reclamacion.nombreReclamante} ${reclamacion.apellidoReclamante}',
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      reclamacion.imagenReclamacionUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _deliverObjectToClaimant(LostObject obj, Reclamacion reclamacion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar entrega'),
        content: Text('¿Entregar el objeto a ${reclamacion.nombreReclamante}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUser = Provider.of<AuthState>(context, listen: false).user;
      if (currentUser == null) throw Exception('Debes iniciar sesion.');

      await locator<DeliverLostObjectUseCase>()(
        requesterId: currentUser.id,
        object: obj,
        claim: reclamacion,
      );

      if (!mounted) return;
      setState(() {
        obj.estadoReclamacion = 'Entregado';
        obj.uidReclamado = reclamacion.uidReclamante;
        obj.nombreReclamado = reclamacion.nombreReclamante;
        obj.custodiaEstado = 'entregado';
        obj.custodiaUid = reclamacion.uidReclamante;
        obj.custodiaNombre = reclamacion.nombreReclamante;
      });

      _renderMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Objeto entregado a ${reclamacion.nombreReclamante}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al entregar el objeto: $e')),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CALENDARIO ANIMADO
  // ═══════════════════════════════════════════════════════════

  Widget _buildAnimatedCalendar() {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
      child: Material(
        elevation: 2,
        child: Container(
          color: Colors.white,
          child: TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (day) => _focusedDay = day,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTTOM DRAWER
  // ═══════════════════════════════════════════════════════════

  Widget _buildBottomDrawer() {
    final authState = Provider.of<AuthState>(context);
    final Usuario? user = authState.user;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => UserAccountPage())),
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                        (user?.urlimagen != null && user!.urlimagen.isNotEmpty)
                            ? user!.urlimagen
                            : 'https://www.gravatar.com/avatar/15'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.nombre ?? 'Usuario',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.correo ?? '',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Objetos perdidos agregados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LostObjectsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_turned_in),
            title: const Text('Objetos reclamados'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ClaimedObjectsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ajustes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.settingsRoute);
            },
          ),
          _buildVersionFooter(),
        ],
      ),
    );
  }

  Widget _buildVersionFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? 'v${snapshot.data!.version}+${snapshot.data!.buildNumber}'
            : '';

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              version,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        );
      },
    );
  }
}

class _ApprovalDecision {
  final LostObjectPoint? custodyPoint;

  const _ApprovalDecision({this.custodyPoint});
}

extension _Padding on Widget {
  Widget paddingAll(double v) =>
      Padding(padding: EdgeInsets.all(v), child: this);
}
