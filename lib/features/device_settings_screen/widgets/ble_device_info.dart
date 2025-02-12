import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';

class BleDeviceInfo extends StatelessWidget {
  final BleDevice device;

  const BleDeviceInfo({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      device.device?.platformName ?? device.name,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
