import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/models/ble_device.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import 'add_device_dialog_event.dart';
import '../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../core/blocs/ble/ble_event.dart';
import '../../../../core/blocs/necklaces/necklaces_bloc.dart';
import 'add_device_dialog_state.dart';

class AddDeviceDialogBloc extends Bloc<AddDeviceDialogEvent, AddDeviceDialogState> {
  final NecklaceRepository _repository;
  final BleBloc _bleBloc;
  final NecklacesBloc _necklacesBloc;

  AddDeviceDialogBloc(this._repository, this._necklacesBloc, this._bleBloc) 
      : super(AddDeviceDialogInitial()) {
    on<SubmitAddDeviceEvent>(_onSubmitAddDevice);
    on<SelectDeviceEvent>(_onSelectDevice);
  }

  Future<void> _onSelectDevice(SelectDeviceEvent event, Emitter<AddDeviceDialogState> emit) async {
    try {
      emit(ConnectionInProgress(event.device.name));
      _bleBloc.add(BleConnectRequest(event.device));
      emit(DeviceSelected(event.device));
    } catch (e) {
      emit(AddDeviceDialogError(e.toString()));
    }
  }

  Future<void> _onSubmitAddDevice(SubmitAddDeviceEvent event, Emitter<AddDeviceDialogState> emit) async {
    emit(AddDeviceDialogLoading());
    try {
      final device = event.device;      
      if (device == null || device.device == null) {
        throw Exception('No device selected');
      }

      await _repository.addNecklace(event.name, device.device!.id.toString());
      _necklacesBloc.add(FetchNecklacesEvent());
      emit(AddDeviceDialogSuccess());
    } catch (e) {
      emit(AddDeviceDialogError(e.toString()));
      return;
    }
  }
}
