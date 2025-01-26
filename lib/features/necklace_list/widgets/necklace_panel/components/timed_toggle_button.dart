import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/core/blocs/ble_connection/ble_connection_bloc.dart';
import 'package:calming_necklace/features/necklace_list/blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../../../../core/data/models/necklace.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../repositories/necklace_repository.dart';

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
    this.activeColor = const Color(0xFF1E88E5),
    this.inactiveColor = const Color(0xFFBBDEFB),
    required this.iconData,
    this.iconColor = Colors.white,
    this.buttonSize = 60.0,
    this.iconSize = 28.0,
    required this.autoTurnOffDuration,
    required this.periodicEmissionTimerDuration,
    required this.isConnected,
    required this.necklace,
    required this.bleConnectionBloc,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repository = context.read<NecklaceRepository>();
    final logger = LoggingService();
    
    return BlocProvider(
      create: (context) => TimedToggleButtonBloc(
        repository: repository,
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
    required this.activeColor,
    required this.inactiveColor,
    required this.iconData,
    required this.iconColor,
    required this.buttonSize,
    required this.iconSize,
    required this.autoTurnOffDuration,
    required this.autoTurnOffEnabled,
    required this.periodicEmissionTimerDuration,
    required this.periodicEmissionEnabled,
    required this.isConnected,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimedToggleButtonBloc, TimedToggleButtonState>(
      buildWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) return true;
        if (previous is LightOnState && current is LightOnState) {
          return previous.secondsLeft != current.secondsLeft;
        }
        return true;
      },
      builder: (context, state) {
        if (state is TimedToggleButtonLoading) {
          return const CircularProgressIndicator();
        }
        
        if (state is TimedToggleButtonError) {
          return Tooltip(
            message: state.message,
            child: Icon(Icons.error, color: Colors.red),
          );
        }

        bool isLightOn = state is LightOnState;
        String timeLeft = isLightOn ? _formatTime((state as LightOnState).secondsLeft) : '';
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(buttonSize / 2),
                onTap: () {
                  if (!isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device not connected')),
                    );
                    return;
                  }
                  context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
                },
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLightOn ? activeColor : inactiveColor,
                    boxShadow: isLightOn ? [
                      BoxShadow(
                        color: activeColor!.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
            if (isLightOn)
              Positioned(
                top: -24,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeLeft,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    if (seconds >= 3600) {
      int hours = seconds ~/ 3600;
      return '${hours}h';
    } else if (seconds >= 60) {
      int minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}
