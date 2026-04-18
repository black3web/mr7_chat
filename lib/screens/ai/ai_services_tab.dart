import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';

class AiServicesTab extends StatelessWidget {
  const AiServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    
    // قائمة الخدمات المعرفة محلياً لتجنب مشاكل AppGradients غير الموجودة
    final services = [
      _ServiceCard(
        icon: Icons.chat_bubble_rounded,
        iconColor: const Color(0xFF4285F4),
        title: 'Gemini 2.5 Flash',
        subtitle: l['geminiChat'] ?? 'Chat with Gemini',
        route: AppRoutes.geminiChat,
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
      ),
      _ServiceCard(
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF00BCD4),
        title: 'DeepSeek',
        subtitle: l['deepSeekChat'] ?? 'DeepSeek Intelligence',
        route: AppRoutes.deepSeekChat,
        gradient: const LinearGradient(colors: [Color(0xFF006064), Color(0xFF00838F)]),
      ),
      _ServiceCard(
        icon: Icons.image_rounded,
        iconColor: const Color(0xFFE91E63),
        title: 'Nano Banana 2',
        subtitle: l['imageGeneration'] ?? 'Generate Images',
        route: AppRoutes.imageGen,
        gradient: const LinearGradient(colors: [Color(0xFF880E4F), Color(0xFFC2185B)]),
      ),
      _ServiceCard(
        icon: Icons.photo_filter_rounded,
        iconColor: const Color(0xFFFF9800),
        title: 'NanoBanana Pro',
        subtitle: l['imageEditing'] ?? 'Edit & Enhance',
        route: AppRoutes.imageGenPro,
        gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFF57C00)]),
      ),
      _ServiceCard(
        icon: Icons.videocam_rounded,
        iconColor: const Color(0xFF9C27B0),
        title: 'Seedance AI',
        subtitle: l['videoGeneration'] ?? 'AI Video',
        route: AppRoutes.videoGen,
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)]),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemCount: services.length,
        itemBuilder: (ctx, i) {
          final s = services[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, s.route),
            child: Container(
              decoration: BoxDecoration(
                gradient: s.gradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: s.iconColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, size: 24, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    s.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, route;
  final LinearGradient gradient;
  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradient,
  });
}
