import 'package:flutter/material.dart';

class SignalStrengthIcon extends StatelessWidget {
  final int rssi;
  final double size;
  final Color? color;

  const SignalStrengthIcon({
    Key? key,
    required this.rssi,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getSignalIcon(),
      size: size,
      color: color ?? _getSignalColor(context),
    );
  }

  IconData _getSignalIcon() {
    if (rssi >= -60) {
      return Icons.signal_wifi_4_bar;
    } else if (rssi >= -75) {
      return Icons.network_wifi_3_bar;
    } else if (rssi >= -90) {
      return Icons.network_wifi_2_bar;
    } else {
      return Icons.network_wifi_1_bar;
    }
  }

  Color _getSignalColor(BuildContext context) {
    if (rssi >= -60) {
      return Colors.green;
    } else if (rssi >= -75) {
      return Colors.orange;
    } else if (rssi >= -90) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
