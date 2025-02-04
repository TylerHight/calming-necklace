import 'package:flutter/material.dart';

class SettingsHelpDialog extends StatelessWidget {
  const SettingsHelpDialog({Key? key}) : super(key: key);

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
                  'Device Settings Help',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildHelpItem(
              Icons.edit_outlined,
              'Device Name',
              'Change the name of your necklace for easy identification.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.timer_outlined,
              'Scent Release Settings',
              'Configure emission duration and interval for automatic scent release.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.bluetooth_outlined,
              'Connection Settings',
              'Manage connected devices including necklace and heart rate monitor.',
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.warning_amber_outlined,
              'Danger Zone',
              'Options for device deletion and archiving. Use with caution.',
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
