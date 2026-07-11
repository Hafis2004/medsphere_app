import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/exceptions.dart';
import '../models/session_note.dart';

abstract class NotesRepository {
  Stream<List<SessionNote>> watchNotes();
  Future<void> addNote({required String title, required String description});
  Future<void> updateNote({required String noteId, required String title, required String description});
  Future<void> deleteNote({required String noteId});
}

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<SessionNote>> watchNotes() {
    return _firestore.collection('session_notes').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SessionNote.fromJson({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Future<void> addNote({required String title, required String description}) async {
    try {
      await _firestore.collection('session_notes').add({
        'title': title.trim(),
        'description': description.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw FirestoreException('Unable to save note.');
    }
  }

  @override
  Future<void> updateNote({required String noteId, required String title, required String description}) async {
    try {
      await _firestore.collection('session_notes').doc(noteId).update({
        'title': title.trim(),
        'description': description.trim(),
      });
    } catch (e) {
      throw FirestoreException('Unable to update note.');
    }
  }

  @override
  Future<void> deleteNote({required String noteId}) async {
    try {
      await _firestore.collection('session_notes').doc(noteId).delete();
    } catch (e) {
      throw FirestoreException('Unable to delete note.');
    }
  }
}

class MockNotesRepository implements NotesRepository {
  MockNotesRepository._();
  static final MockNotesRepository instance = MockNotesRepository._();

  final List<SessionNote> _notes = [];

  final _controller = StreamController<List<SessionNote>>.broadcast();

  @override
  Stream<List<SessionNote>> watchNotes() async* {
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield List.unmodifiable(_notes);
    yield* _controller.stream;
  }

  @override
  Future<void> addNote({required String title, required String description}) async {
    final note = SessionNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    _notes.add(note);
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(List.unmodifiable(_notes));
  }

  @override
  Future<void> updateNote({required String noteId, required String title, required String description}) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final old = _notes[index];
      _notes[index] = SessionNote(
        id: old.id,
        title: title.trim(),
        description: description.trim(),
        createdAt: old.createdAt,
      );
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _controller.add(List.unmodifiable(_notes));
    } else {
      throw const FirestoreException('Note not found.');
    }
  }

  @override
  Future<void> deleteNote({required String noteId}) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      _notes.removeAt(index);
      _controller.add(List.unmodifiable(_notes));
    } else {
      throw const FirestoreException('Note not found.');
    }
  }
}
