import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/services/logging_service.dart';

class BleDeviceInfoDialog extends StatelessWidget {
  final BleDevice device;

  const BleDeviceInfoDialog({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Device Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeviceDetails(),
            const SizedBox(height: 16),
            _buildServicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Name', device.name),
        const SizedBox(height: 8),
        _buildInfoRow('ID', device.id),
        const SizedBox(height: 8),
        _buildInfoRow('Address', device.address),
        const SizedBox(height: 8),
        _buildInfoRow('RSSI', '${device.rssi} dBm'),
        const SizedBox(height: 8),
        _buildInfoRow('Type', device.deviceType.toString().split('.').last),
      ],
    );
  }

  Widget _buildServicesList() {
    if (device.services == null || device.services!.isEmpty) {
      return const Text(
        'No services discovered',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services (${device.services?.length ?? 0})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...device.services?.map((service) => _buildServiceItem(service)) ?? [],
      ],
    );
  }

  Widget _buildServiceItem(BleServiceInfo service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text('Service: ${service.uuid}'),
        children: [
          if (service.characteristics != null && service.characteristics!.isNotEmpty)
            ...service.characteristics!.map((characteristic) => ListTile(
              dense: true,
              title: Text('UUID: ${characteristic.uuid}'),
              subtitle: Text(
                'Properties: ${characteristic.properties.join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
