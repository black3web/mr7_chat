import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final l = AppLocalizations.of(context);
    final user = p.currentUser;
    if (user == null) return const SizedBox();
    final privacy = Map<String, dynamic>.from(p.privacySettings);
    final settings = Map<String, dynamic>.from(user.settings);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(color: AppColors.bgMedium.withOpacity(0.95), border: Border(bottom: BorderSide(color: AppColors.glassBorder))),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                Text(l['settings'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
              // Language
              _Section(title: l['language'], children: [
                _LangOption(lang: 'ar', label: l['arabic'], current: p.language, onTap: () => p.setLanguage('ar')),
                const SizedBox(height: 8),
                _LangOption(lang: 'en', label: l['english'], current: p.language, onTap: () => p.setLanguage('en')),
              ]),
              const SizedBox(height: 16),
              // Theme
              _Section(title: l['theme'], children: [
                _ThemeRow(icon: Icons.dark_mode_rounded, label: l['darkTheme'], selected: p.theme == 'dark', onTap: () => p.setTheme('dark')),
                const SizedBox(height: 8),
                _ThemeRow(icon: Icons.light_mode_rounded, label: l['lightTheme'], selected: p.theme == 'light', onTap: () => p.setTheme('light')),
              ]),
              const SizedBox(height: 16),
              // Privacy
              _Section(title: l['privacy'], children: [
                _SwitchRow(icon: Icons.access_time_rounded, label: l['hideLastSeen'], value: privacy['hideLastSeen'] ?? false, onChanged: (v) { privacy['hideLastSeen'] = v; p.updatePrivacy(privacy); }),
                _SwitchRow(icon: Icons.circle_rounded, label: l['hideOnlineStatus'], value: privacy['hideOnlineStatus'] ?? false, onChanged: (v) { privacy['hideOnlineStatus'] = v; p.updatePrivacy(privacy); }),
                _SwitchRow(icon: Icons.person_off_rounded, label: l['hideName'], value: privacy['hideName'] ?? false, onChanged: (v) { privacy['hideName'] = v; p.updatePrivacy(privacy); }),
                _SwitchRow(icon: Icons.hide_image_rounded, label: l['hideProfilePhoto'], value: privacy['hideProfilePhoto'] ?? false, onChanged: (v) { privacy['hideProfilePhoto'] = v; p.updatePrivacy(privacy); }),
              ]),
              const SizedBox(height: 16),
              // Notifications
              _Section(title: l['notifications'], children: [
                _SwitchRow(icon: Icons.notifications_rounded, label: l['notifications'], value: settings['notifications'] ?? true, onChanged: (v) { settings['notifications'] = v; }),
                _SwitchRow(icon: Icons.preview_rounded, label: l['messagePreview'], value: settings['messagePreview'] ?? true, onChanged: (v) { settings['messagePreview'] = v; }),
                _SwitchRow(icon: Icons.volume_up_rounded, label: l['soundEnabled'], value: settings['soundEnabled'] ?? true, onChanged: (v) { settings['soundEnabled'] = v; }),
                _SwitchRow(icon: Icons.vibration_rounded, label: l['vibrationEnabled'], value: settings['vibrationEnabled'] ?? true, onChanged: (v) { settings['vibrationEnabled'] = v; }),
              ]),
              const SizedBox(height: 16),
              // Advanced
              _Section(title: l['advanced'], children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.cleaning_services_rounded, size: 20, color: AppColors.textSecondary)),
                  title: Text(l['clearCache'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l['cacheCleared']))),
                ),
                const Divider(color: AppColors.divider),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.accent)),
                  title: Text(l['deleteAccount'], style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  subtitle: Text(l['deleteAccountWarning'], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                  onTap: () {},
                ),
              ]),
            ]))),
          ]),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5), letterSpacing: 0.8))),
    GlassContainer(padding: const EdgeInsets.all(12), child: Column(children: children)),
  ]);
}

class _LangOption extends StatelessWidget {
  final String lang, label, current;
  final VoidCallback onTap;
  const _LangOption({required this.lang, required this.label, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: current == lang ? AppGradients.accentGradient : null,
        color: current == lang ? null : AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current == lang ? AppColors.accent : AppColors.glassBorder),
      ),
      child: Row(children: [
        Text(label, style: TextStyle(color: current == lang ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        if (current == lang) const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
      ]),
    ),
  );
}

class _ThemeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeRow({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: selected ? AppGradients.accentGradient : null,
        color: selected ? null : AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.accent : AppColors.glassBorder),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: selected ? Colors.white : AppColors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (selected) const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
      ]),
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 18, color: AppColors.textMuted)),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
    Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent),
  ]);
}
