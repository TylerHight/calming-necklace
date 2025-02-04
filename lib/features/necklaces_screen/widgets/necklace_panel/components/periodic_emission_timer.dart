import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/periodic_emission/periodic_emission_bloc.dart';
import '../../../../../core/ui/ui_constants.dart';
import '../../../../../core/ui/formatters.dart';

class PeriodicEmissionTimer extends StatelessWidget {
  const PeriodicEmissionTimer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeriodicEmissionBloc, PeriodicEmissionState>(
      builder: (context, state) {
        if (state is PeriodicEmissionRunning) {
          final progress = 1 - (state.intervalSecondsLeft / state.totalInterval);
          return Container(
            padding: EdgeInsets.all(UIConstants.periodicTimerPadding),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: UIConstants.periodicTimerSize,
                  height: UIConstants.periodicTimerSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: UIConstants.periodicTimerBackgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      state.isPaused ? UIConstants.periodicTimerPausedColor : UIConstants.periodicTimerActiveColor,
                    ),
                    strokeWidth: UIConstants.periodicTimerStrokeWidth,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatDuration(Duration(seconds: state.intervalSecondsLeft)),
                      style: TextStyle(
                        fontSize: UIConstants.periodicTimerTimeTextSize,
                        fontWeight: UIConstants.periodicTimerTimeFontWeight,
                        color: state.isPaused ? UIConstants.periodicTimerPausedColor : UIConstants.periodicTimerActiveColor,
                      ),
                    ),
                    SizedBox(height: UIConstants.periodicTimerSpacing),
                    Text(
                      state.isPaused ? 'Paused' : 'Until Next',
                      style: TextStyle(
                        fontSize: UIConstants.periodicTimerStatusTextSize,
                        color: UIConstants.periodicTimerStatusColor,
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
