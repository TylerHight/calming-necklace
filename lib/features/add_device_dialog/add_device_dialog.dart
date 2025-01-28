import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_device_dialog_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import 'add_device_dialog_state.dart';

class AddDeviceDialog extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();

  AddDeviceDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddDeviceDialogBloc, AddDeviceDialogState>(
      listener: (context, state) {
        if (state is AddDeviceDialogSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device added successfully')),
          );
        } else if (state is AddDeviceDialogError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Add Necklace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
              builder: (context, state) {
                if (state is ScanningForDevices) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Scanning for devices...'),
                    ],
                  );
                } else if (state is DevicesFound) {
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: state.devices.length,
                      itemBuilder: (context, index) {
                        final device = state.devices[index];
                        return ListTile(
                          title: Text(device.name),
                          subtitle: Text('Signal: ${device.rssi} dBm'),
                          onTap: () {
                            context.read<AddDeviceDialogBloc>().add(
                              SelectDeviceEvent(device),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
                return ElevatedButton(
                  onPressed: () {
                    context.read<AddDeviceDialogBloc>().add(
                      StartScanningEvent(),
                    );
                  },
                  child: const Text('Scan for Devices'),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
            builder: (context, state) {
              return TextButton(
                onPressed: state is AddDeviceDialogLoading
                    ? null
                    : () {
                        final name = _nameController.text;
                        if (name.isEmpty || state is! DeviceSelected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a name and select a device'),
                            ),
                          );
                          return;
                        }
                        context.read<AddDeviceDialogBloc>().add(
                              SubmitAddDeviceEvent(name, state.device),
                            );
                      },
                child: const Text('Add'),
              );
            },
          ),
        ],
      ),
    );
  }
}
