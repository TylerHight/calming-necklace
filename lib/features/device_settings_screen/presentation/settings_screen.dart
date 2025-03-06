import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/ble/ble_settings_sync_service.dart';
import '../../../core/blocs/ble/ble_event.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/ui/formatters.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../widgets/duration_picker_dialog.dart';
import '../widgets/heart_rate_settings_dialog.dart';
import '../widgets/settings_help_dialog.dart';
import '../widgets/ble_device_info.dart';
import '../widgets/ble_device_info_dialog.dart';
import '../../../core/data/models/necklace.dart';
import '../../../core/ui/ui_constants.dart';
import '../../../core/blocs/ble/ble_bloc.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../../../features/add_device_dialog/widgets/device_selector_dialog.dart';
import '../../../features/add_device_dialog/blocs/device_selector/device_selector_bloc.dart';

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
  final BleSettingsSyncService _settingsSyncService = BleSettingsSyncService();
  bool _isLoading = false;
  bool _isSyncing = false;

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
    return WillPopScope(
      onWillPop: () async {
        await _syncSettingsWithDevice(context, showLoadingIndicator: true);
        return true;
      },
      child: BlocProvider(
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
                icon: const Icon(Icons.sync, color: Colors.black87),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manually syncing settings...'))
                  );
                  await _syncSettingsWithDevice(context, showLoadingIndicator: true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual sync completed'))
                  );
                },
              ),
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
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _isSyncing 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.white), SizedBox(width: 16), 
                  Text('Syncing settings...', style: TextStyle(color: Colors.white))]))
            : null,
        ),
      ),
    );
  }

  /// Synchronizes changed settings with the BLE device when leaving the settings screen
  Future<void> _syncSettingsWithDevice(BuildContext context, {bool showLoadingIndicator = false}) async {
    final settingsBloc = context.read<SettingsBloc>();
    if (_isSyncing) return; // Prevent multiple syncs running at once
    
    final currentState = settingsBloc.state;
    final stateNecklace = currentState.necklace;
    
    if (stateNecklace.bleDevice == null) {
      _logger.logWarning('Cannot sync settings: Missing BLE device');
      return;
    }
    
    // Get the latest necklace from the database to compare with the state's necklace
    final updatedNecklace = await widget.databaseService.getNecklaceById(stateNecklace.id);
    if (updatedNecklace == null) {
      _logger.logWarning('Cannot sync settings: Unable to retrieve necklace from database');
      return;
    }

    // Check if any settings have changed
    if (_haveSettingsChanged(stateNecklace, updatedNecklace)) {
      _logger.logInfo('Settings have changed, syncing with device. State necklace vs DB necklace:');
      _logger.logDebug('State emission duration: ${stateNecklace.emission1Duration}, DB: ${updatedNecklace.emission1Duration}');
      _logger.logDebug('State release interval: ${stateNecklace.releaseInterval1}, DB: ${updatedNecklace.releaseInterval1}');
      _logger.logDebug('State periodic emission: ${stateNecklace.periodicEmissionEnabled}, DB: ${updatedNecklace.periodicEmissionEnabled}');
      
      try {
        if (showLoadingIndicator) {
          setState(() => _isSyncing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Syncing settings with device...'))
          );
        }

        // Sync the changed settings with the device
        // The state necklace contains the original settings, and the database necklace contains the updated settings
        await _settingsSyncService.syncChangedSettings(stateNecklace, updatedNecklace);
        
        // Save settings to ensure everything is in sync
        settingsBloc.add(SaveSettings());

        if (showLoadingIndicator) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings synced successfully with device'))
          );
          setState(() => _isSyncing = false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync settings: $e'))
        );
        setState(() => _isSyncing = false);
      }
    }
  }

  /// Checks if any settings have changed between the original and current necklace
  bool _haveSettingsChanged(Necklace stateNecklace, Necklace dbNecklace) {
    return stateNecklace.emission1Duration != dbNecklace.emission1Duration ||
           stateNecklace.releaseInterval1 != dbNecklace.releaseInterval1 ||
           stateNecklace.periodicEmissionEnabled != dbNecklace.periodicEmissionEnabled ||
           stateNecklace.isHeartRateBasedReleaseEnabled != dbNecklace.isHeartRateBasedReleaseEnabled ||
           stateNecklace.highHeartRateThreshold != dbNecklace.highHeartRateThreshold ||
           stateNecklace.lowHeartRateThreshold != dbNecklace.lowHeartRateThreshold;
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
            const SizedBox(height: 16),
            _buildDangerZone(context, state),
          ],
        );
      },
    );
  }

  /// Builds the section displaying the necklace title, renaming option, and connected BLE device information.
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
              onChanged: (value) {
                context.read<SettingsBloc>().add(
                  UpdateHeartRateBasedRelease(value),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Heart rate based release ${value ? 'enabled' : 'disabled'}')),
                );
              },
            ),
            ListTile(
              title: const Text('Adjust Heart Rate Thresholds'),
              subtitle: Text(
                'High: ${state.necklace.highHeartRateThreshold} BPM, ' +
                'Low: ${state.necklace.lowHeartRateThreshold} BPM'
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => showDialog(
                context: context,
                builder: (context) => HeartRateSettingsDialog(
                  necklaceId: state.necklace.id,
                  initialHighThreshold: state.necklace.highHeartRateThreshold,
                  initialLowThreshold: state.necklace.lowHeartRateThreshold,
                ),
              ).then((saved) {
                if (saved == true) {
                  _refreshSettings();
                }
              }),
            ),
            ListTile(
              title: const Text('Change Heart Rate Monitor'),
              trailing: const Icon(Icons.heart_broken),
              subtitle: state.necklace.heartRateMonitorDevice != null
                ? Text(
                    state.necklace.heartRateMonitorDevice!.name,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                : null,
              onTap: () => showDialog<BleDevice>(
                  context: context,
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) => DeviceSelectorBloc(
                          bleRepository: context.read<BleRepository>(),
                          bleBloc: context.read<BleBloc>(),
                        ),
                      ),
                    ],
                    child: DeviceSelectorDialog(
                      deviceType: BleDeviceType.heartRateMonitor,
                      title: 'Select Heart Rate Monitor',
                    ),
                  ),
                ).then((device) async {
                  try {
                    if (device != null) {
                        final deviceJson = jsonEncode(device.toMap());
                        _logger.logDebug('Saving heart rate monitor device: ${deviceJson.substring(0, 100)}...');
                        await widget.databaseService.updateNecklaceSettings(
                          widget.necklace.id,
                          {'heartRateMonitorDevice': deviceJson},
                        );
                        // Refresh settings
                        context.read<SettingsBloc>().add(
                          RefreshSettings(widget.necklace.copyWith(
                            heartRateMonitorDevice: device,
                          )),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected device: ${device.name}')),
                        );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating heart rate monitor: $e')),
                    );
                  }
                }),
            ),
            ListTile(
              title: const Text('View Heart Rate Monitor Info'),
              subtitle: state.necklace.heartRateMonitorDevice != null
                  ? Text('View detailed device information')
                  : Text('No device connected'),
              trailing: const Icon(Icons.info_outline),
              onTap: () {
                if (state.necklace.heartRateMonitorDevice != null) {
                  _showDeviceInfoDialog(context, state.necklace.heartRateMonitorDevice!);
                }
              },
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
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context)
                            => DeviceSelectorBloc(
                          bleRepository: context.read<BleRepository>(),
                          bleBloc: context.read<BleBloc>(),
                        ),
                      ),
                    ],
                    child: DeviceSelectorDialog(
                      deviceType: BleDeviceType.necklace,
                      title: 'Select Necklace Device',
                    ),
                  ),
                ).then((device) async {
                  try {
                    if (device != null) {
                        final deviceJson = jsonEncode(device.toMap());
                        _logger.logDebug('Saving necklace device: ${deviceJson.substring(0, 100)}...');
                        await widget.databaseService.updateNecklaceSettings(
                          widget.necklace.id,
                          {'bleDevice': deviceJson},
                        );

                        // Notify the necklaces bloc to refresh
                        context.read<NecklacesBloc>().add(FetchNecklacesEvent());

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connected to ${device.name}')),
                        );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating device: $e')),
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
          showSecondsOnly: title.contains('Release Duration'),
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

  void _showDeviceInfoDialog(BuildContext context, BleDevice device) {
    _logger.logDebug('Showing device info dialog for ${device.name}');
    showDialog(
      context: context,
      builder: (context) => BleDeviceInfoDialog(
        device: device,
      ),
    ).then((_) {
      _logger.logDebug('Device info dialog closed');
    });
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
        // First disconnect from the BLE device if it exists
        final bleBloc = context.read<BleBloc>();
        if (state.necklace.bleDevice != null) {
          // Ensure device is properly disconnected before deletion
          await Future.wait([
            Future(() => bleBloc.add(
              BleDisconnectRequest(state.necklace.bleDevice!.id),
            )),
            // Wait for disconnect to complete
            Future.delayed(const Duration(seconds: 1)),
          ]);
        }

        // Archive the necklace only after disconnect is complete
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
