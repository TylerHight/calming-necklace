import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/periodic_emission/periodic_emission_bloc.dart';
import '../../../../../core/ui/ui_constants.dart';

class PeriodicEmissionTimer extends StatelessWidget {
  const PeriodicEmissionTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodicEmissionBloc, PeriodicEmissionState>(
      builder: (context, state) {
        if (state is! PeriodicEmissionRunning) {
          return const SizedBox.shrink();
        }

        final bool isActive = state is PeriodicEmissionRunning;
        return Container(
          margin: const EdgeInsets.only(right: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: isActive ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(state.intervalSecondsLeft),
                style: const TextStyle(
                  fontSize: UIConstants.countdownTimerTextSize - 2,
                  color: Colors.grey,
                ),
              ),
            ],
          ) : const SizedBox.shrink(),
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
