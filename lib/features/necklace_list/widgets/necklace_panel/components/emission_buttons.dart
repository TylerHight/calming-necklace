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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: TimedToggleButton(
            autoTurnOffDuration: necklace.emission1Duration,
            periodicEmissionTimerDuration: necklace.releaseInterval1,
            isConnected: isConnected,
            necklace: necklace,
            bleConnectionBloc: bleConnectionBloc,
            iconData: Icons.air,
            activeColor: Colors.blue[600]!,
            inactiveColor: Colors.blue[100]!,
            iconColor: Colors.white,
            buttonSize: 52.0,
            iconSize: 28.0,
            onToggle: () {
              // Implement the toggle logic here
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          height: 52,
          child: TimedToggleButton(
            autoTurnOffDuration: necklace.emission2Duration,
            periodicEmissionTimerDuration: necklace.releaseInterval2,
            isConnected: isConnected,
            necklace: necklace,
            bleConnectionBloc: bleConnectionBloc,
            iconData: Icons.air,
            activeColor: Colors.green[600]!,
            inactiveColor: Colors.green[100]!,
            iconColor: Colors.white,
            buttonSize: 52.0,
            iconSize: 28.0,
            onToggle: () {
              // Implement the toggle logic here
            },
          ),
        ),
      ],
    );
  }
}
