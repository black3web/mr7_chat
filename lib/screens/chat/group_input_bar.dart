import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/group_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';

class GroupInputBar extends StatefulWidget {
  final String groupId;
  final String senderId;
  final String? senderName;
  final String? senderPhotoUrl;
  final MessageModel? replyingTo;
  final VoidCallback? onSent;
  const GroupInputBar({super.key, required this.groupId, required this.senderId, this.senderName, this.senderPhotoUrl, this.replyingTo, this.onSent});
  @override
  State<GroupInputBar> createState() => _GroupInputBarState();
}

class _GroupInputBarState extends State<GroupInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false, _sending = false;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    setState(() => _hasText = false);
    await GroupService().sendGroupMessage(
      groupId: widget.groupId, senderId: widget.senderId,
      senderName: widget.senderName ?? '', senderPhotoUrl: widget.senderPhotoUrl,
      type: MessageType.text, text: text,
      replyToId: widget.replyingTo?.id, replyToText: widget.replyingTo?.text,
    );
    setState(() => _sending = false);
    widget.onSent?.call();
  }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final url = await StorageService().uploadMedia(file, widget.groupId);
      await GroupService().sendGroupMessage(groupId: widget.groupId, senderId: widget.senderId, senderName: widget.senderName ?? '', senderPhotoUrl: widget.senderPhotoUrl, type: MessageType.image, mediaUrl: url);
      widget.onSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(top: BorderSide(color: AppColors.glassBorder))),
      child: Row(children: [
        GestureDetector(onTap: _pickImage, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)), child: const Icon(Icons.attach_file_rounded, size: 20, color: AppColors.textSecondary))),
        const SizedBox(width: 8),
        Expanded(child: Container(constraints: const BoxConstraints(maxHeight: 120), decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.glassBorder)),
          child: TextField(controller: _ctrl, maxLines: null, style: const TextStyle(color: Colors.white, fontSize: 15), onChanged: (v) => setState(() => _hasText = v.trim().isNotEmpty),
            decoration: InputDecoration(hintText: l['typeMessage'], border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))))),
        const SizedBox(width: 8),
        GestureDetector(onTap: _hasText ? _send : null, child: Container(width: 42, height: 42,
          decoration: BoxDecoration(gradient: _hasText ? AppGradients.accentGradient : null, color: _hasText ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: _hasText ? null : Border.all(color: AppColors.glassBorder)),
          child: _sending ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.send_rounded, size: 20, color: _hasText ? Colors.white : AppColors.textMuted))),
      ]),
    );
  }
}