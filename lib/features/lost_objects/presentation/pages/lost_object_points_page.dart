import 'package:flutter/material.dart';
import 'package:flutter_backtome/shared/widgets/action_loading_overlay.dart';
import 'package:flutter_backtome/shared/widgets/location/delivery_point_marker_image.dart';
import 'package:flutter_backtome/core/di/service_locator.dart';
import 'package:flutter_backtome/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_object_points_firestore_datasource.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';
import 'package:flutter_backtome/shared/widgets/location/mapbox_location_picker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:provider/provider.dart';

class LostObjectPointsPage extends StatelessWidget {
  final bool managementMode;

  const LostObjectPointsPage({
    super.key,
    this.managementMode = true,
  });

  static const _primaryColor = Color(0xFF1B396A);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final isAdmin = user?.tipoUsuario == 'admin';
    final canManage = managementMode && isAdmin;
    final dataSource = locator<LostObjectPointsFirestoreDataSource>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de entrega y reclamacion'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showPointForm(context),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Agregar'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: StreamBuilder<List<LostObjectPoint>>(
        stream:
            isAdmin ? dataSource.watchPoints() : dataSource.watchActivePoints(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child:
                    Text('No se pudieron cargar los puntos: ${snapshot.error}'),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final visiblePoints = snapshot.data!;

          if (visiblePoints.isEmpty) {
            return _EmptyPoints(canManage: canManage);
          }

          return Column(
            children: [
              SizedBox(
                height: 300,
                child: _PointsMap(points: visiblePoints),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: visiblePoints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final point = visiblePoints[index];
                    return _PointTile(
                      point: point,
                      canManage: canManage,
                      onEdit: () => _showPointForm(context, point: point),
                      onDeactivate: () => _deactivatePoint(context, point),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showPointForm(
    BuildContext context, {
    LostObjectPoint? point,
  }) async {
    final result = await showModalBottomSheet<LostObjectPoint>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PointFormSheet(point: point),
    );

    if (result == null || !context.mounted) return;

    final user = context.read<AuthState>().user;
    if (user == null) return;

    try {
      await ActionLoadingOverlay.run<void>(
        context,
        message: 'Guardando punto de entrega...',
        action: () => locator<LostObjectPointsFirestoreDataSource>().savePoint(
          requesterId: user.id,
          point: result,
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto guardado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el punto: $e')),
      );
    }
  }

  static Future<void> _deactivatePoint(
    BuildContext context,
    LostObjectPoint point,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar punto'),
        content: Text('¿Deseas desactivar "${point.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final user = context.read<AuthState>().user;
    if (user == null) return;

    try {
      await ActionLoadingOverlay.run<void>(
        context,
        message: 'Desactivando punto de entrega...',
        action: () =>
            locator<LostObjectPointsFirestoreDataSource>().deactivatePoint(
          requesterId: user.id,
          pointId: point.id,
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto desactivado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo desactivar el punto: $e')),
      );
    }
  }
}

class _PointsMap extends StatefulWidget {
  final List<LostObjectPoint> points;

  const _PointsMap({required this.points});

  @override
  State<_PointsMap> createState() => _PointsMapState();
}

class _PointsMapState extends State<_PointsMap> {
  mb.MapboxMap? _mapboxMap;
  mb.PointAnnotationManager? _pointManager;
  final List<mb.PointAnnotation> _annotations = [];

  late final mb.CameraViewportState _initialViewport = mb.CameraViewportState(
    center: mb.Point(
      coordinates: mb.Position(
        widget.points.first.longitud,
        widget.points.first.latitud,
      ),
    ),
    zoom: 14,
  );

  @override
  void didUpdateWidget(covariant _PointsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _renderPoints();
    }
  }

  void _onMapCreated(mb.MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    _pointManager =
        await _mapboxMap!.annotations.createPointAnnotationManager();
    await _renderPoints();
  }

  Future<void> _renderPoints() async {
    final manager = _pointManager;
    if (manager == null) return;

    for (final annotation in _annotations) {
      try {
        await manager.delete(annotation);
      } catch (_) {}
    }
    _annotations.clear();

    for (final point in widget.points) {
      final marker = await DeliveryPointMarkerImage.build(active: point.activo);
      final annotation = await manager.create(
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(point.longitud, point.latitud),
          ),
          image: marker,
          iconAnchor: mb.IconAnchor.BOTTOM,
          iconSize: point.activo ? 0.62 : 0.52,
          symbolSortKey: point.activo ? 2 : 1,
        ),
      );
      _annotations.add(annotation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: mb.MapWidget(
            key: const ValueKey('lostObjectPointsMap'),
            viewport: _initialViewport,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF006D77),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Punto de entrega y recoleccion de objetos perdidos.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointTile extends StatelessWidget {
  final LostObjectPoint point;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _PointTile({
    required this.point,
    required this.canManage,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          point.permiteEntrega
              ? Icons.inventory_2_outlined
              : Icons.assignment_return_outlined,
          color: point.activo ? const Color(0xFF1B396A) : Colors.grey,
        ),
        title: Text(point.nombre),
        subtitle: Text(
          [
            point.tipoLabel,
            if (point.descripcion.trim().isNotEmpty) point.descripcion,
            '${point.latitud.toStringAsFixed(5)}, ${point.longitud.toStringAsFixed(5)}',
            if (!point.activo) 'Inactivo',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: canManage
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'deactivate') onDeactivate();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  if (point.activo)
                    const PopupMenuItem(
                      value: 'deactivate',
                      child: Text('Desactivar'),
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

class _PointFormSheet extends StatefulWidget {
  final LostObjectPoint? point;

  const _PointFormSheet({this.point});

  @override
  State<_PointFormSheet> createState() => _PointFormSheetState();
}

class _PointFormSheetState extends State<_PointFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _type;
  late bool _active;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final point = widget.point;
    _nameController = TextEditingController(text: point?.nombre ?? '');
    _descriptionController =
        TextEditingController(text: point?.descripcion ?? '');
    _type = point?.tipo ?? 'ambos';
    _active = point?.activo ?? true;
    _lat = point?.latitud;
    _lng = point?.longitud;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapboxLocationPicker(
          initialLatitude: _lat,
          initialLongitude: _lng,
        ),
      ),
    );

    if (result is Map<String, dynamic>) {
      setState(() {
        _lat = result['latitud'] as double;
        _lng = result['longitud'] as double;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la ubicacion del punto.')),
      );
      return;
    }

    Navigator.of(context).pop(
      LostObjectPoint(
        id: widget.point?.id ?? '',
        nombre: _nameController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        tipo: _type,
        latitud: _lat!,
        longitud: _lng!,
        activo: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.point == null ? 'Agregar punto' : 'Editar punto',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del punto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Uso del punto',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'entrega',
                      child: Text('Entrega de objetos'),
                    ),
                    DropdownMenuItem(
                      value: 'reclamacion',
                      child: Text('Reclamacion de objetos'),
                    ),
                    DropdownMenuItem(
                      value: 'ambos',
                      child: Text('Entrega y reclamacion'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Punto activo'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    _lat == null
                        ? 'Seleccionar ubicacion en mapa'
                        : 'Ubicacion: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar punto'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPoints extends StatelessWidget {
  final bool canManage;

  const _EmptyPoints({required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Aun no hay puntos configurados.',
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => LostObjectPointsPage._showPointForm(context),
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Agregar punto'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
