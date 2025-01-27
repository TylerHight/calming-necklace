import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'add_device_dialog_bloc.dart';

class AddDeviceDialog extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bleDeviceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Necklace'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: bleDeviceController,
            decoration: InputDecoration(labelText: 'BLE Device'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final name = nameController.text;
            final bleDevice = bleDeviceController.text;
            context.read<AddDeviceDialogBloc>().add(SubmitAddDeviceEvent(name, bleDevice));
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
