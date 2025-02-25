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
    _logger.logDebug('Opening BLE device info dialog for device: ${device.name}');
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 16),
                    _buildServicesList(),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    _logger.logDebug('Building header with device name: ${device.name}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Device Information',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBasicInfo() {
    _logger.logDebug('Building basic info section');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${device.name}'),
            const SizedBox(height: 8),
            Text('ID: ${device.id}'),
            const SizedBox(height: 8),
            Text('Address: ${device.address}'),
            const SizedBox(height: 8),
            Text('RSSI: ${device.rssi} dBm'),
            const SizedBox(height: 8),
            Text('Type: ${device.deviceType.toString().split('.').last}'),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    _logger.logDebug('Building services list with ${device.services.length} services');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...device.services.map((service) {
          _logger.logDebug('Processing service: ${service.uuid}');
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text('Service: ${service.uuid}'),
              children: [
                ...service.characteristics.map((characteristic) {
                  _logger.logDebug('Processing characteristic: ${characteristic.uuid}');
                  return ListTile(
                    title: Text('Characteristic: ${characteristic.uuid}'),
                    subtitle: Text(
                      'Properties: ${characteristic.properties.join(", ")}',
                    ),
                    dense: true,
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            _logger.logDebug('Closing BLE device info dialog');
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
