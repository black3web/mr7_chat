import 'package:flutter/material.dart';
import '../config/theme.dart';

class MR7Logo extends StatelessWidget {
  final double fontSize;
  final bool animate;
  const MR7Logo({super.key, this.fontSize = 32, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFF8B0000), Color(0xFFFF1744), Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'MR7',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          color: Colors.white,
          shadows: [
            Shadow(color: AppColors.accent.withOpacity(0.6), blurRadius: 12),
            Shadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 24),
          ],
        ),
      ),
    );
  }
}
