import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_avatar.dart';
import 'package:intl/intl.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<List<ChatModel>>(
      stream: ChatService().listenToChats(user.id),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final chats = snap.data ?? [];
        if (chats.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(l['noChats'], style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: chats.length,
          itemBuilder: (ctx, i) => _ChatTile(chat: chats[i], currentUserId: user.id),
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  const _ChatTile({required this.chat, required this.currentUserId});

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return DateFormat('HH:mm').format(dt);
    if (now.difference(dt).inDays == 1) return 'أمس';
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final otherId = chat.participantIds.firstWhere((id) => id != currentUserId, orElse: () => currentUserId);
    return FutureBuilder<UserModel?>(
      future: AuthService().getUserById(otherId),
      builder: (ctx, snap) {
        final other = snap.data;
        final unread = chat.unreadCounts[currentUserId] ?? 0;
        return InkWell(
          onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: {'chatId': chat.id, 'otherUserId': otherId}),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              UserAvatar(photoUrl: other?.photoUrl, name: other?.name ?? '?', size: 52, showOnline: true, isOnline: other?.isOnline ?? false),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(other?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(_formatTime(chat.lastMessageAt), style: TextStyle(fontSize: 11, color: unread > 0 ? AppColors.accent : AppColors.textMuted)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: Text(chat.lastMessageText ?? '', style: TextStyle(fontSize: 13, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (unread > 0) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ])),
            ]),
          ),
        );
      },
    );
  }
}