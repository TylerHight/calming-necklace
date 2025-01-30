import 'package:flutter/material.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/services.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration initialDuration;
  final String title;
  final bool isEmissionDuration;
  final Function(Duration) onDurationChanged;

  const DurationPickerDialog({
    Key? key,
    required this.initialDuration,
    required this.title,
    required this.isEmissionDuration,
    required this.onDurationChanged,
  }) : super(key: key);

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late Duration _duration;
  final Color _accentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 280,
                width: 280,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: _accentColor,
                      secondary: _accentColor.withOpacity(0.5),
                    ),
                  ),
                  child: DurationPicker(
                    duration: _duration,
                    onChange: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _duration = val;
                        widget.onDurationChanged(_duration);
                      });
                    },
                    snapToMins: widget.isEmissionDuration ? 0.0 : 1.0,
                    baseUnit: widget.isEmissionDuration ? BaseUnit.second : BaseUnit.minute,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_duration.inSeconds > 0) {
                        Navigator.of(context).pop(_duration);
                      } else {
                        const SnackBar(content: Text('Please select a duration greater than 0'));
                      }
                    },
                    child: const Text('Set Duration'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
