import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/romantic_card.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../auth/auth_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesRepository _notesRepo = NotesRepository();

  void _openNoteEditor({NoteModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                CustomTextField(controller: titleController, hint: KhmerText.notesHintTitle, prefixIcon: Icons.title),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: contentController,
                  hint: KhmerText.notesHintContent,
                  maxLines: 5,
                  prefixIcon: Icons.notes,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: KhmerText.save,
                  isLoading: saving,
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty && contentController.text.trim().isEmpty) return;
                    setSheetState(() => saving = true);
                    try {
                      if (existing == null) {
                        await _notesRepo.addNote(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          authorId: user.uid,
                          authorName: user.name,
                        );
                      } else {
                        await _notesRepo.updateNote(
                          id: existing.id,
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          authorId: user.uid,
                          authorName: user.name,
                        );
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    } catch (e) {
                      setSheetState(() => saving = false);
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(content: Text('${KhmerText.error}: $e')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(KhmerText.delete, style: TextStyle(fontFamily: 'KantumruyPro')),
        content: const Text(KhmerText.areYouSure, style: TextStyle(fontFamily: 'KantumruyPro')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(KhmerText.cancel, style: TextStyle(fontFamily: 'KantumruyPro')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _notesRepo.deleteNote(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(KhmerText.notesDeleted)));
              }
            },
            child: const Text(KhmerText.delete, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.notesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: _notesRepo.notesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) return const EmptyStateWidget(message: KhmerText.notesEmpty, icon: Icons.note_alt_outlined);

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notes[index];
              return RomanticCard(
                onTap: () => _openNoteEditor(existing: note),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (note.title.isNotEmpty)
                            Text(
                              note.title,
                              style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 16, color: AppColors.textDark),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 14, color: AppColors.textLight),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${note.authorName} • ${DateFormat('dd/MM/yyyy HH:mm').format(note.updatedAt)}',
                            style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      onPressed: () => _confirmDelete(note.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
