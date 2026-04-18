import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/message_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final bool showName;
  final Function(MessageModel)? onReply;
  final Function(MessageModel)? onDelete;
  final Function(MessageModel)? onEdit;
  final Function(MessageModel, String)? onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = false,
    this.showName = false,
    this.onReply,
    this.onDelete,
    this.onEdit,
    this.onReact,
  });

  void _showOptions(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        // Reactions row
        Container(
          height: 54, padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(scrollDirection: Axis.horizontal, children: AppConstants.reactions.map((emoji) =>
            GestureDetector(
              onTap: () { Navigator.pop(context); onReact?.call(message, emoji); },
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text(emoji, style: const TextStyle(fontSize: 26))),
            )
          ).toList()),
        ),
        const Divider(height: 1, color: AppColors.divider),
        if (message.text != null) ListTile(leading: const Icon(Icons.copy_rounded, color: AppColors.textSecondary), title: Text(l['copy'], style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Clipboard.setData(ClipboardData(text: message.text!)); }),
        ListTile(leading: const Icon(Icons.reply_rounded, color: AppColors.textSecondary), title: Text(l['replyTo'], style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); onReply?.call(message); }),
        if (isMine && message.type == MessageType.text) ListTile(leading: const Icon(Icons.edit_rounded, color: AppColors.textSecondary), title: Text(l['editMessage'], style: const TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); onEdit?.call(message); }),
        if (isMine) ListTile(leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accent), title: Text(l['deleteMessage'], style: const TextStyle(color: AppColors.accent)), onTap: () { Navigator.pop(context); onDelete?.call(message); }),
        const SizedBox(height: 8),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _DeletedBubble(isMine: isMine);
    if (message.type == MessageType.system) return _SystemMessage(text: message.text ?? '');
    if (message.isEmojiOnly && message.emojiCount <= 6) return _EmojiBubble(message: message, isMine: isMine, onLongPress: () => _showOptions(context));

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: EdgeInsets.only(bottom: 4, left: isMine ? 48 : 0, right: isMine ? 0 : 48),
        child: Row(
          mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine && showAvatar) ...[
              UserAvatar(photoUrl: message.senderPhotoUrl, name: message.senderName ?? '?', size: 28),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                if (!isMine && showName && message.senderName != null)
                  Padding(padding: const EdgeInsets.only(bottom: 2, left: 12),
                    child: Text(message.senderName!, style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700))),
                if (message.isForwarded)
                  Padding(padding: const EdgeInsets.only(bottom: 2, left: 12, right: 12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.forward_rounded, size: 12, color: AppColors.textMuted), const SizedBox(width: 4), Text(AppLocalizations.of(context)['forwarded'], style: const TextStyle(fontSize: 11, color: AppColors.textMuted))])),
                _BubbleContent(message: message, isMine: isMine),
                // Reactions
                if (message.reactions.isNotEmpty) _ReactionsRow(reactions: message.reactions),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  const _BubbleContent({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final bgColor = isMine ? AppColors.bubbleSelf : AppColors.bubbleOther;
    final borderColor = isMine ? AppColors.bubbleSelfBorder : AppColors.bubbleOtherBorder;
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMine ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(18),
        ),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (message.replyToId != null) _ReplyQuote(text: message.replyToText, senderName: message.replyToSenderId),
        if (message.type == MessageType.image && message.mediaUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: message.mediaUrl!, fit: BoxFit.cover, width: double.infinity, placeholder: (_, __) => Container(height: 200, color: AppColors.bgLight), errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
          ),
        if (message.text != null && message.text!.isNotEmpty) ...[
          if (message.type == MessageType.image) const SizedBox(height: 6),
          Text(message.text!, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        ],
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
          if (message.isEdited) Text(AppLocalizations.of(context)['messageEdited'], style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          const SizedBox(width: 4),
          Text(DateFormat('HH:mm').format(message.createdAt), style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
          if (isMine) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 14, color: message.status == MessageStatus.read ? AppColors.read : Colors.white.withOpacity(0.4))],
        ]),
      ]),
    );
  }
}

class _ReplyQuote extends StatelessWidget {
  final String? text, senderName;
  const _ReplyQuote({this.text, this.senderName});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: AppColors.accent, width: 2))),
    child: Text(text ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
  );
}

class _ReactionsRow extends StatelessWidget {
  final Map<String, ReactionModel> reactions;
  const _ReactionsRow({required this.reactions});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 4, children: reactions.entries.map((e) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(e.key, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text('${e.value.userIds.length}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    )
  ).toList());
}

class _EmojiBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback onLongPress;
  const _EmojiBubble({required this.message, required this.isMine, required this.onLongPress});
  @override
  Widget build(BuildContext context) {
    final count = message.emojiCount;
    final size = count <= 1 ? 48.0 : count <= 3 ? 36.0 : 28.0;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(bottom: 4, left: isMine ? 48 : 0, right: isMine ? 0 : 48),
        child: Row(mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
          Text(message.text!, style: TextStyle(fontSize: size)),
        ]),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  final bool isMine;
  const _DeletedBubble({required this.isMine});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 4, left: isMine ? 48 : 0, right: isMine ? 0 : 48),
    child: Row(mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.glassBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.not_interested_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(AppLocalizations.of(context)['messageDeleted'], style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic)),
        ]),
      ),
    ]),
  );
}

class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: AppColors.bgLight.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
    ),
  );
}