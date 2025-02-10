import 'package:equatable/equatable.dart';

class BleState extends Equatable {
  final Map<String, bool> deviceConnectionStates;
  final Map<String, String> deviceStates;
  final Map<String, int> deviceRssi;
  final Map<String, int> reconnectionAttempts;
  final String? error;
  final bool isConnecting;
  final String deviceState;
  final int rssi;

  const BleState({
    required this.deviceConnectionStates,
    required this.deviceStates,
    required this.deviceRssi,
    required this.reconnectionAttempts,
    this.error,
    this.isConnecting = false,
    required this.deviceState,
    required this.rssi,
  });

  factory BleState.initial() => const BleState(
    deviceConnectionStates: {},
    deviceStates: {},
    deviceRssi: {},
    reconnectionAttempts: {},
    deviceState: 'initial',
    rssi: 0,
  );

  BleState copyWith({
    Map<String, bool>? deviceConnectionStates,
    Map<String, String>? deviceStates,
    Map<String, int>? deviceRssi,
    Map<String, int>? reconnectionAttempts,
    String? error,
    bool? isConnecting,
    String? deviceState,
    int? rssi,
  }) {
    return BleState(
      deviceConnectionStates: deviceConnectionStates ?? this.deviceConnectionStates,
      deviceStates: deviceStates ?? this.deviceStates,
      deviceRssi: deviceRssi ?? this.deviceRssi,
      reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
      error: error,
      isConnecting: isConnecting ?? this.isConnecting,
      deviceState: deviceState ?? this.deviceState,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  List<Object?> get props => [
    deviceConnectionStates,
    deviceStates,
    deviceRssi,
    reconnectionAttempts,
    error,
    isConnecting,
    deviceState,
    rssi,
  ];
}