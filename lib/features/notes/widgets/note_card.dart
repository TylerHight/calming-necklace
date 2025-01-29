import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/note.dart';
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
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: UIConstants.noteCardDeviceTagPadding),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        context.read<NotesBloc>().add(DeleteNote(note.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: UIConstants.noteCardMargin),
        child: Padding(
          padding: EdgeInsets.all(UIConstants.noteCardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: UIConstants.noteCardContentTextSize,
                ),
              ),
              SizedBox(height: UIConstants.noteCardSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (note.deviceId != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: UIConstants.noteCardDeviceTagPadding,
                        vertical: UIConstants.noteCardDeviceTagVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          UIConstants.noteCardDeviceTagBorderRadius,
                        ),
                      ),
                      child: Text(
                        'Device: ${note.deviceId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: UIConstants.noteCardMetadataTextSize,
                        ),
                      ),
                    ),
                  Text(
                    DateFormat('MMM d, y h:mm a').format(note.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
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
