import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mr7_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  bool _loading = false;
  bool _showPass = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    final l = AppLocalizations.of(context);
    try {
      final user = await AuthService().login(username: _userCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      context.read<AppProvider>().setUser(user);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() { _errorMsg = l[msg.isNotEmpty ? msg : 'unknownError']; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = l.isArabic;
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(children: [
                const SizedBox(height: 40),
                const MR7Logo(fontSize: 42),
                const SizedBox(height: 6),
                Text('MR7 CHAT', style: TextStyle(fontSize: 11, letterSpacing: 5, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w300)),
                const SizedBox(height: 40),
                GlassContainer(
                  padding: const EdgeInsets.all(28),
                  borderRadius: BorderRadius.circular(24),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l['login'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 24),
                      _buildField(
                        controller: _userCtrl,
                        label: l['username'],
                        hint: l['usernamePlaceholder'],
                        icon: Icons.alternate_email_rounded,
                        validator: (v) => (v?.isEmpty ?? true) ? l['usernameRequired'] : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _passCtrl,
                        label: l['password'],
                        hint: l['passwordPlaceholder'],
                        icon: Icons.lock_outline_rounded,
                        obscure: !_showPass,
                        suffixIcon: IconButton(
                          icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                        validator: (v) => (v?.isEmpty ?? true) ? l['passwordRequired'] : null,
                      ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.accent, fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(l['login'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(l['noAccount'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                          child: Text(l['registerHere'], style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    ]);
  }
}
