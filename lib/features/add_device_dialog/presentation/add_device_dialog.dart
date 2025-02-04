import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../blocs/add_device_dialog/add_device_dialog_state.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/add_device_dialog/add_device_dialog_bloc.dart';
import '../blocs/device_selector/device_selector_event.dart';
import '../widgets/device_selector.dart';

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  _AddDeviceDialogState createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  BleDevice? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AddDeviceDialogBloc(context.read<NecklaceRepository>(), context.read<NecklacesBloc>()),
        ),
        BlocProvider(
          create: (context) => DeviceSelectorBloc(bleRepository: BleRepository()),
        ),
      ],
      child: BlocListener<AddDeviceDialogBloc, AddDeviceDialogState>(
        listener: (context, state) {
          if (state is AddDeviceDialogSuccess) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Device added successfully')),
            );
          }
        },
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 500,
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildForm(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Add Necklace',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNameField(),
        const SizedBox(height: 24),
        _buildDeviceSelector(context),
        const SizedBox(height: 24),
        _buildButtons(context),
      ],
    );
  }

  Widget _buildNameField() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Necklace Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          prefixIcon: const Icon(Icons.spa),
        ),
        validator: (value) {
          return value?.isEmpty ?? true ? 'Please enter a name' : null;
        },
      ),
    );
  }

  Widget _buildDeviceSelector(BuildContext context) {
    return DeviceSelector(
      deviceType: BleDeviceType.necklace,
      onDeviceSelected: (device) {
        setState(() => _selectedDevice = device);
        context.read<DeviceSelectorBloc>().add(SelectDevice(device!));
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
          builder: (context, state) {
            return TextButton(
              onPressed: state is AddDeviceDialogLoading ? null : () {
                if (_formKey.currentState?.validate() ?? false) {
                  if (_selectedDevice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a device')),
                    );
                    return;
                  }
                  context.read<AddDeviceDialogBloc>().add(
                        SubmitAddDeviceEvent(_nameController.text, _selectedDevice),
                      );
                }
              },
              child: const Text('Add'),
            );
          },
        ),
      ],
    );
  }
}
