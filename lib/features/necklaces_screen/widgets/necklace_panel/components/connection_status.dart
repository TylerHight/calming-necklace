import 'package:flutter/material.dart';
import '../../../../../core/ui/ui_constants.dart';
import '../../../../../core/ui/components/signal_strength_icon.dart';

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
        color: isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.connectionStatusBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rssi != null) SignalStrengthIcon(rssi: rssi!),
          if (rssi != null) const SizedBox(width: 4),
          Container(
            width: UIConstants.connectionStatusDotSize,
            height: UIConstants.connectionStatusDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
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
          if (rssi != null) Tooltip(
            message: 'Signal Strength: ${rssi}dBm',
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: isConnected ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
