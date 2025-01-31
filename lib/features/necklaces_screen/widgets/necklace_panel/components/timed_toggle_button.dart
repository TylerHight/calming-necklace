import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calming_necklace/features/necklaces_screen/blocs/timed_toggle_button/timed_toggle_button_bloc.dart';
import '../../../../../core/data/models/necklace.dart';
import '../../../../../core/data/repositories/necklace_repository.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/services/database_service.dart';
import '../../../../../core/ui/ui_constants.dart';

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
        buttonSize: buttonHeight,
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
  final double buttonSize;
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
    required this.buttonSize,
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
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _refreshDuration();
  }

  Future<void> _refreshDuration() async {
    try {
      final updatedNecklace = await widget.databaseService.getNecklaceById(widget.necklace.id);
      if (updatedNecklace != null && mounted) {
        setState(() {
          _duration = updatedNecklace.emission1Duration;
        });
      }
    } catch (e) {
      LoggingService().logError('Error refreshing duration: $e');
    }
  }

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
        final logger = LoggingService();
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
        String timeLeft = isLightOn ? _formatTime((state).secondsLeft) : '';
        
        logger.logDebug('Building TimedToggleButton: isLightOn: $isLightOn, timeLeft: $timeLeft');

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!widget.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device not connected')),
                );
                return;
              }
              context.read<TimedToggleButtonBloc>().add(ToggleLightEvent());
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
                    color: widget.activeColor!.withOpacity(0.4),
                    blurRadius: UIConstants.timedToggleButtonBoxShadowBlurRadius,
                    offset: UIConstants.timedToggleButtonBoxShadowOffset,
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
}
