import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../../core/blocs/ble/ble_state.dart';
import '../../../../../core/services/ble/ble_service.dart';

class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String deviceId;

  const ConnectionStatus({
    Key? key,
    required this.isConnected,
    required this.deviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleBloc, BleState>(
      buildWhen: (previous, current) => 
       previous.deviceConnectionStates[deviceId] != current.deviceConnectionStates[deviceId] ||
       previous.deviceRssi[deviceId] != current.deviceRssi[deviceId],
      builder: (context, state) {
        final connected = state.deviceConnectionStates[deviceId] ?? false;
        final rssi = state.deviceRssi[deviceId] ?? 0;
        final reconnecting = state.reconnectionAttempts[deviceId] ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected ? Colors.blue : Colors.orangeAccent,
              size: 26,
            ),
            if (connected && rssi < -80)
              Icon(
                Icons.signal_cellular_alt,
                color: Colors.orange,
                size: 18,
              ),
            if (reconnecting > 0)
              Text(
                'Reconnecting...',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            if (!connected)
              Text('Disconnected', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        );
      },
    );
  }
}
