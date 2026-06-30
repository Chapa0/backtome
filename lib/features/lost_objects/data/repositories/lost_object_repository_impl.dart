import 'package:flutter_backtome/features/lost_objects/data/datasources/lost_objects_firestore_datasource.dart';
import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/repositories/lost_object_repository.dart';

class LostObjectRepositoryImpl implements LostObjectRepository {
  final LostObjectsFirestoreDataSource _dataSource;

  LostObjectRepositoryImpl({
    required LostObjectsFirestoreDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Stream<List<LostObject>> watchLostObjects() => _dataSource.watchLostObjects();

  @override
  Stream<List<LostObject>> watchApprovedLostObjects() {
    return _dataSource.watchApprovedLostObjects();
  }

  @override
  Future<List<LostObject>> fetchLostObjects() => _dataSource.fetchLostObjects();

  @override
  Future<List<LostObject>> fetchLostObjectsByOwner(String userId) {
    return _dataSource.fetchLostObjectsByOwner(userId);
  }

  @override
  Future<List<LostObject>> fetchClaimedLostObjects(String userId) {
    return _dataSource.fetchClaimedLostObjects(userId);
  }

  @override
  Future<List<LostObject>> fetchVisibleLostObjects({
    required bool isAdmin,
    String? userId,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _dataSource.fetchVisibleLostObjects(
      isAdmin: isAdmin,
      userId: userId,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> deleteLostObject({
    required String requesterId,
    required String objectId,
    required List<String> imageUrls,
  }) {
    return _dataSource.deleteLostObject(
      requesterId: requesterId,
      objectId: objectId,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<void> createLostObject({
    required String requesterId,
    required String description,
    required String objectType,
    required String foundPlace,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
  }) {
    return _dataSource.createLostObject(
      requesterId: requesterId,
      description: description,
      objectType: objectType,
      foundPlace: foundPlace,
      imageUrls: imageUrls,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> claimLostObject({
    required String requesterId,
    required String objectId,
    required Reclamacion claim,
  }) {
    return _dataSource.claimLostObject(
      requesterId: requesterId,
      objectId: objectId,
      claim: claim,
    );
  }

  @override
  Future<void> approveLostObject({
    required String requesterId,
    required String objectId,
  }) {
    return _dataSource.approveLostObject(
      requesterId: requesterId,
      objectId: objectId,
    );
  }

  @override
  Future<void> rejectLostObject({
    required String requesterId,
    required String objectId,
  }) {
    return _dataSource.rejectLostObject(
      requesterId: requesterId,
      objectId: objectId,
    );
  }

  @override
  Future<void> deliverLostObject({
    required String requesterId,
    required String objectId,
    required String claimantId,
  }) {
    return _dataSource.deliverLostObject(
      requesterId: requesterId,
      objectId: objectId,
      claimantId: claimantId,
    );
  }
}
