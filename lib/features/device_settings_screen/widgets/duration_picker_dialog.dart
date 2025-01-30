import 'package:flutter/material.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration initialDuration;
  final String title;
  final Color accentColor;

  const DurationPickerDialog({
    Key? key,
    required this.initialDuration,
    required this.title,
    this.accentColor = Colors.blue,
  }) : super(key: key);

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int minutes;
  late int seconds;

  @override
  void initState() {
    super.initState();
    minutes = widget.initialDuration.inMinutes;
    seconds = widget.initialDuration.inSeconds % 60;
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
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: widget.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumberPicker(
                    value: minutes,
                    maxValue: 59,
                    label: 'Minutes',
                    onChanged: (value) => setState(() => minutes = value),
                  ),
                  const SizedBox(width: 16),
                  _buildNumberPicker(
                    value: seconds,
                    maxValue: 59,
                    label: 'Seconds',
                    onChanged: (value) => setState(() => seconds = value),
                  ),
                ],
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
                      Navigator.of(context).pop(
                        Duration(minutes: minutes, seconds: seconds),
                      );
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int maxValue,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        SizedBox(
          width: 64,
          child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: value.toString()),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (text) {
              final newValue = int.tryParse(text) ?? 0;
              if (newValue >= 0 && newValue <= maxValue) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
