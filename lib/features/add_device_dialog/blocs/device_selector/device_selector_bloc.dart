import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/data/models/ble_device.dart';
import 'device_selector_state.dart';

part 'device_selector_event.dart';

class DeviceSelectorBloc extends Bloc<DeviceSelectorEvent, DeviceSelectorState> {
  DeviceSelectorBloc() : super(DeviceSelectorInitial());

  @override
  Stream<DeviceSelectorState> mapEventToState(DeviceSelectorEvent event) async* {
    if (event is DeviceSelectorSelectDeviceEvent) {
      yield DeviceSelected(event.device);
    }
  }
}
