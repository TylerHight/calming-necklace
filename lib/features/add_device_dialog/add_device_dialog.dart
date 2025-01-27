import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_device_dialog_bloc.dart';
import 'add_device_dialog_state.dart';

class AddDeviceDialog extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bleDeviceController = TextEditingController();

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
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: bleDeviceController,
              decoration: const InputDecoration(labelText: 'BLE Device'),
            ),
            BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
              builder: (context, state) {
                if (state is AddDeviceDialogLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  );
                }
                return const SizedBox.shrink();
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
                        final name = nameController.text;
                        final bleDevice = bleDeviceController.text;
                        if (name.isEmpty || bleDevice.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                            ),
                          );
                          return;
                        }
                        context.read<AddDeviceDialogBloc>().add(
                              SubmitAddDeviceEvent(name, bleDevice),
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
