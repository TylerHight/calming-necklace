import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../core/blocs/ble/ble_event.dart';
import '../../../core/blocs/ble/ble_state.dart';
import '../../../core/data/models/ble_device.dart';
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
        child: _DialogContent(),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: const Text(
                  'Select Device',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
              BlocBuilder<BleBloc, BleState>(
                builder: (context, state) => !state.isScanning
                    ? IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<BleBloc>().add(BleStartScanning()),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: UIConstants.deviceSelectorDialogTitleSpacing),
        Expanded(
          child: DeviceSelector(
            deviceType: BleDeviceType.necklace,
            onDeviceSelected: (device) {
              context.read<BleBloc>().add(BleConnectRequest(device));
            },
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<BleBloc, BleState>(
          builder: (context, state) {
            if (state.error != null) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.error ?? 'Unknown error',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            return ElevatedButton(
              onPressed: state.selectedDevice == null ? null : () {
                Navigator.of(context).pop(state.selectedDevice);
              },
              child: const Text('Confirm Selection'),
            );
          },
        ),
      ],
    );
  }
}