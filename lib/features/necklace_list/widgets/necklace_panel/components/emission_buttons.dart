import 'package:flutter/material.dart';
import 'package:calming_necklace/core/data/models/necklace.dart';
import 'timed_toggle_button.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';

class EmissionControls extends StatelessWidget {
  final Necklace necklace;
  final bool isConnected;
  final Function(int) onCommand;
  final BleConnectionBloc bleConnectionBloc;

  const EmissionControls({
    super.key,
    required this.necklace,
    required this.isConnected,
    required this.onCommand,
    required this.bleConnectionBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmissionButton(
            duration: necklace.emission1Duration,
            interval: necklace.releaseInterval1,
            color: Colors.pink[400]!,
            inactiveColor: Colors.pink[100]!,
            isLeftButton: true,
          ),
          _buildEmissionButton(
            duration: necklace.emission2Duration,
            interval: necklace.releaseInterval2,
            color: Colors.green[400]!,
            inactiveColor: Colors.green[100]!,
            isLeftButton: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEmissionButton({
    required Duration duration,
    required Duration interval,
    required Color color,
    required Color inactiveColor,
    required bool isLeftButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(30), // Changed to 30 for circular shape
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TimedToggleButton(
        autoTurnOffDuration: duration,
        periodicEmissionTimerDuration: interval,
        isConnected: isConnected,
        necklace: necklace,
        bleConnectionBloc: bleConnectionBloc,
        iconData: Icons.air,
        activeColor: color,
        inactiveColor: inactiveColor,
        iconColor: Colors.white,
        buttonSize: 60.0, // Set a fixed size for circular buttons
        iconSize: 24.0,
        label: '',
        onToggle: () {
          onCommand(isLeftButton ? 1 : 2);
        },
      ),
    );
  }
}
