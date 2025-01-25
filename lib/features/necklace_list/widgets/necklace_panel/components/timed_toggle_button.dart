import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';
import 'package:calming_necklace/features/necklace_list/blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../../../../core/data/models/necklace.dart';

class TimedToggleButton extends StatelessWidget {
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData iconData;
  final Color? iconColor;
  final double buttonSize;
  final double iconSize;
  final Duration autoTurnOffDuration;
  final Duration periodicEmissionTimerDuration;
  final bool isConnected;
  final Necklace necklace;
  final BleConnectionBloc bleConnectionBloc;
  final VoidCallback onToggle;

  const TimedToggleButton({
    Key? key,
    this.activeColor,
    this.inactiveColor = Colors.grey,
    required this.iconData,
    this.iconColor = Colors.white,
    this.buttonSize = 48.0,
    this.iconSize = 24.0,
    required this.autoTurnOffDuration,
    required this.periodicEmissionTimerDuration,
    required this.isConnected,
    required this.necklace,
    required this.bleConnectionBloc,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimedToggleButtonBloc(
        bleConnectionBloc: bleConnectionBloc,
        necklace: necklace,
      ),
      child: _TimedToggleButtonView(
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        iconData: iconData,
        iconColor: iconColor,
        buttonSize: buttonSize,
        iconSize: iconSize,
        autoTurnOffDuration: autoTurnOffDuration,
        autoTurnOffEnabled: necklace.autoTurnOffEnabled,
        periodicEmissionTimerDuration: periodicEmissionTimerDuration,
        periodicEmissionEnabled: necklace.periodicEmissionEnabled,
        isConnected: isConnected,
        onToggle: onToggle,
      ),
    );
  }
}

class _TimedToggleButtonView extends StatelessWidget {
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData iconData;
  final Color? iconColor;
  final double buttonSize;
  final double iconSize;
  final Duration autoTurnOffDuration;
  final bool autoTurnOffEnabled;
  final Duration periodicEmissionTimerDuration;
  final bool periodicEmissionEnabled;
  final bool isConnected;
  final VoidCallback onToggle;

  const _TimedToggleButtonView({
    Key? key,
    this.activeColor,
    this.inactiveColor,
    required this.iconData,
    this.iconColor,
    this.buttonSize = 48.0,
    this.iconSize = 24.0,
    required this.autoTurnOffDuration,
    required this.autoTurnOffEnabled,
    required this.periodicEmissionTimerDuration,
    required this.periodicEmissionEnabled,
    required this.isConnected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onToggle();
        context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
      },
      child: BlocBuilder<TimedToggleButtonBloc, TimedToggleButtonState>(
        builder: (context, state) {
          final buttonColor = activeColor ?? Colors.grey[300];
          bool isLightOn = state is LightOnState;

          return Stack(
            children: [
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? (isLightOn ? buttonColor : inactiveColor) : Colors.grey.shade300,
                ),
                child: Center(
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
              ),
              if (autoTurnOffEnabled && isLightOn && state is AutoTurnOffState)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _formatTime(state.secondsLeft),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (periodicEmissionEnabled && !isLightOn && state is PeriodicEmissionState)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      _formatTime(state.secondsLeft),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds >= 3600) {
      int hours = seconds ~/ 3600;
      return '$hours' 'h';
    } else if (seconds >= 60) {
      int minutes = seconds ~/ 60;
      return '$minutes' 'm';
    } else {
      return '$seconds' 's';
    }
  }
}
