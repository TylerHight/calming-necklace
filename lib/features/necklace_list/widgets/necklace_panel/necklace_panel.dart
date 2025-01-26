import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/ble_connection/ble_connection_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import 'components/timed_toggle_button.dart';
import 'components/connection_status.dart';
import '../../blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../repositories/necklace_repository.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/ui/ui_constants.dart';

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

  void _showOptions(BuildContext context, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(tapPosition, tapPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_note',
          child: Row(
            children: [
              Icon(Icons.note_add),
              SizedBox(width: 8),
              Text('Add Note'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        // Navigate to settings
      } else if (value == 'add_note') {
        // Add a note
      }
    });
  }

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
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade200], // Lighter gradient for a softer look
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0), // Reduced padding for a tighter layout
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16), // Reduced space for a more compact design
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              _buildConnectionStatus(),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: UIConstants.popoutMenuIconSize),
            onSelected: (value) {
              if (value == 'settings') {
                // Navigate to settings
              } else if (value == 'add_note') {
                // Add a note
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'add_note',
                child: Row(
                  children: [
                    Icon(Icons.note_add, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text('Add Note'),
                  ],
                ),
              ),
            ],
            iconSize: UIConstants.popoutMenuIconSize, // Use the new constant for icon size
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return ConnectionStatus(isConnected: widget.isConnected);
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildTimedToggleButton(Icons.spa, 1, Colors.pink[400]!, Colors.pink[100]!), // Emission 1
        ),
        Expanded(
          child: _buildTimedToggleButton(Icons.spa, 2, Colors.greenAccent[400]!, Colors.greenAccent[100]!), // Emission 2
        ),
      ],
    );
  }

  Widget _buildTimedToggleButton(IconData icon, int buttonIndex, Color activeColor, Color inactiveColor) {
    return Container(
      margin: EdgeInsets.zero, // Remove any margin
      child: TimedToggleButton(
        autoTurnOffDuration: const Duration(seconds: 5),
        periodicEmissionTimerDuration: const Duration(seconds: 10),
        isConnected: widget.isConnected,
        necklace: widget.necklace,
        bleConnectionBloc: widget.bleConnectionBloc,
        iconData: icon,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        label: 'Emission $buttonIndex',
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
    );
  }
}
