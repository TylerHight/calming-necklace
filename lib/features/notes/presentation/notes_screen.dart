import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../../../core/data/models/note.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/note_card.dart';
import '../widgets/help_dialog.dart';
import '../../../core/services/logging_service.dart';
import '../../../core/ui/ui_constants.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    // Load notes immediately when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<NotesBloc>(context).add(LoadNotes());
    });
  }

  @override
  Widget build(BuildContext context) {
    LoggingService().logDebug('Building NotesScreen');
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        shape: const CircleBorder(),
        backgroundColor: UIConstants.floatingActionButtonColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: UIConstants.appBarGradientColors,
            ),
          ),
        ),
        title: const Text(
          'Notes',
          style: TextStyle(color: UIConstants.appBarTitleColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            color: Colors.white,
            onPressed: () {
              showDialog(context: context, builder: (context) => const NotesHelpDialog());
            },
          ),
        ],
      ),
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotesLoaded) {
            LoggingService().logDebug('Notes loaded: ${state.notes}');
            return _buildNotesList(context, state.notes);
          } else if (state is NotesError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildNotesList(BuildContext context, List<Note> notes) {
    if (notes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: notes.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: NoteCard(note: notes[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_add,
              size: 48,
              color: Colors.blue[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notes added yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the "Add Note" button above to create your first note.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    LoggingService().logDebug('Showing AddNoteDialog');
    showDialog(
      context: context,
      builder: (context) => const AddNoteDialog(),
    );
  }
}
