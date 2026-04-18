import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/glass_container.dart';
import 'message_bubble.dart';
import 'chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatScreen({super.key, required this.chatId, required this.otherUserId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  UserModel? _otherUser;
  MessageModel? _replyingTo;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    ChatService().markAsRead(widget.chatId, context.read<AppProvider>().currentUser!.id);
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getUserById(widget.otherUserId);
    setState(() => _otherUser = user);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final me = p.currentUser!;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.backgroundGradient,
          image: p.chatBackground != null ? DecorationImage(image: NetworkImage(p.chatBackground!), fit: BoxFit.cover, opacity: 0.15) : null,
        ),
        child: SafeArea(
          child: Column(children: [
            // Header
            _ChatHeader(user: _otherUser, onBack: () => Navigator.pop(context)),
            // Messages
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: ChatService().listenToMessages(widget.chatId),
                builder: (ctx, snap) {
                  final msgs = snap.data ?? [];
                  return ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: msgs.length,
                    itemBuilder: (ctx, i) => MessageBubble(
                      message: msgs[i],
                      isMine: msgs[i].senderId == me.id,
                      onReply: (msg) => setState(() => _replyingTo = msg),
                      onDelete: (msg) async {
                        final del = await showDialog<bool>(context: context, builder: (_) => _DeleteDialog(l: l));
                        if (del == true) ChatService().deleteMessage(widget.chatId, msg.id);
                      },
                      onEdit: (msg) async {
                        final ctrl = TextEditingController(text: msg.text);
                        final newText = await showDialog<String>(context: context, builder: (_) => _EditDialog(ctrl: ctrl, l: l));
                        if (newText != null && newText.trim().isNotEmpty) {
                          ChatService().editMessage(widget.chatId, msg.id, newText.trim());
                        }
                      },
                      onReact: (msg, emoji) => ChatService().addReaction(widget.chatId, msg.id, emoji, me.id),
                    ),
                  );
                },
              ),
            ),
            // Reply preview
            if (_replyingTo != null) _ReplyPreview(msg: _replyingTo!, onCancel: () => setState(() => _replyingTo = null)),
            // Input bar
            ChatInputBar(
              chatId: widget.chatId,
              senderId: me.id,
              senderName: me.name,
              senderPhotoUrl: me.photoUrl,
              replyingTo: _replyingTo,
              onSent: () {
                setState(() => _replyingTo = null);
                if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onBack;
  const _ChatHeader({this.user, required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: onBack),
        GestureDetector(
          onTap: user != null ? () => Navigator.pushNamed(context, AppRoutes.userProfile, arguments: {'userId': user!.id}) : null,
          child: Row(children: [
            UserAvatar(photoUrl: user?.photoUrl, name: user?.name ?? '?', size: 38, showOnline: true, isOnline: user?.isOnline ?? false),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              Text(user?.isOnline == true ? AppLocalizations.of(context)['online'] : AppLocalizations.of(context)['offline'],
                style: TextStyle(fontSize: 11, color: user?.isOnline == true ? AppColors.online : AppColors.textMuted)),
            ]),
          ]),
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary), onPressed: () {}),
      ]),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final MessageModel msg;
  final VoidCallback onCancel;
  const _ReplyPreview({required this.msg, required this.onCancel});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: AppColors.bgLight,
    child: Row(children: [
      Container(width: 3, height: 36, color: AppColors.accent),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(msg.senderName ?? '', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(msg.text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ])),
      IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted), onPressed: onCancel),
    ]),
  );
}

class _DeleteDialog extends StatelessWidget {
  final AppLocalizations l;
  const _DeleteDialog({required this.l});
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.bgCard,
    title: Text(l['deleteMessage'], style: const TextStyle(color: Colors.white)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l['cancel'])),
      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l['delete'])),
    ],
  );
}

class _EditDialog extends StatelessWidget {
  final TextEditingController ctrl;
  final AppLocalizations l;
  const _EditDialog({required this.ctrl, required this.l});
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.bgCard,
    title: Text(l['editMessage'], style: const TextStyle(color: Colors.white)),
    content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), maxLines: 4),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(l['cancel'])),
      ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: Text(l['save'])),
    ],
  );
}