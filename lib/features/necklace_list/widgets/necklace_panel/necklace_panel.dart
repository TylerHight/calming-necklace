import 'package:flutter/material.dart';

import '../../../../core/blocs/ble_connection/ble_connection_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import 'components/timed_toggle_button.dart';

class NecklacePanel extends StatefulWidget {
  final int index;
  final String name;
  final bool isConnected;
  final Necklace necklace;
  final BleConnectionBloc bleConnectionBloc;

  const NecklacePanel({
    Key? key,
    required this.index,
    required this.name,
    required this.isConnected,
    required this.necklace,
    required this.bleConnectionBloc,
  }) : super(key: key);

  @override
  _NecklacePanelState createState() => _NecklacePanelState();
}

class _NecklacePanelState extends State<NecklacePanel> {
  bool isRelease1Active = false;
  bool isRelease2Active = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
                _buildConnectionStatus(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.settings, 'Settings', () {
                  // Navigate to settings
                }),
                _buildActionButton(Icons.note_add, 'Add Note', () {
                  // Add a note
                }),
                _buildTimedToggleButton(Icons.spa, 1), // Release 1
                _buildTimedToggleButton(Icons.spa, 2), // Release 2
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.isConnected ? 'Connected' : 'Disconnected',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimedToggleButton(IconData icon, int buttonIndex) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TimedToggleButton(
          autoTurnOffDuration: const Duration(seconds: 5), // Example duration
          periodicEmissionTimerDuration: const Duration(seconds: 10), // Example duration
          isConnected: widget.isConnected,
          necklace: widget.necklace,
          bleConnectionBloc: widget.bleConnectionBloc,
          iconData: icon,
          onToggle: () {
            setState(() {
              if (buttonIndex == 1) {
                isRelease1Active = !isRelease1Active;
              } else if (buttonIndex == 2) {
                isRelease2Active = !isRelease2Active;
              }
            });
          },
        ),
      ),
    );
  }
}
