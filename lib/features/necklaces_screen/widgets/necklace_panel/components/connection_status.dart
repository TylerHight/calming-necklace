import 'package:flutter/material.dart';
import '../../../../../core/ui/ui_constants.dart';

/// Displays the connection status and signal strength for a necklace device
class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final int? rssi;

  const ConnectionStatus({
    Key? key,
    required this.isConnected,
    this.rssi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.connectionStatusPaddingH,
        vertical: UIConstants.connectionStatusPaddingV,
      ),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.connectionStatusBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: UIConstants.connectionStatusDotSize,
            height: UIConstants.connectionStatusDotSize,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: UIConstants.connectionStatusDotSpacing),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: UIConstants.connectionStatusTextSize,
              fontWeight: UIConstants.connectionStatusFontWeight,
              color: isConnected ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}