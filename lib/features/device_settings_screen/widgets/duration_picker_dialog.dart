import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../../core/ui/ui_constants.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/services/database_service.dart';
import '../blocs/duration_picker/duration_picker_bloc.dart';

class DurationPickerDialog extends StatelessWidget {
  final String title;
  final Duration initialDuration;
  final bool isEmissionDuration;
  final Function(Duration) onDurationChanged;
  final LoggingService _logger;
  final DatabaseService _databaseService;
  final Duration defaultDuration;
  final String necklaceId;
  final int scentNumber;

  DurationPickerDialog({
    Key? key,
    required this.title,
    required this.initialDuration,
    required this.isEmissionDuration,
    required this.onDurationChanged,
    required this.necklaceId,
    required this.scentNumber,
    DatabaseService? databaseService,
    this.defaultDuration = const Duration(seconds: 10),
  }) : _logger = LoggingService.instance, _databaseService = databaseService ?? DatabaseService(), super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DurationPickerBloc()
        ..add(UpdateHours(initialDuration.inHours))
        ..add(UpdateMinutes(initialDuration.inMinutes % 60))
        ..add(UpdateSeconds(initialDuration.inSeconds % 60)),
      child: BlocBuilder<DurationPickerBloc, DurationPickerState>(
        builder: (context, state) {
          return _buildDialog(context, state);
        },
      ),
    );
  }

  Widget _buildDialog(BuildContext context, DurationPickerState state) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.durationPickerDialogRadius),
      ),
      content: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: UIConstants.durationPickerSpacing / 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.durationPickerSpacing),
            if (!isEmissionDuration) SizedBox(
              height: UIConstants.durationPickerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildNumberPicker(
                      context,
                      0,
                      23,
                      state.hours,
                          (value) => context.read<DurationPickerBloc>().add(UpdateHours(value)),
                      'Hours',
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildNumberPicker(
                      context,
                      0,
                      59,
                      state.minutes,
                          (value) => context.read<DurationPickerBloc>().add(UpdateMinutes(value)),
                      'Minutes',
                    ),
                  ),
                  _buildSeparator(),
                  Expanded(
                    child: _buildNumberPicker(
                      context,
                      0,
                      59,
                      state.seconds,
                          (value) => context.read<DurationPickerBloc>().add(UpdateSeconds(value)),
                      'Seconds',
                    ),
                  ),
                ],
              ),
            ),
            if (isEmissionDuration) SizedBox(
              height: UIConstants.durationPickerHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildNumberPicker(
                      context, 0, 59, state.seconds,
                      (value) => context.read<DurationPickerBloc>().add(UpdateSeconds(value)),
                      'Seconds',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: UIConstants.durationPickerSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final newDuration = Duration(
                        hours: state.hours,
                        minutes: state.minutes,
                        seconds: state.seconds,
                      );
                      // Save to database
                      final settingKey = isEmissionDuration
                          ? 'emission${scentNumber}Duration'
                          : 'releaseInterval${scentNumber}';
                      await _databaseService.updateNecklaceSettings(
                        necklaceId,
                        {settingKey: newDuration.inSeconds},
                      );
                      onDurationChanged(newDuration);
                      LoggingService.instance.logDebug('Successfully saved duration: $newDuration');
                    } catch (e) {
                      LoggingService.instance.logError('Error updating duration: $e');
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker(
      BuildContext context,
      int minValue,
      int maxValue,
      int initialValue,
      Function(int) onChanged,
      String label,
      ) {
    _logger.logDebug('Building NumberPicker with initial value: $initialValue');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: UIConstants.durationPickerColumnWidth,
          child: NumberPicker(
            value: initialValue,
            minValue: minValue,
            maxValue: maxValue,
            step: 1,
            itemHeight: UIConstants.durationPickerItemExtent,
            haptics: true,
            textStyle: TextStyle(
              fontSize: UIConstants.durationPickerFontSize,
            ),
            selectedTextStyle: TextStyle(
              fontSize: UIConstants.durationPickerFontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onChanged(value);
            },
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: UIConstants.durationPickerSeparatorWidth,
      height: UIConstants.durationPickerHeight * 0.6,
      color: UIConstants.durationPickerSeparatorColor.withOpacity(0.3),
    );
  }
}
