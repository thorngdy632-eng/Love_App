import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/romantic_card.dart';
import '../auth/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _loadingPrefs = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  void _toggleDarkMode(bool value) {
    context.read<ThemeProvider>().setDarkMode(value);
  }

  void _openChangePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
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
                Text(
                  KhmerText.settingsChangePassword,
                  style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 18, color: AppColors.textDark),
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  controller: currentController,
                  hint: 'ពាក្យសម្ងាត់បច្ចុប្បន្ន',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: newController,
                  hint: 'ពាក្យសម្ងាត់ថ្មី',
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (newController.text.trim().length < 6) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('ពាក្យសម្ងាត់ត្រូវមានយ៉ាងតិច ៦ តួអក្សរ')),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              final email = user?.email;
                              if (user != null && email != null) {
                                final cred = EmailAuthProvider.credential(
                                  email: email,
                                  password: currentController.text,
                                );
                                await user.reauthenticateWithCredential(cred);
                                await user.updatePassword(newController.text.trim());
                              } else {
                                setSheetState(() => saving = false);
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('មិនអាចកំណត់អត្តសញ្ញាណអ្នកប្រើបានទេ')),
                                  );
                                }
                                return;
                              }
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text(KhmerText.success)),
                                );
                              }
                            } on FirebaseAuthException catch (_) {
                              setSheetState(() => saving = false);
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(content: Text(KhmerText.wrongCredentials)),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(KhmerText.save, style: TextStyle(fontFamily: 'KantumruyPro')),
                  ),
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
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text(KhmerText.settingsTitle)),
      body: _loadingPrefs
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                RomanticCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        title: const Text(KhmerText.settingsNotifications, style: TextStyle(fontFamily: 'KantumruyPro')),
                        secondary: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        value: context.watch<ThemeProvider>().isDarkMode,
                        onChanged: _toggleDarkMode,
                        title: const Text(KhmerText.settingsDarkMode, style: TextStyle(fontFamily: 'KantumruyPro')),
                        secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                RomanticCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline, color: AppColors.primary),
                        title: const Text(KhmerText.settingsAccount, style: TextStyle(fontFamily: 'KantumruyPro')),
                        subtitle: Text(user?.email ?? '', style: const TextStyle(fontFamily: 'KantumruyPro')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_reset_outlined, color: AppColors.primary),
                        title: const Text(KhmerText.settingsChangePassword, style: TextStyle(fontFamily: 'KantumruyPro')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openChangePassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
