import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/ui/formatters.dart';
import '../blocs/settings/settings_bloc.dart';
import '../widgets/duration_picker_dialog.dart';
import '../widgets/heart_rate_settings_dialog.dart';
import '../widgets/device_selection_dialog.dart';
import '../widgets/settings_help_dialog.dart';
import '../widgets/ble_device_info.dart';
import '../../../core/data/models/necklace.dart';
import '../../../core/ui/ui_constants.dart';

class SettingsScreen extends StatefulWidget {
  final Necklace necklace;
  final NecklaceRepository repository;
  final DatabaseService databaseService;

  const SettingsScreen({
    Key? key,
    required this.necklace,
    required this.repository,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late LoggingService _logger;

  @override
  void initState() {
    super.initState();
    _initializeLogger();
    _loadLatestSettings();
  }

  Future<void> _initializeLogger() async {
    _logger = await LoggingService.getInstance();
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
      lazy: false,
      create: (context) => SettingsBloc(
        widget.necklace,
        widget.repository,
        widget.databaseService,
      )..add(RefreshSettings(widget.necklace)),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.black87),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const SettingsHelpDialog(),
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
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
  late LoggingService _logger;

  @override
  void initState() {
    super.initState();
    _initializeLogger();
  }

  Future<void> _initializeLogger() async {
    _logger = await LoggingService.getInstance();
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
            _buildHeartRateSection(context, state),
            const SizedBox(height: 16),
            _buildConnectionSection(context, state),
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
              'Necklace Name',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              subtitle: TextFormField(
                initialValue: state.necklace.name,
                decoration: const InputDecoration(
                  labelText: 'Rename necklace',
                  hintText: 'Enter device name',
                  border: UnderlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<SettingsBloc>().add(UpdateNecklaceName(value));
                  }
                },
              )
            ),
            if (state.isSaved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Changes saved',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (state.necklace.bleDevice != null) ...[
              Row(
                children: [
                  Text(
                    'Connected Device:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  BleDeviceInfo(
                    device: state.necklace.bleDevice!,
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No device connected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
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
                'Scent Release Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Release Duration'),
                subtitle: Text(
                  formatDuration(state.necklace.emission1Duration, useFullWords: true),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDurationPicker(
                  context,
                  'Scent Release Duration',
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
                title: const Text('Enable Repeated Release'),
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
                  formatDuration(state.necklace.releaseInterval1, useFullWords: true),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showDurationPicker(
                  context,
                  'Scent Release Interval',
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

  Widget _buildHeartRateSection(BuildContext context, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Heart Rate Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Heart Rate Based Release'),
              value: state.necklace.isHeartRateBasedReleaseEnabled,
              onChanged: null,
            ),
            ListTile(
              title: Text('Configure Heart Rate Thresholds'),
              subtitle: Text(
                'High: ${state.necklace.highHeartRateThreshold} BPM, ' +
                'Low: ${state.necklace.lowHeartRateThreshold} BPM'
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => showDialog(
                context: context,
                builder: (context) => HeartRateSettingsDialog(
                  necklaceId: state.necklace.id,
                  initialEnabled: state.necklace.isHeartRateBasedReleaseEnabled,
                  initialHighThreshold: state.necklace.highHeartRateThreshold,
                  initialLowThreshold: state.necklace.lowHeartRateThreshold,
                ),
              ).then((saved) {
                if (saved == true) {
                  _refreshSettings();
                }
              }),
            ),
          ],
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
                final bleService = BleService();
                showDialog(
                  context: context,
                  builder: (context) => DeviceSelectionDialog(
                    deviceType: BleDeviceType.necklace,
                    title: 'Select Necklace Device',
                    onDeviceSelected: (device) async {
                      try {
                        // Update necklace in database with new device
                        await widget.databaseService.updateNecklaceSettings(
                          widget.necklace.id,
                          {'bleDevice': device.toMap()},
                        );

                        // Notify the necklaces bloc to refresh
                        context.read<NecklacesBloc>().add(FetchNecklacesEvent());

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected to ${device.name}')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating device: $e')),
                        );
                      }
                    },
                  ),
                );
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
