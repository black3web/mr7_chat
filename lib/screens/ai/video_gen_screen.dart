import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../config/theme.dart';
import '../../services/ai_service.dart';

class VideoGenScreen extends StatefulWidget {
  const VideoGenScreen({super.key});
  @override
  State<VideoGenScreen> createState() => _VideoGenScreenState();
}

class _VideoGenScreenState extends State<VideoGenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _promptCtrl = TextEditingController();
  bool _loading = false;
  String? _videoUrl;
  VideoPlayerController? _videoPlayerCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _promptCtrl.dispose();
    _videoPlayerCtrl?.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _promptCtrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _loading = true; _videoUrl = null; });

    try {
      final url = await AiService().generateVideo(text);
      _videoPlayerCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoUrl = url;
              _loading = false;
              _videoPlayerCtrl!.play();
              _videoPlayerCtrl!.setLooping(true);
            });
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عذراً، وظيفة الفيديو قيد التحديث')));
      }
    }
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
                color: Colors.purple,
                icon: Icons.videocam_rounded,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const _SectionTitle(title: 'وصف مشهد الفيديو', icon: Icons.movie_creation_rounded),
                    const SizedBox(height: 12),
                    _buildInputField(),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('بدء التوليد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    if (_videoUrl != null) _buildVideoResult(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: _promptCtrl,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'مثلاً: منظر طبيعي لشلالات في الغابة بنمط سينمائي...',
          hintStyle: TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildVideoResult() {
    return Column(
      children: [
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: _videoPlayerCtrl!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerCtrl!),
          ),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, color: AppColors.accent),
          label: const Text('حفظ الفيديو', style: TextStyle(color: AppColors.accent)),
        )
      ],
    );
  }
}

// الويدجيتس الفرعية المفقودة
class _AiHeader extends StatelessWidget {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onBack;
  const _AiHeader({required this.title, required this.subtitle, required this.color, required this.icon, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.accent),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ]);
  }
}
