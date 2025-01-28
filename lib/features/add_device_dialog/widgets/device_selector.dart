import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _buildDropdown(),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<BleDevice>(
      value: selectedDevice,
      isExpanded: true,
      isDense: true,
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
      hint: const Text('Select a device'),
      items: [
        const DropdownMenuItem<BleDevice>(
          value: null,
          child: Text('No device'),
        ),
        ...devices.map((device) {
          return DropdownMenuItem<BleDevice>(
            value: device,
            child: Row(
              children: [
                _buildSignalStrengthIcon(device.rssi),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(device.name),
                      Text(
                        'Signal: ${device.rssi} dBm',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: onDeviceSelected,
    );
  }

  Widget _buildSignalStrengthIcon(int rssi) {
    if (rssi > -60) {
      return SvgPicture.asset('assets/icons/signal_strong.svg');
    } else if (rssi > -75) {
      return SvgPicture.asset('assets/icons/signal_good.svg');
    } else if (rssi > -90) {
      return SvgPicture.asset('assets/icons/signal_weak.svg');
    } else {
      return SvgPicture.asset('assets/icons/signal_none.svg');
    }
  }
}
