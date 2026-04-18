import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/story_service.dart';
import '../../services/storage_service.dart';
import '../../models/story_model.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});
  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _descCtrl = TextEditingController();
  String? _mediaUrl;
  StoryMediaType _mediaType = StoryMediaType.image;
  bool _loading = false;
  bool _uploading = false;

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  Future<void> _pick(bool isVideo) async {
    XFile? file;
    if (isVideo) {
      file = await StorageService().pickVideo();
    } else {
      file = await StorageService().pickImage();
    }
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final userId = context.read<AppProvider>().currentUser!.id;
      final url = await StorageService().uploadStoryMedia(file, userId);
      setState(() { _mediaUrl = url; _mediaType = isVideo ? StoryMediaType.video : StoryMediaType.image; });
    } catch (_) {} finally { setState(() => _uploading = false); }
  }

  Future<void> _publish() async {
    if (_mediaUrl == null) return;
    setState(() => _loading = true);
    try {
      final user = context.read<AppProvider>().currentUser!;
      await StoryService().addStory(
        userId: user.id,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        mediaType: _mediaType,
        mediaUrl: _mediaUrl!,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                Text(l['addStory'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                if (_mediaUrl != null) ElevatedButton(
                  onPressed: _loading ? null : _publish,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(l['done'], style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
              if (_mediaUrl == null) ...[
                GlassContainer(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const Icon(Icons.add_photo_alternate_rounded, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: _uploading ? null : () => _pick(false),
                        icon: const Icon(Icons.image_rounded, size: 20),
                        label: Text(l['uploadPhoto'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: _uploading ? null : () => _pick(true),
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: Text(l['uploadVideo'], style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A148C), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      )),
                    ]),
                    if (_uploading) ...[const SizedBox(height: 16), const CircularProgressIndicator(color: AppColors.accent)],
                  ]),
                ),
              ] else ...[
                ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: _mediaUrl!, height: 320, fit: BoxFit.cover, width: double.infinity)),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(hintText: l['addStoryDescription']),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _mediaUrl = null),
                  child: Row(children: [
                    const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text('تغيير الوسائط', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ]),
                ),
              ],
            ]))),
          ]),
        ),
      ),
    );
  }
}
