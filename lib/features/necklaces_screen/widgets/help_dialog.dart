import 'package:flutter/material.dart';

class NecklacesHelpDialog extends StatelessWidget {
  const NecklacesHelpDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'How to use Necklaces',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildHelpItem(
              Icons.spa_outlined,
              'Emission Controls',
              'Use the buttons to control scent emission. Each necklace has two emission options.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.timer_outlined,
              'Timed Release',
              'Emissions can be set to automatically turn off after a set duration.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.settings_outlined,
              'Settings',
              'Access device settings through the menu to customize emission durations and intervals.',
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
