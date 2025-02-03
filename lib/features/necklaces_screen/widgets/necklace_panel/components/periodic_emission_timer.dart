import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/periodic_emission/periodic_emission_bloc.dart';
import '../../../../../core/ui/formatters.dart';

class PeriodicEmissionTimer extends StatelessWidget {
  const PeriodicEmissionTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodicEmissionBloc, PeriodicEmissionState>(
      builder: (context, state) {
        if (state is PeriodicEmissionRunning) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Next emission in: ${formatDuration(Duration(seconds: state.intervalSecondsLeft))}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
