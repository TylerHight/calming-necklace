import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/data/repositories/necklace_repository.dart';
import 'add_device_dialog_state.dart';

part 'add_device_dialog_event.dart';

class AddDeviceDialogBloc extends Bloc<AddDeviceDialogEvent, AddDeviceDialogState> {
  final NecklaceRepository _repository;

  AddDeviceDialogBloc(this._repository) : super(AddDeviceDialogInitial()) {
    on<SubmitAddDeviceEvent>(_onSubmitAddDevice);
  }

  Future<void> _onSubmitAddDevice(SubmitAddDeviceEvent event, Emitter<AddDeviceDialogState> emit) async {
    emit(AddDeviceDialogLoading());
    try {
      await _repository.addNecklace(event.name, event.bleDevice);
      emit(AddDeviceDialogSuccess());
    } catch (e) {
      emit(AddDeviceDialogError(e.toString()));
    }
  }
}