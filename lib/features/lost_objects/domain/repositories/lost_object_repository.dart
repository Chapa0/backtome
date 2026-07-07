import 'package:flutter_backtome/features/claims/domain/entities/reclamacion.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object_point.dart';

abstract class LostObjectRepository {
  Stream<List<LostObject>> watchLostObjects();

  Stream<List<LostObject>> watchApprovedLostObjects();

  Future<List<LostObject>> fetchLostObjects();

  Future<List<LostObject>> fetchLostObjectsByOwner(String userId);

  Future<List<LostObject>> fetchClaimedLostObjects(String userId);

  Future<List<LostObject>> fetchVisibleLostObjects({
    required bool isAdmin,
    String? userId,
    String searchQuery = '',
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<void> createLostObject({
    required String requesterId,
    required String description,
    required String objectType,
    required String foundPlace,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
  });

  Future<void> claimLostObject({
    required String requesterId,
    required String objectId,
    required Reclamacion claim,
  });

  Future<void> approveLostObject({
    required String requesterId,
    required String objectId,
    LostObjectPoint? custodyPoint,
  });

  Future<void> rejectLostObject({
    required String requesterId,
    required String objectId,
  });

  Future<void> deliverLostObject({
    required String requesterId,
    required String objectId,
    required String claimantId,
  });

  Future<void> receiveLostObjectAtPoint({
    required String requesterId,
    required String objectId,
    required LostObjectPoint custodyPoint,
  });

  Future<void> deleteLostObject({
    required String requesterId,
    required String objectId,
    required List<String> imageUrls,
  });
}
