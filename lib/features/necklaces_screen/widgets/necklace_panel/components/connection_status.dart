import 'package:flutter/material.dart';
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
    return StreamBuilder<bool>(
      stream: BleService().connectionStatusStream,
      initialData: isConnected,
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected ? Colors.blue : Colors.orangeAccent,
              size: 26,
            ),
            if (!connected)
              Text('Disconnected', style: TextStyle(color: Colors.red, fontSize: 12)),
          ],
        );
      },
    );
  }
}