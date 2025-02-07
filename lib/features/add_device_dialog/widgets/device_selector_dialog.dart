import 'package:calming_necklace/features/add_device_dialog/blocs/device_selector/device_selector_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/ble_device.dart';
import '../../../core/data/repositories/ble_repository.dart';
import '../blocs/device_selector/device_selector_bloc.dart';
import '../blocs/device_selector/device_selector_state.dart';
import '../../../core/ui/ui_constants.dart';
import 'device_selector.dart';

class DeviceSelectorDialog extends StatelessWidget {
  const DeviceSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.deviceSelectorDialogBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 400,
          maxHeight: 500,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: UIConstants.deviceSelectorDialogPadding,
          vertical: UIConstants.deviceSelectorDialogVerticalPadding,
        ),
        child: BlocProvider(
          create: (context) => DeviceSelectorBloc(
            bleRepository: context.read<BleRepository>(),
          ),
          child: _DialogContent(),
        ),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Device',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const SizedBox(height: UIConstants.deviceSelectorDialogTitleSpacing),
        Expanded(
          child: DeviceSelector(
            deviceType: BleDeviceType.necklace,
            onDeviceSelected: (device) {
              Navigator.of(context).pop(device);
            },
          ),
        ),
      ],
    );
  }
}
