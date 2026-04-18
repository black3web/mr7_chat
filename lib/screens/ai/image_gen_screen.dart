import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});
  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> with SingleTickerProviderStateMixin {
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
                title: 'Image Generator',
                subtitle: 'AI Image Creation',
                color: const Color(0xFFE91E63),
                icon: Icons.image_rounded,
                onBack: () => Navigator.pop(context),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    Tab(text: 'إنشاء جديد'),
                    Tab(text: 'تحسين الجودة'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _GenerateTab(),
                    _UpscaleTab(),
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

class _GenerateTab extends StatefulWidget {
  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  final _promptCtrl = TextEditingController();
  String _ratio = '1:1';
  bool _loading = false;
  String? _resultUrl;
  String? _error;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final url = await AiService().generateImage(_promptCtrl.text.trim(), ratio: _ratio);
      setState(() { _resultUrl = url; _loading = false; });
    } catch (e) {
      setState(() { _error = 'فشل إنشاء الصورة. حاول مرة أخرى.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle(title: 'وصف الصورة (Prompt)', icon: Icons.auto_awesome),
        const SizedBox(height: 12),
        _buildInputField(),
        const SizedBox(height: 20),
        const _SectionTitle(title: 'أبعاد الصورة', icon: Icons.aspect_ratio),
        const SizedBox(height: 12),
        _buildRatioSelector(),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _generate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('إنشاء الصورة الآن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        if (_error != null) _buildError(),
        if (_resultUrl != null) _buildResult(),
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
          hintText: 'مثلاً: رائد فضاء يركب خيلاً في الفضاء الفسيح...',
          hintStyle: TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRatioSelector() {
    final ratios = ['1:1', '4:3', '16:9', '9:16'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ratios.map((r) => GestureDetector(
        onTap: () => setState(() => _ratio = r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _ratio == r ? AppColors.accent : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(r, style: const TextStyle(color: Colors.white)),
        ),
      )).toList(),
    );
  }

  Widget _buildResult() {
    return Column(
      children: [
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(imageUrl: _resultUrl!, placeholder: (c, u) => const LinearProgressIndicator()),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {}, // إضافة منطق الحفظ لاحقاً
          icon: const Icon(Icons.download, color: AppColors.accent),
          label: const Text('حفظ الصورة', style: TextStyle(color: AppColors.accent)),
        )
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }
}

class _UpscaleTab extends StatefulWidget {
  @override
  State<_UpscaleTab> createState() => _UpscaleTabState();
}

class _UpscaleTabState extends State<_UpscaleTab> {
  bool _loading = false;
  String? _resultUrl;

  Future<void> _pickAndUpscale() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;

    setState(() => _loading = true);
    try {
      // منطق تحسين الجودة عبر AI
      final url = await AiService().upscaleImage(img.path);
      setState(() { _resultUrl = url; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.high_quality_rounded, size: 80, color: Colors.white12),
            const SizedBox(height: 16),
            const Text('تحسين جودة الصور الضعيفة بدقة 4K', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _pickAndUpscale,
              icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
              label: const Text('اختر صورة من المعرض', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, minimumSize: const Size(200, 50)),
            ),
            if (_loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            if (_resultUrl != null) ...[
              const SizedBox(height: 20),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: _resultUrl!, height: 200)),
            ]
          ],
        ),
      ),
    );
  }
}

// الويجيتس الفرعية التي كانت تسبب الأخطاء
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
