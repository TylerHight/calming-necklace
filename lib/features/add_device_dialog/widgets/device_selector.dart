import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';
import 'package:calming_necklace/core/ui/components/signal_strength_icon.dart';
import 'package:calming_necklace/core/ui/ui_constants.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/device_selector/device_selector_event.dart';
import '../blocs/device_selector/device_selector_state.dart';

class DeviceSelector extends StatefulWidget {
  final BleDeviceType deviceType;
  final Function(BleDevice) onDeviceSelected;

  const DeviceSelector({
    super.key,
    required this.deviceType,
    required this.onDeviceSelected,
  });

  @override
  State<DeviceSelector> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends State<DeviceSelector> {
  late DeviceSelectorBloc _deviceSelectorBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deviceSelectorBloc = context.read<DeviceSelectorBloc>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start scanning when the widget is first built
      _deviceSelectorBloc.add(StartScanning());
    });
  }

  @override
  void dispose() {
    _deviceSelectorBloc.add(StopScanning());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<DeviceSelectorBloc, DeviceSelectorState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildDeviceList(state, theme),
            if (state.devices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.isScanning)
                      const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      state.isScanning ? 'Searching for devices...' : 'No devices found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (!state.isScanning)
                      ElevatedButton.icon(
                        icon: Icon(Icons.refresh, color: UIConstants.deviceSelectorIconColor),
                        label: Text(
                          'Scan for Devices',
                          style: TextStyle(color: UIConstants.deviceSelectorTextColor),
                        ),
                        onPressed: () => context.read<DeviceSelectorBloc>().add(StartScanning()),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList(DeviceSelectorState state, ThemeData theme) {
    if (state.devices.isEmpty) {
      return Container();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: UIConstants.deviceSelectorBorderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.devices.length,
        itemBuilder: (context, index) {
          final device = state.devices[index];
          return ListTile(
            title: Text(
              device.name,
              style: TextStyle(color: UIConstants.deviceSelectorTextColor),
            ),
            subtitle: Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      device.address,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: UIConstants.deviceSelectorTextColor),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SignalStrengthIcon(rssi: device.rssi, color: UIConstants.deviceSelectorIconColor),
                const SizedBox(width: 8),
                if (state.selectedDevice?.id == device.id)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
            selected: state.selectedDevice?.id == device.id,
            selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () {
              if (state.selectedDevice?.id != device.id) {
                _deviceSelectorBloc.add(SelectDevice(device));
                widget.onDeviceSelected(device);
              }
            },
          );
        },
      ),
    );
  }
}
