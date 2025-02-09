import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../../../../core/services/ble/ble_service.dart';
import '../../../../core/blocs/necklaces/necklaces_bloc.dart';
import 'add_device_dialog_state.dart';

part 'add_device_dialog_event.dart';

class AddDeviceDialogBloc extends Bloc<AddDeviceDialogEvent, AddDeviceDialogState> {
  final NecklaceRepository _repository;
  final BleService _bleService;
  final NecklacesBloc _necklacesBloc;

  AddDeviceDialogBloc(this._repository, this._necklacesBloc, this._bleService) 
      : super(AddDeviceDialogInitial()) {
    on<SubmitAddDeviceEvent>(_onSubmitAddDevice);
  }

  Future<void> _onSubmitAddDevice(SubmitAddDeviceEvent event, Emitter<AddDeviceDialogState> emit) async {
    emit(AddDeviceDialogLoading());
    try {
      // Attempt to connect to the device first
      if (event.device?.device != null) {
        await _bleService.connectToDevice(event.device!.device);
      }
      
      await _repository.addNecklace(event.name, event.device?.id ?? '');
      _necklacesBloc.add(FetchNecklacesEvent());
      emit(AddDeviceDialogSuccess());
    } catch (e) {
      emit(AddDeviceDialogError(e.toString()));
      return;
    }
  }
}
