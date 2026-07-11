import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/services/firebase_service.dart';
import '../../models/session_note.dart';
import '../../repositories/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return FirebaseService.instance.isInitialized ? NotesRepositoryImpl() : MockNotesRepository.instance;
});

final notesProvider = StreamProvider<List<SessionNote>>((ref) {
  return ref.watch(notesRepositoryProvider).watchNotes();
});

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _editingId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_editingId == null) {
        await ref.read(notesRepositoryProvider).addNote(
          title: _titleController.text,
          description: _descriptionController.text,
        );
      } else {
        await ref.read(notesRepositoryProvider).updateNote(
          noteId: _editingId!,
          title: _titleController.text,
          description: _descriptionController.text,
        );
      }
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _editingId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _startEdit(SessionNote note) {
    _titleController.text = note.title;
    _descriptionController.text = note.description;
    setState(() => _editingId = note.id);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Notes')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notesProvider),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Enter a description' : null,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_editingId == null ? 'Save Note' : 'Update Note'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) {
                    return const Center(child: Text('No session notes yet.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(note.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(note.description),
                              const SizedBox(height: 6),
                              Text(DateFormat('MMM dd, yyyy').format(note.createdAt)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(onPressed: () => _startEdit(note), icon: const Icon(Icons.edit_outlined)),
                              IconButton(
                                onPressed: () async {
                                  await ref.read(notesRepositoryProvider).deleteNote(noteId: note.id);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
