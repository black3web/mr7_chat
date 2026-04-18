import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/animated_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<UserModel> _users = [];
  List<GroupModel> _groups = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) { setState(() { _users = []; _groups = []; _searched = false; }); return; }
    setState(() { _loading = true; _searched = true; });
    final query = q.trim().replaceFirst('@', '');
    final futures = await Future.wait([
      AuthService().searchUsers(query),
      GroupService().searchGroups(query),
    ]);
    setState(() { _users = futures[0] as List<UserModel>; _groups = futures[1] as List<GroupModel>; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = context.read<AppProvider>().currentUser!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    onChanged: (v) { if (v.isEmpty) { setState(() { _users = []; _groups = []; _searched = false; }); } },
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: l['search'],
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _ctrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _ctrl.clear(); setState(() { _users = []; _groups = []; _searched = false; }); }) : null,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(onPressed: () => _search(_ctrl.text), child: Text(l['search'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700))),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : !_searched
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text(l['search'], style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                        ]))
                      : _users.isEmpty && _groups.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text(l['noResults'], style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
                            ]))
                          : ListView(children: [
                              if (_users.isNotEmpty) ...[
                                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(l['chats'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5), letterSpacing: 0.8))),
                                ..._users.map((u) => ListTile(
                                  leading: UserAvatar(photoUrl: u.photoUrl, name: u.name, size: 46, showOnline: true, isOnline: u.isOnline),
                                  title: Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  subtitle: Text('@${u.username}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.userProfile, arguments: {'userId': u.id}),
                                )),
                              ],
                              if (_groups.isNotEmpty) ...[
                                Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(l['groups'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5), letterSpacing: 0.8))),
                                ..._groups.map((g) => ListTile(
                                  leading: UserAvatar(photoUrl: g.photoUrl, name: g.name, size: 46),
                                  title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  subtitle: Text('@${g.username} - ${g.members.length} ${l['members']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.groupChat, arguments: {'groupId': g.id}),
                                )),
                              ],
                            ]),
            ),
          ]),
        ),
      ),
    );
  }
}
