import 'package:equatable/equatable.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';

abstract class LostObjectsEvent extends Equatable {
  const LostObjectsEvent();

  @override
  List<Object?> get props => [];
}

class LostObjectsStarted extends LostObjectsEvent {
  final bool onlyApproved;

  const LostObjectsStarted({
    this.onlyApproved = true,
  });

  @override
  List<Object?> get props => [onlyApproved];
}

class LostObjectsFilterChanged extends LostObjectsEvent {
  final String query;
  final String objectType;

  const LostObjectsFilterChanged({
    this.query = '',
    this.objectType = '',
  });

  @override
  List<Object?> get props => [query, objectType];
}

class LostObjectsReceived extends LostObjectsEvent {
  final List<LostObject> objects;

  const LostObjectsReceived(this.objects);

  @override
  List<Object?> get props => [objects];
}

class LostObjectsFailed extends LostObjectsEvent {
  final String message;

  const LostObjectsFailed(this.message);

  @override
  List<Object?> get props => [message];
}
