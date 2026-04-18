import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/mr7_logo.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});
  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim, _slideAnim;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _selected = context.read<AppProvider>().language;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onContinue() async {
    if (_selected == null) return;
    await context.read<AppProvider>().setLanguage(_selected!);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const MR7Logo(fontSize: 48),
                      const SizedBox(height: 8),
                      Text('MR7 CHAT', style: TextStyle(
                        fontSize: 12, letterSpacing: 6,
                        color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w300,
                      )),
                      const SizedBox(height: 48),
                      Text('اختر لغتك / Select your language',
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _LanguageCard(
                        flag: '🇸🇦', label: 'العربية', sublabel: 'Arabic',
                        selected: _selected == 'ar',
                        onTap: () => setState(() => _selected = 'ar'),
                      ),
                      const SizedBox(height: 16),
                      _LanguageCard(
                        flag: '🇬🇧', label: 'English', sublabel: 'الإنجليزية',
                        selected: _selected == 'en',
                        onTap: () => setState(() => _selected = 'en'),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selected != null ? _onContinue : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            _selected == 'ar' ? 'متابعة' : 'Continue',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag, label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard({required this.flag, required this.label, required this.sublabel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.glassBase,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.glassBorder,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(sublabel, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
          ]),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accent : Colors.transparent,
              border: Border.all(color: selected ? AppColors.accent : AppColors.glassBorder, width: 1.5),
            ),
            child: selected ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }
}
