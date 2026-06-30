import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/filter_lost_objects_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FilterLostObjectsUseCase', () {
    const useCase = FilterLostObjectsUseCase();

    test('returns only approved objects by default', () {
      final result = useCase(
        objects: [
          _lostObject(id: '1', descripcion: 'Mochila negra', aprobado: true),
          _lostObject(id: '2', descripcion: 'Laptop gris', aprobado: false),
        ],
      );

      expect(result.map((object) => object.id), ['1']);
    });

    test('filters by description, type and place', () {
      final result = useCase(
        query: 'biblioteca',
        objectType: 'credencial',
        objects: [
          _lostObject(
            id: '1',
            descripcion: 'Credencial ITVer',
            tipoObjeto: 'credencial',
            lugarEncontrado: 'Biblioteca',
          ),
          _lostObject(
            id: '2',
            descripcion: 'Credencial gimnasio',
            tipoObjeto: 'credencial',
            lugarEncontrado: 'Cancha',
          ),
          _lostObject(
            id: '3',
            descripcion: 'Mochila biblioteca',
            tipoObjeto: 'mochila',
            lugarEncontrado: 'Biblioteca',
          ),
        ],
      );

      expect(result.map((object) => object.id), ['1']);
    });

    test('can include unapproved objects when explicitly requested', () {
      final result = useCase(
        includeUnapproved: true,
        objects: [
          _lostObject(id: '1', aprobado: true),
          _lostObject(id: '2', aprobado: false),
        ],
      );

      expect(result.map((object) => object.id), ['1', '2']);
    });
  });
}

LostObject _lostObject({
  required String id,
  String descripcion = 'Objeto perdido',
  String tipoObjeto = 'mochila',
  String lugarEncontrado = 'Edificio A',
  bool? aprobado = true,
}) {
  return LostObject(
    id: id,
    descripcion: descripcion,
    tipoObjeto: tipoObjeto,
    tipoOBjetoBusqueda: tipoObjeto,
    lugarEncontrado: lugarEncontrado,
    imagenUrl: '',
    nombreEncontrado: 'Usuario',
    uidEncontrado: 'uid',
    timestamp: DateTime(2026, 1, 1),
    aprobado: aprobado,
    imageUrls: const [],
    reclamaciones: <Reclamacion>[],
    estadoReclamacion: '',
  );
}
