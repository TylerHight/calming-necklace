import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/note.dart';
import '../../../core/data/repositories/necklace_repository.dart';
import '../bloc/notes_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/ui/ui_constants.dart';

class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({
    Key? key,
    required this.note,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        color: Colors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      onDismissed: (direction) {
        context.read<NotesBloc>().add(DeleteNote(note.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, y h:mm a').format(note.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (note.deviceId != null)
                    FutureBuilder<String>(
                      future: context.read<NecklaceRepository>().getDeviceNameById(note.deviceId!),
                      builder: (context, snapshot) {
                        final deviceName = snapshot.data ?? 'Unknown Device';
                        return Text(
                          'Necklace: $deviceName',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
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
}
