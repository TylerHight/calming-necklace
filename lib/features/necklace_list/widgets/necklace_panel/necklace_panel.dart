import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/ble_connection/ble_connection_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import 'components/timed_toggle_button.dart';
import '../../blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../repositories/necklace_repository.dart';
import '../../../../core/services/logging_service.dart';

class NecklacePanel extends StatefulWidget {
  final int index;
  final String name;
  final bool isConnected;
  final Necklace necklace;
  final NecklaceRepository repository;
  final BleConnectionBloc bleConnectionBloc;

  const NecklacePanel({
    Key? key,
    required this.index,
    required this.name,
    required this.isConnected,
    required this.necklace,
    required this.repository,
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
    final logger = LoggingService();
    logger.logDebug('NecklacePanel: Using provided repository: ${widget.repository}');
    final repository = widget.repository;
    
    return BlocProvider(
      create: (context) => TimedToggleButtonBloc(
        repository: repository,
        necklace: widget.necklace,
      ),
      child: Card(
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
                  _buildTimedToggleButton(Icons.spa, 1, Colors.pink[400]!, Colors.pink[100]!), // Emission 1
                  _buildTimedToggleButton(Icons.spa, 2, Colors.greenAccent[400]!, Colors.greenAccent[100]!), // Emission 2
                ],
              ),
            ],
          ),
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

  Widget _buildTimedToggleButton(IconData icon, int buttonIndex, Color activeColor, Color inactiveColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TimedToggleButton(
          autoTurnOffDuration: const Duration(seconds: 5),
          periodicEmissionTimerDuration: const Duration(seconds: 10),
          isConnected: widget.isConnected,
          necklace: widget.necklace,
          bleConnectionBloc: widget.bleConnectionBloc,
          iconData: icon,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
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
