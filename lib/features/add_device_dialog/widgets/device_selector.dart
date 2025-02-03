import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/ui/components/signal_strength_icon.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/device_selector/device_selector_event.dart';
import '../blocs/device_selector/device_selector_state.dart';

class DeviceSelector extends StatelessWidget {
  final BleDeviceType deviceType;
  final Function(BleDevice?) onDeviceSelected;

  const DeviceSelector({
    Key? key,
    required this.deviceType,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceSelectorBloc, DeviceSelectorState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Device (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                if (state.isScanning)
                  const SizedBox(
                    width: 16,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      context.read<DeviceSelectorBloc>().add(StartScanning());
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeviceList(context, state),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList(BuildContext context, DeviceSelectorState state) {
    return DropdownButtonFormField<BleDevice>(
      value: state.selectedDevice,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      hint: Text(
        state.isScanning 
          ? 'Scanning for devices...' 
          : state.devices.isEmpty 
            ? 'No devices found - tap refresh to scan' 
            : 'Select a device (optional)'),
      items: [
        ...state.devices.map((device) {
          return DropdownMenuItem<BleDevice>(
            value: device,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SignalStrengthIcon(rssi: device.rssi),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(device.name),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (BleDevice? device) {
        onDeviceSelected(device);
      },
    );
  }
}
