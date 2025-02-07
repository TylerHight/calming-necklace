import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../../../core/services/ble/ble_service.dart';

class DeviceSelectionDialog extends StatefulWidget {
  final BleDeviceType deviceType;
  final String title;
  final Function(BleDevice)? onDeviceSelected;

  const DeviceSelectionDialog({
    Key? key,
    required this.deviceType,
    required this.title,
    this.onDeviceSelected,
  }) : super(key: key);

  @override
  State<DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<DeviceSelectionDialog> {
  final BleRepository _bleRepository = BleRepository();
  bool _isScanning = false;
  bool _showLoadingOverlay = false;
  bool _isConnecting = false;

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
                          title: Row(
                            children: [
                              Text(
                                device.name,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 8),
                              Text(device.address),
                            ],
                          ),
                          subtitle: Text('${device.rssi} dBm'),
                          trailing: Icon(Icons.signal_cellular_alt, size: 16),
                          onTap: () async {
                            setState(() => _isConnecting = true);
                            try {
                              final bleService = BleService();
                              if (device.device == null) {
                                throw Exception('No BluetoothDevice available');
                              }
                              // Use the stored BluetoothDevice instance
                              await bleService.connectToDevice(device.device!);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Connected to ${device.name}')),
                                );
                                if (widget.onDeviceSelected != null) {
                                  widget.onDeviceSelected!(device);
                                }
                                Navigator.of(context).pop(device);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to connect: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isConnecting = false);
                              }
                            }
                          },
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
