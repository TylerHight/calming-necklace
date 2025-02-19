import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../../../../core/blocs/ble/ble_event.dart';
import '../../../../../core/blocs/ble/ble_state.dart';
import '../../../../../core/data/models/necklace.dart';
import '../../../../../core/data/repositories/necklace_repository.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/services/database_service.dart';
import '../../../../../core/blocs/ble/ble_bloc.dart';
import '../../../../../core/ui/ui_constants.dart';
import 'release_interval_countdown.dart';

class TimedToggleButton extends StatelessWidget {
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData iconData;
  final Color? iconColor;
  final double buttonHeight;
  final double iconSize;
  final double buttonWidth;
  final Duration autoTurnOffDuration;
  final Duration periodicEmissionTimerDuration;
  final bool isConnected;
  final Necklace necklace;
  final DatabaseService databaseService;
  final VoidCallback onToggle;
  final String label;

  const TimedToggleButton({
    Key? key,
    this.activeColor = const Color(0xFF1E88E5),
    this.inactiveColor = const Color(0xFFBBDEFB),
    required this.iconData,
    this.iconColor = Colors.white,
    this.buttonHeight = 60.0,
    this.iconSize = 28.0,
    required this.buttonWidth,
    required this.autoTurnOffDuration,
    required this.periodicEmissionTimerDuration,
    required this.isConnected,
    required this.necklace,
    required this.databaseService,
    required this.onToggle,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimedToggleButtonBloc(
        repository: context.read<NecklaceRepository>(),
        necklace: necklace,
      ),
      child: _TimedToggleButtonView(
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        iconData: iconData,
        iconColor: iconColor,
        buttonHeight: buttonHeight,
        iconSize: iconSize,
        buttonWidth: buttonWidth,
        autoTurnOffDuration: autoTurnOffDuration,
        autoTurnOffEnabled: necklace.autoTurnOffEnabled,
        periodicEmissionTimerDuration: periodicEmissionTimerDuration,
        periodicEmissionEnabled: necklace.periodicEmissionEnabled,
        isConnected: isConnected,
        databaseService: databaseService,
        onToggle: onToggle,
        label: label,
        necklace: necklace,
      ),
    );
  }
}

class _TimedToggleButtonView extends StatefulWidget {
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData iconData;
  final Color? iconColor;
  final double buttonHeight;
  final double iconSize;
  final double buttonWidth;
  final Duration autoTurnOffDuration;
  final bool autoTurnOffEnabled;
  final Duration periodicEmissionTimerDuration;
  final bool periodicEmissionEnabled;
  final bool isConnected;
  final DatabaseService databaseService;
  final VoidCallback onToggle;
  final String label;
  final Necklace necklace;

  const _TimedToggleButtonView({
    Key? key,
    required this.activeColor,
    required this.inactiveColor,
    required this.iconData,
    required this.iconColor,
    required this.buttonHeight,
    required this.iconSize,
    required this.buttonWidth,
    required this.autoTurnOffDuration,
    required this.autoTurnOffEnabled,
    required this.periodicEmissionTimerDuration,
    required this.periodicEmissionEnabled,
    required this.isConnected,
    required this.databaseService,
    required this.onToggle,
    required this.label,
    required this.necklace,
  }) : super(key: key);

  @override
  State<_TimedToggleButtonView> createState() => _TimedToggleButtonState();
}

class _TimedToggleButtonState extends State<_TimedToggleButtonView> {
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimedToggleButtonBloc, TimedToggleButtonState>(
      listener: (context, state) {
        if (state is TimedToggleButtonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is TimedToggleButtonLoading) {
          return Container(
            width: widget.buttonWidth,
            height: widget.buttonHeight,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        if (state is TimedToggleButtonError) {
          return _buildErrorButton(
            message: state.message,
            child: Icon(Icons.error, color: Colors.red),
          );
        }

        final isLightOn = state is LightOnState;
        final timeLeft = isLightOn ? _formatTime((state).secondsLeft) : '';

        final logger = LoggingService.instance;
        logger.logDebug('Building TimedToggleButton: isLightOn: $isLightOn, timeLeft: $timeLeft');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (!widget.isConnected) {
                await _handleDisconnectedState(context);
                return;
              }

              final currentState = context.read<TimedToggleButtonBloc>().state;
              final shouldTurnOn = !(currentState is LightOnState);
              LoggingService.instance.logDebug('Sending LED control request');
              
              // First update the UI state
              context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
              
              // Then send the BLE command
              Future.microtask(() {
                context.read<BleBloc>().add(BleLedControlRequest(
                  turnOn: shouldTurnOn,
                  deviceId: widget.necklace.bleDevice!.id,
                ));
              });
            },
            onTapDown: (_) {
              setState(() {
                _lastTapTime = DateTime.now();
              });
            },
            child: Container(
              width: UIConstants.timedToggleButtonWidth,
              height: UIConstants.timedToggleButtonHeight,
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isLightOn ? widget.activeColor!.withOpacity(0.9) : widget.inactiveColor!.withOpacity(0.9),
                    isLightOn ? widget.activeColor! : widget.inactiveColor!,
                  ],
                ),
                borderRadius: BorderRadius.circular(UIConstants.timedToggleButtonBorderRadius),
                boxShadow: isLightOn ? [
                  BoxShadow(
                    color: widget.activeColor!.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ] : null,
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.iconData,
                    color: widget.iconColor,
                    size: UIConstants.timedToggleButtonIconSize,
                  ),
                  const SizedBox(width: 4),
                  if (isLightOn && timeLeft.isNotEmpty)
                    Text(
                      timeLeft,
                      style: TextStyle(
                        fontSize: UIConstants.countdownTimerTextSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bleState = context.watch<BleBloc>().state;
    final isConnected = widget.necklace.bleDevice != null && 
        bleState.deviceConnectionStates[widget.necklace.bleDevice!.id] == true;
    
    if (isConnected != widget.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // This will trigger a rebuild with the updated connection status
        });
      });
    }
  }

  Widget _buildErrorButton({required String message, required Widget child}) {
    return Tooltip(
      message: message,
      child: Container(
        width: widget.buttonWidth,
        height: widget.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Center(child: child),
      ),
    );
  }

  Future<BleState> _handleDisconnectedState(BuildContext context) async {
    final logger = LoggingService.instance;
    logger.logDebug('Device not connected - attempting reconnection');

    bool isReconnected = false;
    int attemptCount = 0;
    const maxAttempts = 3;

    while (!isReconnected && attemptCount < maxAttempts) {
      attemptCount++;
      logger.logDebug('Reconnection attempt $attemptCount of $maxAttempts');

      // Show reconnection indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnecting to device... (Attempt $attemptCount/$maxAttempts)'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Start scanning for devices
      context.read<BleBloc>().add(BleStartScanning());

      // Wait for connection with timeout
      final bleState = await context.read<BleBloc>().stream
          .firstWhere((state) => state.deviceConnectionStates[widget.necklace.bleDevice!.id] == true)
          .timeout(const Duration(seconds: 5), onTimeout: () => BleState.initial());
      if (bleState != null) {
        isReconnected = true;
        context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
        return bleState; // Return the valid BleState
      }
    }

    if (!isReconnected) {
      logger.logError('Failed to reconnect to device after $maxAttempts attempts');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reconnect to device'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return Future.error('Failed to reconnect to device'); // Return an error if reconnection fails
  }
}
