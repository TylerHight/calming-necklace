import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/logging_service.dart';

class HeartRateSettingsDialog extends StatefulWidget {
  final String necklaceId;
  final int initialHighThreshold;
  final int initialLowThreshold;

  const HeartRateSettingsDialog({
    Key? key,
    required this.necklaceId,
    required this.initialHighThreshold,
    required this.initialLowThreshold,
  }) : super(key: key);

  @override
  State<HeartRateSettingsDialog> createState() => _HeartRateSettingsDialogState();
}

class _HeartRateSettingsDialogState extends State<HeartRateSettingsDialog> {
  late double _highThreshold;
  late double _lowThreshold;
  final DatabaseService _databaseService = DatabaseService();
  final LoggingService _logger = LoggingService.instance;

  @override
  void initState() {
    super.initState();
    _highThreshold = widget.initialHighThreshold.toDouble();
    _lowThreshold = widget.initialLowThreshold.toDouble();
  }

  Future<void> _saveSettings() async {
    try {
      await _databaseService.updateNecklaceSettings(
        widget.necklaceId,
        {
          'highHeartRateThreshold': _highThreshold.round(),
          'lowHeartRateThreshold': _lowThreshold.round(),
        },
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.logError('Error saving heart rate settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Heart Rate Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text('High Heart Rate Threshold: ${_highThreshold.round()} BPM'),
          Slider(
            value: _highThreshold,
            min: 30,
            max: 200,
            divisions: 170,
            label: '${_highThreshold.round()} BPM',
            onChanged: (value) {
              setState(() {
                if (value > _lowThreshold) {
                  _highThreshold = value;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Text('Low Heart Rate Threshold: ${_lowThreshold.round()} BPM'),
          Slider(
            value: _lowThreshold,
            min: 30,
            max: 200,
            divisions: 170,
            label: '${_lowThreshold.round()} BPM',
            onChanged: (value) {
              setState(() {
                if (value < _highThreshold) {
                  _lowThreshold = value;
                }
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
