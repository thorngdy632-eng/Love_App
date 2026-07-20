import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_cache.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/romantic_card.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bioController = TextEditingController();
  bool _editingBio = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto(String uid) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last;
      await _profileRepo.updateProfileImage(uid: uid, imageBytes: bytes, imageExtension: ext);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${KhmerText.error}: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('មិនអាចប្តូររូបភាពបានទេ សូមព្យាយាមម្តងទៀត')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveBio(String uid) async {
    setState(() => _saving = true);
    try {
      await _profileRepo.updateBio(uid: uid, bio: _bioController.text.trim());
      if (mounted) {
        setState(() => _editingBio = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(KhmerText.profileSaved)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    if (authUser == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.profileTitle)),
      body: StreamBuilder<UserModel?>(
        stream: _profileRepo.watchUser(authUser.uid),
        builder: (context, snapshot) {
          final user = snapshot.data ?? authUser;
          if (!_editingBio && user.bio != _bioController.text) _bioController.text = user.bio;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? cachedMemoryImage(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : () => _changePhoto(user.uid),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(user.name, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 20, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight)),
                const SizedBox(height: 24),
                RomanticCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            KhmerText.profileBio,
                            style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 15, color: AppColors.textDark),
                          ),
                          IconButton(
                            icon: Icon(_editingBio ? Icons.close : Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => setState(() => _editingBio = !_editingBio),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_editingBio) ...[
                        TextField(
                          controller: _bioController,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'KantumruyPro'),
                          decoration: const InputDecoration(hintText: KhmerText.profileBioHint),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          label: KhmerText.save,
                          isLoading: _saving,
                          onPressed: () => _saveBio(user.uid),
                          height: 46,
                        ),
                      ] else
                        Text(
                          user.bio.isEmpty ? KhmerText.profileBioHint : user.bio,
                          style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight, fontSize: 14),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RomanticCard(
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.badge_outlined, label: KhmerText.profileName, value: user.name),
                      const Divider(height: 24),
                      _InfoRow(icon: Icons.phone_outlined, label: KhmerText.profilePhone, value: user.phone),
                      const Divider(height: 24),
                      _InfoRow(icon: Icons.email_outlined, label: KhmerText.profileEmail, value: user.email),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 14, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}
