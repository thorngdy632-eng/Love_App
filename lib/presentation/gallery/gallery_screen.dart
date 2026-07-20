import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_download.dart';
import '../../core/widgets/romantic_card.dart' show LoadingWidget, EmptyStateWidget;
import '../../data/models/gallery_photo_model.dart';
import '../../data/repositories/gallery_repository.dart';
import '../auth/auth_provider.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final GalleryRepository _galleryRepo = GalleryRepository();
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _addPhotos() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final picked = await _picker.pickMultiImage(imageQuality: 65, maxWidth: 1280);
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    int success = 0;
    for (final xFile in picked) {
      try {
        final bytes = await xFile.readAsBytes();
        final ext = xFile.path.split('.').last;
        await _galleryRepo.addPhoto(imageBytes: bytes, uploaderId: user.uid, imageExtension: ext);
        success++;
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${KhmerText.error}: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(KhmerText.messageSendImageFail)),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('បានបន្ថែម $success រូបភាព')),
      );
    }
  }

  void _openViewer(Uint8List bytes, String photoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await downloadImageBytes(bytes, 'love_app_$photoId.jpg');
                  messenger.showSnackBar(
                    const SnackBar(content: Text('បានទាញយករួចរាល់')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () => _confirmDelete(photoId),
              ),
            ],
          ),
          body: PhotoView(imageProvider: MemoryImage(bytes)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.galleryTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _addPhotos,
        child: _uploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: StreamBuilder<List<GalleryPhotoModel>>(
        stream: _galleryRepo.galleryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingWidget();
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) return const EmptyStateWidget(message: KhmerText.galleryEmpty, icon: Icons.collections_outlined);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
                return GestureDetector(
                  onTap: () => _openViewer(base64Decode(photo.imageUrl), photo.id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(base64Decode(photo.imageUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.textLight)),
                  ),
                );
            },
          );
        },
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
              try {
                await _galleryRepo.deletePhoto(id);
                if (mounted) Navigator.maybePop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), duration: const Duration(seconds: 5)),
                  );
                }
              }
            },
            child: const Text(KhmerText.delete, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
