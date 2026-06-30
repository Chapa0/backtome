import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';

class FilterLostObjectsUseCase {
  const FilterLostObjectsUseCase();

  List<LostObject> call({
    required List<LostObject> objects,
    String query = '',
    String objectType = '',
    bool includeUnapproved = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedType = objectType.trim().toLowerCase();

    return objects.where((object) {
      final matchesApproval = includeUnapproved || object.aprobado == true;
      final notRejected = object.rechazado != true;
      final matchesType = normalizedType.isEmpty ||
          object.tipoObjeto.toLowerCase() == normalizedType ||
          object.tipoOBjetoBusqueda.toLowerCase() == normalizedType;
      final searchableText = [
        object.descripcion,
        object.tipoObjeto,
        object.tipoOBjetoBusqueda,
        object.lugarEncontrado,
        object.nombreEncontrado,
      ].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);

      return matchesApproval && notRejected && matchesType && matchesQuery;
    }).toList();
  }
}
