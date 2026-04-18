import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';

class VideoGenScreen extends StatefulWidget {
  const VideoGenScreen({super.key});
  @override
  State<VideoGenScreen> createState() => _VideoGenScreenState();
}

class _VideoGenScreenState extends State<VideoGenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              _AiHeader(
                title: 'Video Generator',
                subtitle: 'AI Video Creation',
                color: const Color(0xFF9C27B0),
                icon: Icons.videocam_rounded,
                onBack: () => Navigator.pop(context),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppGradients.accentGradient,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'تحويل نص إلى فيديو'),
                    Tab(text: 'تحويل صورة إلى فيديو'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _TextToVideoTab(),
                    _ImageToVideoTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextToVideoTab extends StatefulWidget {
  @override
  State<_TextToVideoTab> createState() => _TextToVideoTabState();
}

class _TextToVideoTabState extends State<_TextToVideoTab> {
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _videoUrl;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty || _loading) return;
    setState(() { _loading = true; _videoUrl = null; });

    try {
      final url = await AiService().generateVideo(_promptCtrl.text.trim());
      setState(() { _videoUrl = url; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إنشاء الفيديو')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle(title: 'وصف مشهد الفيديو', icon: Icons.movie_filter_rounded),
        const SizedBox(height: 12),
        _buildInputField(),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('بدء التوليد ذكاء اصطناعي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        if (_videoUrl != null) _VideoPreview(url: _videoUrl!),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: _promptCtrl,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'مثلاً: غابة استوائية مع شلالات متحركة بدقة عالية...',
          hintStyle: TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _ImageToVideoTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_videocam_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('قريباً: تحريك الصور الثابتة', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _initialized = true));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
    return Column(
      children: [
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
        ),
        IconButton(
          onPressed: () => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play(),
          icon: Icon(_ctrl.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 40),
        ),
      ],
    );
  }
}

class _AiHeader extends StatelessWidget {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onBack;
  const _AiHeader({required this.title, required this.subtitle, required this.color, required this.icon, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
