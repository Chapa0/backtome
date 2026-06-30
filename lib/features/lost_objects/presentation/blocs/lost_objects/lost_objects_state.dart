import 'package:equatable/equatable.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';

enum LostObjectsStatus {
  initial,
  loading,
  success,
  failure,
}

class LostObjectsState extends Equatable {
  final LostObjectsStatus status;
  final List<LostObject> allObjects;
  final List<LostObject> visibleObjects;
  final String query;
  final String objectType;
  final String? errorMessage;

  const LostObjectsState({
    this.status = LostObjectsStatus.initial,
    this.allObjects = const [],
    this.visibleObjects = const [],
    this.query = '',
    this.objectType = '',
    this.errorMessage,
  });

  LostObjectsState copyWith({
    LostObjectsStatus? status,
    List<LostObject>? allObjects,
    List<LostObject>? visibleObjects,
    String? query,
    String? objectType,
    String? errorMessage,
  }) {
    return LostObjectsState(
      status: status ?? this.status,
      allObjects: allObjects ?? this.allObjects,
      visibleObjects: visibleObjects ?? this.visibleObjects,
      query: query ?? this.query,
      objectType: objectType ?? this.objectType,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allObjects,
        visibleObjects,
        query,
        objectType,
        errorMessage,
      ];
}
