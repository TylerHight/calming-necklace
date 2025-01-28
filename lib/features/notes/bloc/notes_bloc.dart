import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/models/note.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/logging_service.dart';

// Events
abstract class NotesEvent {}

class LoadNotes extends NotesEvent {}
class AddNote extends NotesEvent {
  final Note note;
  AddNote(this.note);
}
class DeleteNote extends NotesEvent {
  final String noteId;
  DeleteNote(this.noteId);
}
class FilterNotes extends NotesEvent {
  final String? deviceId;
  FilterNotes(this.deviceId);
}

// States
abstract class NotesState {}

class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}
class NotesLoaded extends NotesState {
  final List<Note> notes;
  NotesLoaded(this.notes);
}
class NotesError extends NotesState {
  final String message;
  NotesError(this.message);
}

// Bloc
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final DatabaseService _databaseService;

  NotesBloc(this._databaseService) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    add(LoadNotes()); // Load notes when bloc is created
    on<DeleteNote>(_onDeleteNote);
    on<FilterNotes>(_onFilterNotes);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    emit(NotesLoading());
    LoggingService().logDebug('Loading notes from database');
    try {
      final notes = await _databaseService.getNotes();
      if (notes.isEmpty) {
        LoggingService().logDebug('No notes found in database');
        emit(NotesLoaded([]));
      } else {
        emit(NotesLoaded(notes));
      }
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onAddNote(AddNote event, Emitter<NotesState> emit) async {
    try {
      LoggingService().logDebug('Adding note: ${event.note}');
      await _databaseService.insertNote(event.note);
      add(LoadNotes());
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      LoggingService().logDebug('Deleting note with id: ${event.noteId}');
      await _databaseService.deleteNote(event.noteId);
      add(LoadNotes());
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onFilterNotes(FilterNotes event, Emitter<NotesState> emit) async {
    try {
      LoggingService().logDebug('Retrieving notes by device: ${event.deviceId}');
      final notes = await _databaseService.getNotesByDevice(event.deviceId);
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }
}
