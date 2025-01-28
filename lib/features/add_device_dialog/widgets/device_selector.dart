import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/ui/components/signal_strength_icon.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/device_selector/device_selector_state.dart';

class DeviceSelector extends StatelessWidget {
  final List<BleDevice> devices;
  final BleDevice? selectedDevice;
  final Function(BleDevice?) onDeviceSelected;

  const DeviceSelector({
    Key? key,
    required this.devices,
    this.selectedDevice,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Device (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdown(context),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<BleDevice>(
      value: selectedDevice,
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
      hint: const Text('No device selected'),
      items: [
        ...devices.map((device) {
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
