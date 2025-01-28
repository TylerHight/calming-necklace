import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/data/models/ble_device.dart';
import '../../core/data/repositories/necklace_repository.dart';
import '../necklaces_screen/blocs/necklaces_bloc.dart';
import 'add_device_dialog_state.dart';

part 'add_device_dialog_event.dart';

class AddDeviceDialogBloc extends Bloc<AddDeviceDialogEvent, AddDeviceDialogState> {
  final NecklaceRepository _repository;
  final NecklacesBloc _necklacesBloc;

  AddDeviceDialogBloc(this._repository, this._necklacesBloc) 
      : super(AddDeviceDialogInitial()) {
    on<SubmitAddDeviceEvent>(_onSubmitAddDevice);
  }

  Future<void> _onSubmitAddDevice(SubmitAddDeviceEvent event, Emitter<AddDeviceDialogState> emit) async {
    emit(AddDeviceDialogLoading());
    try {
      await _repository.addNecklace(event.name, event.device);
      _necklacesBloc.add(FetchNecklacesEvent());
      emit(AddDeviceDialogSuccess());
    } catch (e) {
      emit(AddDeviceDialogError(e.toString()));
    }
  }
}