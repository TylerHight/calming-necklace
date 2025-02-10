import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/necklaces/necklaces_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../../../core/services/ble/ble_service.dart';
import '../../../core/services/ble/ble_types.dart';
import '../../../core/ui/ui_constants.dart';
import '../blocs/add_device_dialog/add_device_dialog_state.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/add_device_dialog/add_device_dialog_bloc.dart';
import '../blocs/device_selector/device_selector_event.dart';
import '../widgets/device_selector.dart';
import '../widgets/device_selector_dialog.dart';

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
          create: (context) => AddDeviceDialogBloc(
            context.read<NecklaceRepository>(),
            context.read<NecklacesBloc>(),
            BleService(),
          ),
        ),
        BlocProvider(
          create: (context) => DeviceSelectorBloc(
            bleRepository: context.read<BleRepository>(),
          ),
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
        BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
          builder: (context, state) {
            if (state is AddDeviceDialogLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (state is ConnectionInProgress) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Connecting to ${state.deviceName}...',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              );
            }
            if (state is AddDeviceDialogError) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                child: Text(state.error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showDeviceSelectorDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: UIConstants.deviceSelectorBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bluetooth, color: UIConstants.deviceSelectorIconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDevice?.name ?? 'Select a device',
                    style: TextStyle(color: UIConstants.deviceSelectorTextColor),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: UIConstants.deviceSelectorIconColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeviceSelectorDialog(BuildContext context) async {
    final device = await showDialog<BleDevice>(
      context: context,
      builder: (context) => const DeviceSelectorDialog(),
    );
    if (device != null) {
      setState(() => _selectedDevice = device);
      context.read<AddDeviceDialogBloc>().add(SelectDeviceEvent(device));    }
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
          builder: (context, state) {
            if (state is AddDeviceDialogLoading) {
              return const CircularProgressIndicator();
            }
            if (state is AddDeviceDialogError) {
              return Text(
                state.error,
                style: TextStyle(color: Colors.red),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        BlocBuilder<AddDeviceDialogBloc, AddDeviceDialogState>(
          builder: (context, state) {
            return TextButton(
              onPressed: (state is AddDeviceDialogLoading) ? null : () {
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
