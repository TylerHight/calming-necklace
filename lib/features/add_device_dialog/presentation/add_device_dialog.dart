import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/add_device_dialog/add_device_dialog_state.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/add_device_dialog/add_device_dialog_bloc.dart';
import '../widgets/device_selector.dart';
import '../../../../core/data/models/ble_device.dart';

// Dummy devices for testing
final List<BleDevice> dummyDevices = [
  BleDevice(
    id: '1',
    name: 'Necklace Device 1',
    address: '00:11:22:33:44:55',
    rssi: -65,
    deviceType: BleDeviceType.necklace,
  ),
  BleDevice(
    id: '2',
    name: 'Necklace Device 2',
    address: '66:77:88:99:AA:BB',
    rssi: -50,
    deviceType: BleDeviceType.necklace,
  ),
  BleDevice(
    id: '3',
    name: 'Heart Rate Monitor',
    address: 'CC:DD:EE:FF:00:11',
    rssi: -58,
    deviceType: BleDeviceType.heartRateMonitor,
  ),
];

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  _AddDeviceDialogState createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final TextEditingController _nameController = TextEditingController();
  BleDevice? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddDeviceDialogBloc, AddDeviceDialogState>(
      listener: (context, state) {
        if (state is AddDeviceDialogSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device added successfully')),
          );
        }
      },
      child: BlocProvider(
        create: (context) => DeviceSelectorBloc(),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Necklace Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.spa),
      ),
    );
  }

  Widget _buildDeviceSelector(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceSelectorBloc(),
      child: DeviceSelector(
        devices: dummyDevices.where((d) => d.deviceType == BleDeviceType.necklace).toList(),
        selectedDevice: _selectedDevice,
        onDeviceSelected: (device) {
          setState(() {
            _selectedDevice = device;
          });
        },
      ),
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
              onPressed: state is AddDeviceDialogLoading
                  ? null
                  : () {
                      final name = _nameController.text;
                      if (name.isEmpty || _selectedDevice == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a name and select a device'),
                          ),
                        );
                        return;
                      }
                      context.read<AddDeviceDialogBloc>().add(
                            SubmitAddDeviceEvent(name, _selectedDevice!),
                          );
                    },
              child: const Text('Add'),
            );
          },
        ),
      ],
    );
  }
}
