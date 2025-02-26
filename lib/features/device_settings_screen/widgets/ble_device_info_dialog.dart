import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/services/logging_service.dart';

class BleDeviceInfoDialog extends StatelessWidget {
  final BleDevice device;
  final LoggingService _logger = LoggingService.instance;

  BleDeviceInfoDialog({
    Key? key,
    required this.device,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _logger.logDebug('Building BLE Device Info Dialog for device: ${device.id}');
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
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
            Expanded(
              child: SingleChildScrollView(
                child: _buildServicesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    _logger.logDebug('Device services before dialog: ${device.services?.length ?? 0}');

    if (device.services == null) {
      _logger.logDebug('No services data available for device: ${device.id}');
      return const Text(
        'No services information available',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    final services = device.services!.where((s) => s.uuid.isNotEmpty).toList();
    if (services.isEmpty) {
      return const Text(
        'No valid services discovered',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services (${services.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: services.map((service) => _buildServiceItem(service)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BleServiceInfo service) {
    final characteristics = service.characteristics
        ?.where((c) => c.uuid.isNotEmpty)
        .toList() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text('Service: ${_formatUuid(service.uuid)}'),
        subtitle: Text('${characteristics.length} characteristics'),
        children: characteristics
            .map((c) => _buildCharacteristicItem(c))
            .toList(),
      ),
    );
  }

  Widget _buildCharacteristicItem(BleCharacteristicInfo characteristic) {
    return ListTile(
      dense: true,
      title: Text('UUID: ${_formatUuid(characteristic.uuid)}'),
      subtitle: Text('Properties: ${_formatProperties(characteristic.properties)}'),
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

  String _formatUuid(String uuid) {
    return uuid.toUpperCase();
  }

  String _formatProperties(List<String> properties) {
    if (properties.isEmpty) return 'None';
    return properties.map((p) => p.toUpperCase()).join(', ');
  }
}