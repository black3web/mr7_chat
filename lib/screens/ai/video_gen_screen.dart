import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_container.dart';
import 'gemini_chat_screen.dart';

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
    const bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(child: Column(children: [
          const _AiHeader(
            title: 'Video Generator', 
            subtitle: 'AI Video Creation', 
            color: Color(0xFF9C27B0), 
            icon: Icons.videocam_rounded
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgLight, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: AppColors.glassBorder)
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10), 
                gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              padding: const EdgeInsets.all(3),
              tabs: const [Tab(text: 'Seedance AI'), Tab(text: 'Kilwa Video')],
            ),
          ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: const [_SeedanceTab(), _KilwaVideoTab()])),
        ])),
      ),
    );
  }
}

class _SeedanceTab extends StatefulWidget {
  const _SeedanceTab();
  @override
  State<_SeedanceTab> createState() => _SeedanceTabState();
}

class _SeedanceTabState extends State<_SeedanceTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;
  String? _inputImageUrl;
  bool _imageToVideo = false;

  Map<String, dynamic> _selectedModel = AiService.seedanceModels[0];
  int _duration = 8;
  String _resolution = '720p';
  String _aspectRatio = '16:9';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadMedia(file, 'ai_temp');
      setState(() { _inputImageUrl = url; _imageToVideo = true; });
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _resultUrl = null; _error = null; });
    try {
      final url = await AiService().seedanceGenerate(
        prompt: prompt,
        userId: userId,
        model: _selectedModel['id'] as String,
        duration: _duration,
        resolution: _resolution,
        aspectRatio: _aspectRatio,
        imageUrl: _imageToVideo ? _inputImageUrl : null,
      );
      setState(() => _resultUrl = url);
    } catch (e) {
      setState(() => _error = 'فشل توليد الفيديو. حاول مجددا.');
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final durations = _selectedModel['durations'] as List<dynamic>;
    final ratios = _selectedModel['ratios'] as List<dynamic>;
    final supportsImage = _selectedModel['supportsImageInput'] as bool;
    const accentGradient = LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('النموذج', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...AiService.seedanceModels.map((m) => GestureDetector(
              onTap: () { setState(() { _selectedModel = m; if (!durations.contains(_duration)) _duration = (m['durations'] as List).first; }); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: _selectedModel['id'] == m['id'] ? accentGradient : null,
                  color: _selectedModel['id'] == m['id'] ? null : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedModel['id'] == m['id'] ? const Color(0xFF9C27B0) : AppColors.glassBorder),
                ),
                child: Row(children: [
                  Icon(Icons.movie_rounded, size: 18, color: _selectedModel['id'] == m['id'] ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m['name'] as String, style: TextStyle(color: _selectedModel['id'] == m['id'] ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${(m['durations'] as List).join(', ')}s | ${(m['resolutions'] as List).join(', ')}', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                  ])),
                  if (_selectedModel['id'] == m['id']) const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                ]),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        Text('المدة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: durations.map<Widget>((d) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _duration = d as int),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _duration == d ? accentGradient : null, 
                  color: _duration == d ? null : AppColors.bgLight, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: _duration == d ? const Color(0xFF9C27B0) : AppColors.glassBorder)
                ),
                child: Text('${d}s', style: TextStyle(color: _duration == d ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 12),
        Text('نسبة العرض', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ratios.map<Widget>((r) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _aspectRatio = r as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: _aspectRatio == r ? accentGradient : null, 
                  color: _aspectRatio == r ? null : AppColors.bgLight, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: _aspectRatio == r ? const Color(0xFF9C27B0) : AppColors.glassBorder)
                ),
                child: Text(r as String, style: TextStyle(color: _aspectRatio == r ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 12),
        Text('الدقة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: ['480p', '720p'].map((r) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: r == '480p' ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _resolution = r),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _resolution == r ? accentGradient : null, 
                color: _resolution == r ? null : AppColors.bgLight, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: _resolution == r ? const Color(0xFF9C27B0) : AppColors.glassBorder)
              ),
              child: Text(r, textAlign: TextAlign.center, style: TextStyle(color: _resolution == r ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          ),
        ))).toList()),
        const SizedBox(height: 12),
        if (supportsImage) ...[
          GestureDetector(
            onTap: _imageToVideo ? () => setState(() { _imageToVideo = false; _inputImageUrl = null; }) : _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: _imageToVideo ? accentGradient : null,
                color: _imageToVideo ? null : AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _imageToVideo ? const Color(0xFF9C27B0) : AppColors.glassBorder),
              ),
              child: Row(children: [
                Icon(_imageToVideo ? Icons.image_rounded : Icons.add_photo_alternate_outlined, size: 20, color: _imageToVideo ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 10),
                Text(_imageToVideo ? 'صورة محددة - اضغط للازالة' : 'اضف صورة (Image-to-Video)', style: TextStyle(color: _imageToVideo ? Colors.white : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          if (_inputImageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _inputImageUrl!, height: 120, fit: BoxFit.cover, width: double.infinity)),
          ],
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _ctrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: l['videoDescription']),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.movie_creation_rounded, size: 20),
          label: Text(_loading ? l['generating'] : l['generateVideo'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.accent, fontSize: 13)))]),
          ),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              _VideoPlayerWidget(url: _resultUrl!),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
                const SizedBox(width: 6),
                Text('تم توليد الفيديو بنجاح', style: TextStyle(color: AppColors.online, fontSize: 13)),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ملاحظات مهمة:', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            Text('- Seedance 1.5 Pro: 4/8/12 ثانية, لا يدعم الصوت في 12 ثانية', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text('- Seedance 1.0 Pro/Lite: 5/10 ثانية بدون صوت', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _KilwaVideoTab extends StatefulWidget {
  const _KilwaVideoTab();
  @override
  State<_KilwaVideoTab> createState() => _KilwaVideoTabState();
}

class _KilwaVideoTabState extends State<_KilwaVideoTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _resultUrl = null; _error = null; });
    try {
      final url = await AiService().generateVideoKilwa(prompt, userId);
      setState(() => _resultUrl = url);
    } catch (e) {
      setState(() => _error = 'فشل توليد الفيديو. حاول مجددا.');
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Icon(Icons.movie_rounded, size: 48, color: const Color(0xFF9C27B0).withOpacity(0.7)),
            const SizedBox(height: 8),
            const Text('Seedance 1.5 Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('توليد فيديو سريع', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: l['videoDescription']),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_circle_rounded, size: 20),
          label: Text(_loading ? 'جاري التوليد...' : l['generateVideo'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF4A148C), minimumSize: const Size(double.infinity, 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
            child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.accent, size: 18), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.accent, fontSize: 13)))]),
          ),
        ],
        if (_resultUrl != null) ...[
          const SizedBox(height: 16),
          GlassContainer(padding: const EdgeInsets.all(8), child: _VideoPlayerWidget(url: _resultUrl!)),
        ],
      ]),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});
  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _initialized = true));
    _ctrl.addListener(() => setState(() => _playing = _ctrl.value.isPlaying));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return Container(height: 200, decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)), child: const Center(child: CircularProgressIndicator(color: AppColors.accent)));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(children: [
        AspectRatio(aspectRatio: _ctrl.value.aspectRatio, child: VideoPlayer(_ctrl)),
        Positioned.fill(child: GestureDetector(
          onTap: () => _playing ? _ctrl.pause() : _ctrl.play(),
          child: AnimatedOpacity(
            opacity: _playing ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(color: Colors.black38, child: const Center(child: Icon(Icons.play_circle_rounded, size: 56, color: Colors.white))),
          ),
        )),
        VideoProgressIndicator(_ctrl, allowScrubbing: true, colors: const VideoProgressColors(playedColor: AppColors.accent, bufferedColor: Colors.white24, backgroundColor: Colors.white12)),
      ]),
    );
  }
}

class _AiHeader extends StatelessWidget {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  const _AiHeader({required this.title, required this.subtitle, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ])),
      ]),
    );
  }
}
