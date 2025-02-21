import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/core/data/models/ble_device.dart';
import 'package:calming_necklace/core/ui/components/signal_strength_icon.dart';
import 'package:calming_necklace/core/ui/ui_constants.dart';
import '../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../core/blocs/ble/ble_event.dart';
import '../../../../core/blocs/ble/ble_state.dart';

class DeviceSelector extends StatefulWidget {
  final BleDeviceType deviceType;
  final Function(BleDevice) onDeviceSelected;

  const DeviceSelector({
    super.key,
    required this.deviceType,
    required this.onDeviceSelected,
  });

  @override
  State<DeviceSelector> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends State<DeviceSelector> {
  late BleBloc _bleBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bleBloc = context.read<BleBloc>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start scanning when the widget is first built
      _bleBloc.add(BleStartScanning());
    });
  }

  @override
  void dispose() {
    _bleBloc.add(BleStopScanning());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<BleBloc, BleState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: state.isScanning
                  ? Container(
                width: double.infinity,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
                  : SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: UIConstants.deviceSelectorDialogTitleSpacing),
            if (state.devices.isEmpty && !state.isScanning)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      state.isScanning ? 'Searching for devices...' : 'No devices found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<bool>(!state.isScanning),
                constraints: const BoxConstraints(maxHeight: UIConstants.deviceSelectorListMaxHeight),
                decoration: BoxDecoration(
                  border: Border.all(color: UIConstants.deviceSelectorBorderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.devices.length,
                  itemBuilder: (context, index) {
                    final device = state.devices[index];
                    return ListTile(
                      title: Text(
                        device.name,
                        style: TextStyle(color: UIConstants.deviceSelectorTextColor),
                      ),
                      subtitle: Text(
                        device.address,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: UIConstants.deviceSelectorTextColor,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SignalStrengthIcon(rssi: device.rssi, color: UIConstants.deviceSelectorIconColor),
                          const SizedBox(width: 8),
                          if (state.selectedDevice?.id == device.id)
                            Icon(Icons.check_circle, color: theme.colorScheme.primary),
                        ],
                      ),
                      selected: state.selectedDevice?.id == device.id,
                      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () {
                        if (state.selectedDevice?.id != device.id) {
                          _bleBloc.add(BleConnectRequest(device));
                          widget.onDeviceSelected(device);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}