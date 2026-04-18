import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../config/routes.dart';
import '../widgets/animated_background.dart';
import '../widgets/mr7_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim, _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final p = context.read<AppProvider>();
    if (p.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.languageSelect);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [const Color(0xFF8B0000).withOpacity(0.6), Colors.transparent],
                      ),
                      border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.4), width: 1),
                    ),
                    child: const Center(child: MR7Logo(fontSize: 36)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MR7 CHAT',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 6,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
