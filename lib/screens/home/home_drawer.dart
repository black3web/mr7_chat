import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';

class HomeDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeDrawer({super.key, required this.scaffoldKey});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    return Drawer(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.drawerGradient),
          child: SafeArea(
            child: Column(children: [
              // Banner header
              GestureDetector(
                onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.profile); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryDark.withOpacity(0.8), AppColors.bgDark.withOpacity(0.3)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    UserAvatar(photoUrl: user.photoUrl, name: user.name, size: 70),
                    const SizedBox(height: 12),
                    Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('@\${user.username}', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 2),
                    Text('ID: \${user.id}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), fontFamily: 'monospace')),
                  ]),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 8),
                    _DrawerItem(icon: Icons.person_rounded, label: l['myAccount'], onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.profile); }),
                    _DrawerItem(icon: Icons.smart_toy_rounded, label: l['aiServices'], onTap: () { Navigator.pop(context); }),
                    _DrawerItem(icon: Icons.settings_rounded, label: l['settings'], onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.settings); }),
                    _DrawerItem(icon: Icons.support_agent_rounded, label: l['support'], onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.support); }),
                    if (user.isAdmin) ...[
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 8),
                      _DrawerItem(icon: Icons.admin_panel_settings_rounded, label: l['adminPanel'], color: AppColors.accent, onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.admin); }),
                    ],
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),
                    // Saved accounts
                    if (p.savedAccounts.length > 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(l['switchAccount'], style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ),
                      ...p.savedAccounts.where((a) => a.id != user.id).map((acc) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: UserAvatar(photoUrl: acc.photoUrl, name: acc.name, size: 36),
                        title: Text(acc.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('@\${acc.username}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        onTap: () { Navigator.pop(context); p.switchAccount(acc.id); },
                      )),
                      const SizedBox(height: 4),
                    ],
                    _DrawerItem(icon: Icons.add_circle_outline_rounded, label: l['addAccount'], onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.register); }),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 8),
                    _DrawerItem(icon: Icons.info_outline_rounded, label: l['devInfo'], onTap: () { Navigator.pop(context); _showDevInfo(context, l); }),
                    _DrawerItem(icon: Icons.logout_rounded, label: l['logout'], color: AppColors.accent, onTap: () async { Navigator.pop(context); await p.logout(); Navigator.pushReplacementNamed(context, AppRoutes.login); }),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDevInfo(BuildContext context, AppLocalizations l) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
      title: Text(l['devInfo'], style: const TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(backgroundColor: AppColors.primary, radius: 30, child: Text('J', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(height: 12),
        const Text(AppConstants.devName, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _DevLink(label: 'الموقع الشخصي', url: AppConstants.devWebsite),
        const SizedBox(height: 8),
        _DevLink(label: 'قناة تيليجرام', url: AppConstants.devTelegram),
      ]),
    ));
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: (color ?? AppColors.textMuted).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
    ),
    title: Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    hoverColor: AppColors.glassBase,
  );
}

class _DevLink extends StatelessWidget {
  final String label, url;
  const _DevLink({required this.label, required this.url});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(Icons.link_rounded, size: 16, color: AppColors.accent),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      Text(url, style: TextStyle(color: AppColors.accent.withOpacity(0.8), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
    ])),
  ]);
}