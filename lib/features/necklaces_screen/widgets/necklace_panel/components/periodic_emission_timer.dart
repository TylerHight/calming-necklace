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
          final progress = state.intervalSecondsLeft / state.totalInterval;
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isPaused ? Colors.orange : Colors.blue,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatDuration(Duration(seconds: state.intervalSecondsLeft)),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.isPaused ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isPaused ? 'Paused' : 'Until Next',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
