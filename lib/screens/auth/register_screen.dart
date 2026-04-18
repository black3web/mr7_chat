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
import '../../config/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _showPass = false, _showConfirm = false;
  String? _errorMsg;
  bool? _userAvailable;
  bool _checkingUser = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _userCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String val) async {
    if (val.length < 4) { setState(() => _userAvailable = null); return; }
    setState(() => _checkingUser = true);
    final available = await AuthService().isUsernameAvailable(val.toLowerCase());
    setState(() { _userAvailable = available; _checkingUser = false; });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userAvailable == false) return;
    setState(() { _loading = true; _errorMsg = null; });
    final l = AppLocalizations.of(context);
    try {
      final user = await AuthService().register(
        name: _nameCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
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
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(children: [
              const SizedBox(height: 20),
              const MR7Logo(fontSize: 36),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(28),
                borderRadius: BorderRadius.circular(24),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(l['register'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 24),
                    // Name
                    _buildLabel(l['name']),
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(hintText: l['namePlaceholder'], prefixIcon: const Icon(Icons.person_outline_rounded, size: 20)),
                      maxLength: AppConstants.maxNameLength,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return l['nameRequired'];
                        if (v.length > AppConstants.maxNameLength) return l['nameTooLong'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Username
                    _buildLabel(l['username']),
                    TextFormField(
                      controller: _userCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      onChanged: (v) {
                        if (RegExp(AppConstants.usernameRegex).hasMatch(v) && v.length >= 4) _checkUsername(v);
                        else setState(() => _userAvailable = null);
                      },
                      decoration: InputDecoration(
                        hintText: l['usernamePlaceholder'],
                        prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                        suffixIcon: _checkingUser
                            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)))
                            : _userAvailable == null ? null
                              : Icon(_userAvailable! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: _userAvailable! ? AppColors.online : AppColors.accent, size: 20),
                      ),
                      maxLength: AppConstants.maxUsernameLength,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l['usernameRequired'];
                        if (v.length < AppConstants.minUsernameLength) return l['usernameTooShort'];
                        if (v.length > AppConstants.maxUsernameLength) return l['usernameTooLong'];
                        if (!RegExp(AppConstants.usernameRegex).hasMatch(v)) return l['usernameInvalid'];
                        if (_userAvailable == false) return l['usernameTaken'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Password
                    _buildLabel(l['password']),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_showPass,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l['passwordPlaceholder'],
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                      ),
                      maxLength: AppConstants.maxPasswordLength,
                      validator: (v) {
                        if (v == null || v.isEmpty) return l['passwordRequired'];
                        if (v.length < AppConstants.minPasswordLength) return l['passwordTooShort'];
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Confirm
                    _buildLabel(l['confirmPassword']),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: l['confirmPasswordPlaceholder'],
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: AppColors.textMuted),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) return l['passwordsNotMatch'];
                        return null;
                      },
                    ),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
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
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: Text(l['createAccount'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                    const SizedBox(height: 20),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l['haveAccount'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(l['loginHere'], style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
  );
}
