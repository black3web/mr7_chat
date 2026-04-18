import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/animated_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _loading = false;
  String? _photoUrl;
  bool _showPass = false, _showNewPass = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser!;
    _nameCtrl.text = user.name;
    _userCtrl.text = user.username;
    _bioCtrl.text = user.bio ?? '';
    _photoUrl = user.photoUrl;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _userCtrl.dispose(); _bioCtrl.dispose(); _passCtrl.dispose(); _newPassCtrl.dispose(); super.dispose(); }

  Future<void> _pickPhoto() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadProfilePhoto(file);
      setState(() => _photoUrl = url);
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final l = AppLocalizations.of(context);
    try {
      final updates = <String, dynamic>{};
      if (_nameCtrl.text.trim().isNotEmpty) updates['name'] = _nameCtrl.text.trim();
      if (_userCtrl.text.trim().isNotEmpty) updates['username'] = _userCtrl.text.trim();
      if (_bioCtrl.text.trim().isNotEmpty) updates['bio'] = _bioCtrl.text.trim();
      if (_photoUrl != null) updates['photoUrl'] = _photoUrl;
      if (_newPassCtrl.text.isNotEmpty && _passCtrl.text.isNotEmpty) updates['newPassword'] = _newPassCtrl.text;
      await AuthService().updateProfile(
        name: updates['name'],
        username: updates['username'],
        photoUrl: updates['photoUrl'],
        bio: updates['bio'],
        newPassword: updates['newPassword'],
      );
      await context.read<AppProvider>().refreshUser();
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l['success']))); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                Text(l['editProfile'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)) :
                TextButton(onPressed: _save, child: Text(l['save'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15))),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
              // Photo
              Center(child: Stack(children: [
                UserAvatar(photoUrl: _photoUrl, name: _nameCtrl.text, size: 90),
                Positioned(bottom: 0, right: 0, child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(width: 30, height: 30, decoration: BoxDecoration(gradient: AppGradients.accentGradient, shape: BoxShape.circle, border: Border.all(color: AppColors.bgDark, width: 2)), child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white)),
                )),
              ])),
              const SizedBox(height: 24),
              GlassContainer(padding: const EdgeInsets.all(16), child: Column(children: [
                _Field(ctrl: _nameCtrl, label: l['name'], icon: Icons.person_rounded, max: AppConstants.maxNameLength),
                const SizedBox(height: 12),
                _Field(ctrl: _userCtrl, label: l['username'], icon: Icons.alternate_email_rounded, prefix: '@', max: AppConstants.maxUsernameLength),
                const SizedBox(height: 12),
                _Field(ctrl: _bioCtrl, label: 'Bio', icon: Icons.info_outline_rounded, maxLines: 3),
              ])),
              const SizedBox(height: 12),
              GlassContainer(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l['changePassword'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                _Field(ctrl: _passCtrl, label: l['currentPassword'], icon: Icons.lock_outline_rounded, obscure: !_showPass, suffix: IconButton(icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted), onPressed: () => setState(() => _showPass = !_showPass))),
                const SizedBox(height: 12),
                _Field(ctrl: _newPassCtrl, label: l['newPassword'], icon: Icons.lock_rounded, obscure: !_showNewPass, suffix: IconButton(icon: Icon(_showNewPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted), onPressed: () => setState(() => _showNewPass = !_showNewPass))),
              ])),
            ]))),
          ]),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final int maxLines;
  final int? max;
  final String? prefix;
  final Widget? suffix;
  const _Field({required this.ctrl, required this.label, required this.icon, this.obscure = false, this.maxLines = 1, this.max, this.prefix, this.suffix});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      maxLength: max,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        suffixIcon: suffix,
        counterStyle: TextStyle(color: AppColors.textMuted, fontSize: 10),
      ),
    ),
  ]);
}
