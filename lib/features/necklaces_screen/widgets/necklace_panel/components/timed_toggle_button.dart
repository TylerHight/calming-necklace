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
        if (state is LightOffState) {
          setState(() {
            _lastTapTime = null;
          });
        }

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
          return _buildButtonWithOverlay(
            context,
            isLightOn: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.iconData,
                  color: widget.iconColor?.withOpacity(0.3),
                  size: UIConstants.timedToggleButtonIconSize,
                ),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
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
              
              try {
                // Show loading state
                context.read<TimedToggleButtonBloc>().add(
                  ToggleLightLoadingEvent(),
                );
                await Future.delayed(Duration(milliseconds: 100)); // Allow UI to update

                // Ensure proper state before toggling light
                await _ensureProperState(context, shouldTurnOn);

                // Attempt to toggle light
                final bleBloc = context.read<BleBloc>();
                final success = await bleBloc.toggleLight(
                  widget.necklace.bleDevice!.id,
                  shouldTurnOn,
                );

                if (success) {
                  context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
                } else {
                  throw Exception('Failed to toggle light');
                }
              } catch (e) {
                context.read<TimedToggleButtonBloc>().add(
                  ToggleLightErrorEvent(e.toString()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to send last command. '
                        'Ensure that device is in range and powered on'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
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
    _checkConnectionStatus();
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

  Widget _buildButtonWithOverlay(
    BuildContext context,
    {required bool isLightOn,
    required Widget child}
  ) {
    return Container(
      width: UIConstants.timedToggleButtonWidth,
      height: UIConstants.timedToggleButtonHeight,
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
      ),
      child: child,
    );
  }

  Future<BleState> _handleDisconnectedState(BuildContext context) async {
    final logger = LoggingService.instance;
    logger.logDebug('Device not connected - attempting reconnection');

    bool isReconnected = false;
    int attemptCount = 0;
    const maxAttempts = 3;
    const scanTimeout = Duration(seconds: 5);

    while (!isReconnected && attemptCount < maxAttempts) {
      attemptCount++;
      logger.logDebug('Reconnection attempt $attemptCount of $maxAttempts');

      // Update UI with reconnection status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnecting to device... (Attempt $attemptCount/$maxAttempts)'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Start scanning with specific device filter
      context.read<BleBloc>().add(BleStartScanning());
      
      try {
        // Wait for scan results
        final targetDeviceId = widget.necklace.bleDevice!.id;
        final bleState = await context.read<BleBloc>().stream
            .where((state) => state.isScanning)
            .timeout(scanTimeout)
            .firstWhere((state) {
              final hasDevice = state.deviceConnectionStates.containsKey(targetDeviceId);
              logger.logDebug('Scanning - Found device: $hasDevice');
              return hasDevice;
            });

        // Attempt connection if device found
        if (bleState.deviceConnectionStates.containsKey(targetDeviceId)) {
          logger.logDebug('Device found, attempting connection');
          
          // Attempt to connect to the found device
          context.read<BleBloc>().add(BleConnectRequest(widget.necklace.bleDevice!));
          
          // Wait for connection confirmation
          final connectedState = await context.read<BleBloc>().stream
              .timeout(const Duration(seconds: 5))
              .firstWhere((state) => 
                  state.deviceConnectionStates[targetDeviceId] == true);
          
          if (connectedState.deviceConnectionStates[targetDeviceId] == true) {
            isReconnected = true;
            logger.logDebug('Successfully reconnected to device');
            context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
            return connectedState;
          }
        }
      } catch (e) {
        logger.logError('Error during reconnection attempt $attemptCount: $e');
        await Future.delayed(Duration(milliseconds: 500 * attemptCount));
        continue;
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

  void _checkConnectionStatus() {
    final bleState = context.read<BleBloc>().state;
    final isConnected = widget.necklace.bleDevice != null && 
        bleState.deviceConnectionStates[widget.necklace.bleDevice!.id] == true;
    
    if (!isConnected && context.read<TimedToggleButtonBloc>().state is LightOnState) {
      context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
    }
  }

  Future<void> _ensureProperState(BuildContext context, bool desiredState) async {
    final bloc = context.read<TimedToggleButtonBloc>();
    final currentState = bloc.state;
    
    if (currentState is LightOnState && !desiredState) {
      // If we're turning off, make sure to clean up the timer
      bloc.add(ToggleLightEvent());
    } else if (currentState is LightOffState && desiredState) {
      // If we're turning on, make sure we're in a clean state
      if (bloc.state is! TimedToggleButtonLoading) {
        bloc.add(ToggleLightLoadingEvent());
      }
    }
  }
}
