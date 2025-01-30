import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../../core/ui/ui_constants.dart';
import '../blocs/duration_picker/duration_picker_bloc.dart';

class DurationPickerDialog extends StatelessWidget {
  final String title;
  final Duration initialDuration;
  final bool isEmissionDuration;
  final Function(Duration) onDurationChanged;

  const DurationPickerDialog({
    Key? key,
    required this.title,
    required this.initialDuration,
    required this.isEmissionDuration,
    required this.onDurationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DurationPickerBloc()
        ..add(UpdateHours(initialDuration.inHours))
        ..add(UpdateMinutes(initialDuration.inMinutes % 60))
        ..add(UpdateSeconds(initialDuration.inSeconds % 60)),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.durationPickerDialogRadius),
        ),
        child: Container(
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
              SizedBox(
                height: UIConstants.durationPickerHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNumberPicker(
                      context,
                      0,
                      23,
                      initialDuration.inHours,
                      (value) => context.read<DurationPickerBloc>().add(UpdateHours(value)),
                      'Hours',
                    ),
                    _buildSeparator(),
                    _buildNumberPicker(
                      context,
                      0,
                      59,
                      initialDuration.inMinutes % 60,
                      (value) => context.read<DurationPickerBloc>().add(UpdateMinutes(value)),
                      'Minutes',
                    ),
                    _buildSeparator(),
                    _buildNumberPicker(
                      context,
                      0,
                      59,
                      initialDuration.inSeconds % 60,
                      (value) => context.read<DurationPickerBloc>().add(UpdateSeconds(value)),
                      'Seconds',
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
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<DurationPickerBloc, DurationPickerState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: () {
                          onDurationChanged(state.duration);
                          Navigator.pop(context);
                        },
                        child: const Text('Set'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: UIConstants.durationPickerColumnWidth,
          child: NumberPicker(
            value: initialValue,
            minValue: minValue,
            maxValue: maxValue,
            itemHeight: UIConstants.durationPickerItemExtent,
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
