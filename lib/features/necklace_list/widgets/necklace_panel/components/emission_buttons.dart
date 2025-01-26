// lib/features/necklace_list/widgets/necklace_panel/components/emission_buttons.dart

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
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEmissionButton(
              duration: necklace.emission1Duration,
              interval: necklace.releaseInterval1,
              color: Colors.pink[400]!,
              inactiveColor: Colors.pink[100]!,
              label: 'Emission 1',
              isLeftButton: true,
            ),
          ),
          Container(
            width: 1,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildEmissionButton(
              duration: necklace.emission2Duration,
              interval: necklace.releaseInterval2,
              color: Colors.green[400]!,
              inactiveColor: Colors.green[100]!,
              label: 'Emission 2',
              isLeftButton: false,
            ),
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
    required String label,
    required bool isLeftButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: isLeftButton ? Radius.circular(16) : Radius.zero,
          right: !isLeftButton ? Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TimedToggleButton(
            autoTurnOffDuration: duration,
            periodicEmissionTimerDuration: interval,
            isConnected: isConnected,
            necklace: necklace,
            bleConnectionBloc: bleConnectionBloc,
            iconData: Icons.air,
            activeColor: color,
            inactiveColor: inactiveColor,
            iconColor: Colors.white,
            buttonSize: 48.0,
            iconSize: 24.0,
            onToggle: () {
              onCommand(isLeftButton ? 1 : 2);
            },
          ),
        ],
      ),
    );
  }
}
