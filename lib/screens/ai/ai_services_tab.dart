import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../l10n/app_localizations.dart';

class AiServicesTab extends StatelessWidget {
  const AiServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final services = [
      _ServiceCard(
        icon: Icons.chat_bubble_rounded,
        iconColor: const Color(0xFF4285F4),
        title: 'Gemini 2.5 Flash',
        subtitle: 'ذكاء جوجل الخارق',
        route: AppRoutes.geminiChat,
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
      ),
      _ServiceCard(
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF00BCD4),
        title: 'DeepSeek',
        subtitle: 'محرك الاستنتاج الذكي',
        route: AppRoutes.deepSeekChat,
        gradient: const LinearGradient(colors: [Color(0xFF006064), Color(0xFF00838F)]),
      ),
      _ServiceCard(
        icon: Icons.image_rounded,
        iconColor: const Color(0xFFE91E63),
        title: 'Image Generator',
        subtitle: 'توليد صور بدقة 4K',
        route: AppRoutes.imageGen,
        gradient: const LinearGradient(colors: [Color(0xFF880E4F), Color(0xFFAD1457)]),
      ),
      _ServiceCard(
        icon: Icons.videocam_rounded,
        iconColor: const Color(0xFF9C27B0),
        title: 'Video Generator',
        subtitle: 'صناعة فيديوهات قصيرة',
        route: AppRoutes.videoGen,
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)]),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.mainGradient),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الذكاء الاصطناعي', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('استكشف أدوات المستقبل', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              刻 (
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCard(context, services[index]),
                  childCount: services.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _ServiceCard s) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, s.route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: s.gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: s.iconColor.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(s.icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(s.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, route;
  final LinearGradient gradient;
  const _ServiceCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.route, required this.gradient});
}
