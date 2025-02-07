import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/models/necklace.dart';
import '../../../../core/data/repositories/necklace_repository.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/ui/components/signal_strength_icon.dart';
import 'components/timed_toggle_button.dart';
import 'components/connection_status.dart';
import 'components/periodic_emission_timer.dart';
import '../../blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../blocs/periodic_emission/periodic_emission_bloc.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/ui/ui_constants.dart';
import '../../../../features/device_settings_screen/presentation/settings_screen.dart';
import '../../../../features/notes/widgets/add_note_dialog.dart';
import '../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../core/blocs/ble/ble_state.dart';

class NecklacePanel extends StatefulWidget {
  final int index;
  final String name;
  final Necklace necklace;
  final NecklaceRepository repository;
  final DatabaseService databaseService;
  final bool isConnected;
  final int rssi;

  const NecklacePanel({
    Key? key,
    required this.index,
    required this.name,
    required this.necklace,
    required this.repository,
    required this.databaseService,
    required this.isConnected,
    required this.rssi,
  }) : super(key: key);

  @override
  _NecklacePanelState createState() => _NecklacePanelState();
}

class _NecklacePanelState extends State<NecklacePanel> {
  bool isRelease1Active = false;

  @override
  void initState() {
    super.initState();
  }

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
              databaseService: widget.databaseService,
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

    return BlocBuilder<BleBloc, BleState>(
      builder: (context, bleState) {
        final isConnected = widget.necklace.bleDevice != null &&
            (bleState.deviceConnectionStates[widget.necklace.bleDevice] ?? false);

        final rssi = isConnected ? (bleState.rssi ?? 0) : 0;

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => TimedToggleButtonBloc(
                repository: widget.repository,
                necklace: widget.necklace,
              ),
            ),
            BlocProvider(
              create: (context) => PeriodicEmissionBloc(
                necklace: widget.necklace,
                repository: widget.repository,
              )..add(const InitializePeriodicEmission()),
            ),
          ],
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
                  colors: [Colors.white, Colors.grey.shade200],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isConnected, rssi),
                  if (widget.necklace.periodicEmissionEnabled)
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: PeriodicEmissionTimer()),
                  const SizedBox(height: 16),
                  _buildControls(isConnected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isConnected, int rssi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.necklacePanelHeaderHorizontalPadding),
      child: Row(
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
          _buildConnectionIndicator(isConnected, rssi),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(bool isConnected, int rssi) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ConnectionStatus(
        isConnected: true,
        deviceId: 'device_id_123',
      )
    );
  }

  Widget _buildControls(bool isConnected) {
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