import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import '../../widgets/glass_container.dart';

class ChatInputBar extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onSent;
  const ChatInputBar({super.key, required this.chatId, required this.senderId, this.senderName, this.senderPhotoUrl, this.replyingTo, this.onSent});
  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    setState(() => _hasText = false);
    await ChatService().sendMessage(
      chatId: widget.chatId,
      senderId: widget.senderId,
      senderName: widget.senderName,
      senderPhotoUrl: widget.senderPhotoUrl,
      type: MessageType.text,
      text: text,
      replyToId: widget.replyingTo?.id,
      replyToText: widget.replyingTo?.text,
      replyToSenderId: widget.replyingTo?.senderId,
    );
    setState(() => _sending = false);
    widget.onSent?.call();
  }

  Future<void> _pickAndSendImage() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final url = await StorageService().uploadMedia(file, widget.chatId);
      await ChatService().sendMessage(
        chatId: widget.chatId, senderId: widget.senderId,
        senderName: widget.senderName, senderPhotoUrl: widget.senderPhotoUrl,
        type: MessageType.image, mediaUrl: url,
      );
      widget.onSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(top: BorderSide(color: AppColors.glassBorder))),
      child: Row(children: [
        GestureDetector(
          onTap: () => _showMediaPicker(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
            child: const Icon(Icons.attach_file_rounded, size: 20, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
              decoration: InputDecoration(
                hintText: l['typeMessage'],
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _hasText ? _send : null,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: _hasText ? AppGradients.accentGradient : null,
                color: _hasText ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: _hasText ? null : Border.all(color: AppColors.glassBorder),
              ),
              child: _sending
                ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.send_rounded, size: 20, color: _hasText ? Colors.white : AppColors.textMuted),
            ),
          ),
        ),
      ]),
    );
  }

  void _showMediaPicker(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _MediaOption(icon: Icons.image_rounded, label: l['photo'], onTap: () { Navigator.pop(context); _pickAndSendImage(); }),
          _MediaOption(icon: Icons.videocam_rounded, label: l['video'], onTap: () => Navigator.pop(context)),
          _MediaOption(icon: Icons.insert_drive_file_rounded, label: l['file'], onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MediaOption({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder)),
        child: Icon(icon, size: 26, color: AppColors.accent),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ]),
  );
}
