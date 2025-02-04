import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';
import 'package:calming_necklace/core/ui/components/signal_strength_icon.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start scanning when the widget is first built
      context.read<DeviceSelectorBloc>().add(StartScanning());
    });
  }

  @override
  void dispose() {
    context.read<DeviceSelectorBloc>().add(StopScanning());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSelectorBloc, DeviceSelectorState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDeviceList(state),
            const SizedBox(height: 16),
            _buildScanButton(context, state),
          ],
        );
      },
    );
  }

  Widget _buildScanButton(BuildContext context, DeviceSelectorState state) {
    return ElevatedButton.icon(
      icon: state.isScanning
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.bluetooth_searching, size: 20),
      label: Text(state.isScanning ? 'Scanning...' : 'Rescan for Devices'),
      onPressed: () {
        if (!state.isScanning) {
          context.read<DeviceSelectorBloc>().add(StartScanning());
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDeviceList(DeviceSelectorState state) {
    if (state.devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          state.isScanning ? 'Searching for devices...' : 'No devices found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.devices.length,
        itemBuilder: (context, index) {
          final device = state.devices[index];
          return ListTile(
            title: Text(device.name),
            subtitle: Text(device.address),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SignalStrengthIcon(rssi: device.rssi),
                const SizedBox(width: 8),
                if (state.selectedDevice?.id == device.id)
                  const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ),
            onTap: () {
              widget.onDeviceSelected(device);
              context.read<DeviceSelectorBloc>().add(SelectDevice(device));
            },
          );
        },
      ),
    );
  }
}
