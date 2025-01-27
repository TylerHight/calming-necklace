import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/data/models/necklace.dart';

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

  NecklacesBloc(this._repository) : super(NecklacesInitial()) {
    on<FetchNecklacesEvent>(_onFetchNecklaces);
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
} 