import 'package:flutter/material.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/ble_repository.dart';

class DeviceSelectionDialog extends StatefulWidget {
  final BleDeviceType deviceType;
  final String title;

  const DeviceSelectionDialog({
    Key? key,
    required this.deviceType,
    required this.title,
  }) : super(key: key);

  @override
  State<DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  final BleRepository _bleRepository = BleRepository();
  bool _isScanning = false;
  bool _showLoadingOverlay = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    setState(() => _showLoadingOverlay = true);
    await _bleRepository.startScanning();
    await Future.delayed(const Duration(seconds: 4));
    setState(() => _showLoadingOverlay = false);
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    onPressed: _isScanning ? null : _startScan,
                    icon: Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_showLoadingOverlay)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        Text('Scanning for devices...'),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              StreamBuilder<List<BleDevice>>(
                stream: _bleRepository.devices,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No devices found');
                  }

                  final devices = snapshot.data!
                      .where((device) => device.deviceType == widget.deviceType)
                      .toList();

                  return Container(
                    height: 300,
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(device.name),
                          subtitle: Text(device.address),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${device.rssi} dBm'),
                              Icon(Icons.signal_cellular_alt, size: 16),
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(device),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bleRepository.stopScanning();
    super.dispose();
  }
}
