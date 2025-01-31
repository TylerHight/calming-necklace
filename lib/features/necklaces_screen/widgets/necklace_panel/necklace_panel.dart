import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/ui/components/signal_strength_icon.dart';
import 'components/timed_toggle_button.dart';
import 'components/connection_status.dart';
import '../../blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/ui/ui_constants.dart';
import '../../../../features/device_settings_screen/presentation/settings_screen.dart';
import '../../../../features/notes/widgets/add_note_dialog.dart';

class NecklacePanel extends StatefulWidget {
  final int index;
  final String name;
  final bool isConnected;
  final Necklace necklace;
  final NecklaceRepository repository;
  final DatabaseService databaseService;

  const NecklacePanel({
    Key? key,
    required this.index,
    required this.name,
    required this.isConnected,
    required this.necklace,
    required this.repository,
    required this.databaseService,
  }) : super(key: key);

  @override
  _NecklacePanelState createState() => _NecklacePanelState();
}

class _NecklacePanelState extends State<NecklacePanel> {
  bool isRelease1Active = false;

  void _showOptions(BuildContext context, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
              const Icon(Icons.note_add),
              SizedBox(width: 8),
              Text('Add Note'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'settings') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              necklace: widget.necklace,
              repository: widget.repository,
              databaseService: widget.databaseService, // Pass DatabaseService
            ),
          ),
        );
      } else if (value == 'add_note') {
        showDialog(
          context: context,
          builder: (context) => AddNoteDialog(
            deviceId: widget.necklace.id,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logger = LoggingService();
    logger.logDebug('Building NecklacePanel for ${widget.name}');
    logger.logDebug('NecklacePanel: Using provided repository: ${widget.repository}');
    final repository = widget.repository; // TODO: handle with bloc instead of directly accessing repository
    
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.name,
          style: const TextStyle(
            fontSize: UIConstants.titleTextSize,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        _buildConnectionIndicator(),
      ],
    );
  }

  Widget _buildConnectionIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ConnectionStatus(isConnected: widget.isConnected),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0), // Add padding around the row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space the buttons
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: UIConstants.settingsIconSize,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsScreen(
                  necklace: widget.necklace,
                  repository: widget.repository,
                  databaseService: widget.databaseService,
                ),
              ),
            ),
          ),
          const SizedBox(width: UIConstants.settingsNotesSpacing), // Spacing between the settings button and the notes button
          IconButton(
            icon: const Icon(Icons.note_add),
            iconSize: UIConstants.notesIconSize,
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddNoteDialog(
                deviceId: widget.necklace.id,
              ),
            ),
          ),
          const SizedBox(width: UIConstants.notesToggleSpacing), // Spacing between the notes button and the toggle button
          SizedBox(
            width: UIConstants.timedToggleButtonWidth,
            child: _buildTimedToggleButton(Icons.spa, Colors.blue[400]!, Colors.blue[100]!),
          ),
        ],
      ),
    );
  }

  Widget _buildTimedToggleButton(IconData icon, Color activeColor, Color inactiveColor) {
    return Container(
      margin: EdgeInsets.zero, // Remove any margin
      child: TimedToggleButton(
        autoTurnOffDuration: const Duration(seconds: 5),
        periodicEmissionTimerDuration: const Duration(seconds: 10),
        isConnected: widget.isConnected,
        databaseService: widget.databaseService,
        necklace: widget.necklace,
        iconData: icon,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        label: 'Emission 1',
        buttonWidth: UIConstants.timedToggleButtonWidth,
        buttonHeight: UIConstants.timedToggleButtonHeight,
        onToggle: () {
          setState(() {
            isRelease1Active = !isRelease1Active;
          });
        },
      ),
    );
  }
}
