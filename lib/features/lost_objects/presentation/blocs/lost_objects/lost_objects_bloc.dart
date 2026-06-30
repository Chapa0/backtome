import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_backtome/features/lost_objects/domain/entities/lost_object.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/filter_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/domain/usecases/watch_lost_objects_usecase.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/blocs/lost_objects/lost_objects_event.dart';
import 'package:flutter_backtome/features/lost_objects/presentation/blocs/lost_objects/lost_objects_state.dart';

class LostObjectsBloc extends Bloc<LostObjectsEvent, LostObjectsState> {
  final WatchLostObjectsUseCase _watchLostObjects;
  final FilterLostObjectsUseCase _filterLostObjects;
  StreamSubscription<List<LostObject>>? _subscription;

  LostObjectsBloc({
    required WatchLostObjectsUseCase watchLostObjects,
    required FilterLostObjectsUseCase filterLostObjects,
  })  : _watchLostObjects = watchLostObjects,
        _filterLostObjects = filterLostObjects,
        super(const LostObjectsState()) {
    on<LostObjectsStarted>(_onStarted);
    on<LostObjectsReceived>(_onReceived);
    on<LostObjectsFailed>(_onFailed);
    on<LostObjectsFilterChanged>(_onFilterChanged);
  }

  Future<void> _onStarted(
    LostObjectsStarted event,
    Emitter<LostObjectsState> emit,
  ) async {
    emit(state.copyWith(status: LostObjectsStatus.loading));
    await _subscription?.cancel();
    _subscription = _watchLostObjects(onlyApproved: event.onlyApproved).listen(
      (objects) => add(LostObjectsReceived(objects)),
      onError: (Object error) => add(LostObjectsFailed(error.toString())),
    );
  }

  void _onReceived(
    LostObjectsReceived event,
    Emitter<LostObjectsState> emit,
  ) {
    emit(
      state.copyWith(
        status: LostObjectsStatus.success,
        allObjects: event.objects,
        visibleObjects: _filter(event.objects),
      ),
    );
  }

  void _onFailed(
    LostObjectsFailed event,
    Emitter<LostObjectsState> emit,
  ) {
    emit(
      state.copyWith(
        status: LostObjectsStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  void _onFilterChanged(
    LostObjectsFilterChanged event,
    Emitter<LostObjectsState> emit,
  ) {
    emit(
      state.copyWith(
        query: event.query,
        objectType: event.objectType,
        visibleObjects: _filter(
          state.allObjects,
          query: event.query,
          objectType: event.objectType,
        ),
      ),
    );
  }

  List<LostObject> _filter(
    List<LostObject> objects, {
    String? query,
    String? objectType,
  }) {
    return _filterLostObjects(
      objects: objects,
      query: query ?? state.query,
      objectType: objectType ?? state.objectType,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
