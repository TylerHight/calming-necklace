import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/necklace_repository.dart';
import '../../data/models/necklace.dart';
import '../../services/database_service.dart';
import 'dart:async';

// Events
abstract class NecklacesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class FetchNecklacesEvent extends NecklacesEvent {}

// States
abstract class NecklacesState extends Equatable {
  @override
  List<Object> get props => [];
}

class NecklacesInitial extends NecklacesState {}

class NecklacesLoading extends NecklacesState {}

class NecklacesLoaded extends NecklacesState {
  final List<Necklace> necklaces;

  NecklacesLoaded(this.necklaces);

  @override
  List<Object> get props => [necklaces];
}

class NecklacesError extends NecklacesState {
  final String message;

  NecklacesError(this.message);

  @override
  List<Object> get props => [message];
}

class NecklacesBloc extends Bloc<NecklacesEvent, NecklacesState> {
  final NecklaceRepository _repository;
  final DatabaseService _databaseService;
  late final StreamSubscription<void> _databaseSubscription;

  NecklacesBloc(this._repository, this._databaseService) : super(NecklacesInitial()) {
    on<FetchNecklacesEvent>(_onFetchNecklaces);
    _databaseSubscription = _databaseService.onNecklaceUpdate.listen((_) {
      add(FetchNecklacesEvent());
    });
  }

  Future<void> _onFetchNecklaces(FetchNecklacesEvent event, Emitter<NecklacesState> emit) async {
    emit(NecklacesLoading());
    try {
      final necklaces = await _repository.getNecklaces();
      emit(NecklacesLoaded(necklaces));
    } catch (e) {
      emit(NecklacesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _databaseSubscription.cancel();
    return super.close();
  }
}
