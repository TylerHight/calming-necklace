import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/ble/ble_service.dart';
import 'ble_event.dart'; // Import BleEvent
import 'ble_state.dart'; // Import BleState

class BleBloc extends Bloc<BleEvent, BleState> {
  final BleService _bleService; // Corrected declaration
  StreamSubscription<String>? _deviceStateSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;
  StreamSubscription<int>? _rssiSubscription;
  StreamSubscription<int>? _reconnectionAttemptsSubscription;

  BleBloc({required BleService bleService})
      : _bleService = bleService,
        super(BleState.initial()) { // Ensure initial state is provided
    _deviceStateSubscription = _bleService.deviceStateStream.listen(_onDeviceStateChanged);
    _connectionStatusSubscription = _bleService.connectionStatusStream.listen(_onConnectionStatusChanged);
    _reconnectionAttemptsSubscription = _bleService.reconnectionAttemptsStream.listen(_onReconnectionAttempt);
    _rssiSubscription = _bleService.rssiStream.listen(_onRssiUpdate);
  }

  void _onDeviceStateChanged(String state) {
    emit(this.state.copyWith(
      deviceState: state,
    ));
  }

  void _onConnectionStatusChanged(bool isConnected) {
    if (_bleService.connectedDevice != null) {
      final deviceId = _bleService.connectedDevice!.id.toString();
      final updatedStates = Map<String, bool>.from(state.deviceConnectionStates);
      updatedStates[deviceId] = isConnected;
      emit(state.copyWith(deviceConnectionStates: updatedStates));
    }
  }

  void _onReconnectionAttempt(int attempts) {
    // Handle reconnection attempts
  }

  void _onRssiUpdate(int rssi) {
    emit(state.copyWith(rssi: rssi));
  }

  @override
  Future<void> close() {
    _deviceStateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _reconnectionAttemptsSubscription?.cancel();
    _rssiSubscription?.cancel();
    return super.close();
  }
}
