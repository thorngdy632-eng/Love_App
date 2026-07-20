import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/romantic_card.dart';
import '../../data/models/memory_model.dart';
import '../../data/repositories/memories_repository.dart';
import '../auth/auth_provider.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final MemoriesRepository _memoriesRepo = MemoriesRepository();
  final ImagePicker _picker = ImagePicker();

  Future<void> _openAddMemory() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 1280);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final ext = picked.path.split('.').last;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    if (!mounted) return;

    await showModalBottomSheet(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(bytes, height: 160, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                CustomTextField(controller: titleController, hint: KhmerText.notesHintTitle, prefixIcon: Icons.title),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: descController,
                  hint: KhmerText.notesHintContent,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: sheetContext,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setSheetState(() => selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: KhmerText.save,
                  isLoading: saving,
                  onPressed: () async {
                    setSheetState(() => saving = true);
                    await _memoriesRepo.addMemory(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      imageBytes: bytes,
                      imageExtension: ext,
                      memoryDate: selectedDate,
                      authorId: user.uid,
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.memoriesTitle)),
      floatingActionButton: FloatingActionButton(onPressed: _openAddMemory, child: const Icon(Icons.add_a_photo_outlined)),
      body: StreamBuilder<List<MemoryModel>>(
        stream: _memoriesRepo.memoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
          final memories = snapshot.data ?? [];
          if (memories.isEmpty) return const EmptyStateWidget(message: KhmerText.memoriesEmpty, icon: Icons.photo_album_outlined);

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: memories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final memory = memories[index];
              return RomanticCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        base64Decode(memory.imageUrl),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (memory.title.isNotEmpty)
                      Text(memory.title, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 16, color: AppColors.textDark)),
                    if (memory.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(memory.description, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM/yyyy').format(memory.memoryDate),
                          style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 12, color: AppColors.textLight),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          onPressed: () async {
                            try {
                              await _memoriesRepo.deleteMemory(memory.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${KhmerText.error}: $e')),
                                );
                              }
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
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
