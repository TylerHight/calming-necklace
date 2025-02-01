import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/ui/formatters.dart';
import '../blocs/settings/settings_bloc.dart';
import '../widgets/duration_picker_dialog.dart';
import '../widgets/device_selection_dialog.dart';
import '../../../core/data/models/necklace.dart';
import '../../../core/ui/ui_constants.dart';

class SettingsScreen extends StatefulWidget {
  final Necklace necklace;
  final NecklaceRepository repository;
  final DatabaseService databaseService;

  SettingsScreen({
    Key? key,
    required this.necklace,
    required this.repository,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LoggingService _logger = LoggingService();

  @override
  void initState() {
    super.initState();
    _loadLatestSettings();
  }

  Future<void> _loadLatestSettings() async {
    final updatedNecklace = await widget.databaseService.getNecklaceById(widget.necklace.id);
    if (updatedNecklace != null && mounted) {
      context.read<SettingsBloc>().add(RefreshSettings(updatedNecklace));
    }
  }

  Future<void> _refreshSettings() async {
    try {
      final updatedNecklace = await widget.databaseService.getNecklaceById(widget.necklace.id);
      if (updatedNecklace != null && mounted) {
        context.read<SettingsBloc>().add(RefreshSettings(updatedNecklace));
      }
    } catch (e) {
      _logger.logError('Error refreshing settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc(
        widget.necklace,
        widget.repository,
        widget.databaseService
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Device Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                // Save settings implementation
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SettingsContent(
          databaseService: widget.databaseService,
          necklace: widget.necklace,
        ),
      ),
    );
  }
}

class SettingsContent extends StatefulWidget {
  final DatabaseService databaseService;
  final Necklace necklace;

  const SettingsContent({
    Key? key,
    required this.databaseService,
    required this.necklace,
  }) : super(key: key);

  @override
  _SettingsContentState createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  late final LoggingService _logger;

  @override
  void initState() {
    super.initState();
    _logger = LoggingService();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: UIConstants.settingsScreenHorizontalPadding,
            vertical: UIConstants.settingsScreenVerticalPadding,
          ),
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          children: [
            _buildDeviceInfoSection(context, state),
            const SizedBox(height: 16),
            _buildScent1Section(context, state),
            const SizedBox(height: 16),
            _buildConnectionSection(context, state),
            _buildDangerZone(context, state),
          ],
        );
      },
    );
  }

  Widget _buildDeviceInfoSection(BuildContext context, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNameField(context, state),
            const SizedBox(height: 8),
            Text('Device ID: ${state.necklace.id}'),
            Text('BLE Address: ${state.necklace.bleDevice}'),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField(BuildContext context, SettingsState state) {
    return TextFormField(
      initialValue: state.necklace.name,
      decoration: const InputDecoration(
        labelText: 'Device Name',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        context.read<SettingsBloc>().add(UpdateNecklaceName(value));
      },
    );
  }

  Widget _buildScent1Section(BuildContext context, SettingsState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scent 1 Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Emission Duration'),
                subtitle: Text(
                  formatDuration(state.necklace.emission1Duration),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDurationPicker(
                  context,
                  'Scent 1 Emission Duration',
                  state.necklace.emission1Duration,
                  databaseService: widget.databaseService,
                  onDurationSelected: (duration) {
                    context.read<SettingsBloc>().add(
                      UpdateEmissionDuration(duration),
                    );
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('Enable Periodic Emission'),
                value: state.necklace.periodicEmissionEnabled,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    UpdatePeriodicEmission(value),
                  );
                },
              ),
              ListTile(
                title: const Text('Release Interval'),
                subtitle: Text(
                  formatDuration(state.necklace.releaseInterval1),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDurationPicker(
                  context,
                  'Scent 1 Release Interval',
                  state.necklace.releaseInterval1,
                  databaseService: widget.databaseService,
                  onDurationSelected: (duration) {
                    context.read<SettingsBloc>().add(
                      UpdateReleaseInterval(duration),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionSection(BuildContext context, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Change Necklace Device'),
              trailing: const Icon(Icons.bluetooth),
              onTap: () {
                showDialog<BleDevice>(
                  context: context,
                  builder: (context) => DeviceSelectionDialog(
                    deviceType: BleDeviceType.necklace,
                    title: 'Select Necklace Device',
                  ),
                ).then((device) {
                  if (device != null) {
                    // TODO: Implement device change logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected device: ${device.name}')),
                    );
                  }
                });
              },
            ),
            ListTile(
              title: const Text('Change Heart Rate Monitor'),
              trailing: const Icon(Icons.heart_broken),
              onTap: () {
                showDialog<BleDevice>(
                  context: context,
                  builder: (context) => DeviceSelectionDialog(
                    deviceType: BleDeviceType.heartRateMonitor,
                    title: 'Select Heart Rate Monitor',
                  ),
                ).then((device) {
                  if (device != null) {
                    // TODO: Implement device change logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected device: ${device.name}')),
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, SettingsState state) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Delete Device',
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () {
                _showDeleteConfirmation(context, state);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDurationPicker(
      BuildContext context,
      String title,
      Duration initialDuration,
      {required DatabaseService databaseService, required Function(Duration) onDurationSelected,}
      ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return DurationPickerDialog(
          title: title,
          initialDuration: initialDuration,
          isEmissionDuration: title.contains('Emission'),
          necklaceId: widget.necklace.id,
          scentNumber: 1,
          databaseService: databaseService,
          onDurationChanged: (duration) {
            onDurationSelected(duration);
            _logger.logDebug('Duration changed: $duration');
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, SettingsState state) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Device'),
          content: const Text(
            'Are you sure you want to delete this device? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        context.read<SettingsBloc>().add(ArchiveNecklace(state.necklace.id));
        // Refresh the necklaces list
        context.read<NecklacesBloc>().add(FetchNecklacesEvent());
        // Show success message and pop back to main screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device deleted successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting device: $e')),
        );
      }
    }
  }
}
