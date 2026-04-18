import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/glass_container.dart';
import 'gemini_chat_screen.dart';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});
  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(child: Column(children: [
          _AiHeader(title: 'Image Generator', subtitle: 'AI Image Creation', color: const Color(0xFFE91E63), icon: Icons.image_rounded),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 42,
            decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorder)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppGradients.accentGradient),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              padding: const EdgeInsets.all(3),
              tabs: [Tab(text: l['generateImage']), Tab(text: l['imageEditing'])],
            ),
          ),
          Expanded(child: TabBarView(controller: _tabCtrl, children: const [_NanoBananaTab(), _NanoBananaProTab()])),
        ])),
      ),
    );
  }
}

// Nano Banana 2 - text to image only
class _NanoBananaTab extends StatefulWidget {
  const _NanoBananaTab();
  @override
  State<_NanoBananaTab> createState() => _NanoBananaTabState();
}

class _NanoBananaTabState extends State<_NanoBananaTab> {
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
      final url = await AiService().generateImageNano(prompt, userId);
      setState(() => _resultUrl = url);
    } catch (e) {
      setState(() => _error = 'فشل توليد الصورة. حاول مجددا.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.image_search_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Nano Banana 2 - 2K', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(hintText: l['imageDescription']),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_fix_high_rounded, size: 20),
              label: Text(_loading ? l['generating'] : l['generateImage'], style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ]),
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
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: _resultUrl!, fit: BoxFit.cover, width: double.infinity)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
                const SizedBox(width: 6),
                Text('تم توليد الصورة بنجاح', style: TextStyle(color: AppColors.online, fontSize: 13)),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }
}

// NanoBanana Pro - create + edit
class _NanoBananaProTab extends StatefulWidget {
  const _NanoBananaProTab();
  @override
  State<_NanoBananaProTab> createState() => _NanoBananaProTabState();
}

class _NanoBananaProTabState extends State<_NanoBananaProTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultUrl;
  String? _error;
  String? _inputImageUrl;
  String _ratio = '1:1';
  String _resolution = '2K';
  bool _editMode = false;

  static const _ratios = ['1:1', '16:9', '9:16', '4:3', '3:4'];
  static const _resolutions = ['1K', '2K', '4K'];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final file = await StorageService().pickImage();
    if (file == null) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() => _loading = true);
    try {
      final url = await StorageService().uploadMedia(file, 'ai_temp');
      setState(() { _inputImageUrl = url; _editMode = true; });
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _loading) return;
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    setState(() { _loading = true; _resultUrl = null; _error = null; });
    try {
      final url = await AiService().nanoBananaPro(
        prompt: prompt, userId: userId, ratio: _ratio, resolution: _resolution,
        imageUrl: _inputImageUrl,
      );
      setState(() => _resultUrl = url);
    } catch (e) {
      setState(() => _error = 'فشل معالجة الصورة. حاول مجددا.');
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Mode toggle
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _editMode = false; _inputImageUrl = null; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(gradient: !_editMode ? AppGradients.accentGradient : null, color: _editMode ? AppColors.bgLight : null, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)), border: Border.all(color: AppColors.glassBorder)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.text_fields_rounded, size: 18, color: !_editMode ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(l['generateImage'], style: TextStyle(color: !_editMode ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(gradient: _editMode ? AppGradients.accentGradient : null, color: !_editMode ? AppColors.bgLight : null, borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)), border: Border.all(color: AppColors.glassBorder)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.photo_filter_rounded, size: 18, color: _editMode ? Colors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(l['editImage'], style: TextStyle(color: _editMode ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (_inputImageUrl != null) ...[
          GlassContainer(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: _inputImageUrl!, height: 160, fit: BoxFit.cover, width: double.infinity)),
              const SizedBox(height: 6),
              Text('صورة المدخل - اكتب تعليمات التعديل ادناه', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        // Ratio selector
        Text('نسبة الصورة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _ratios.map((r) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _ratio = r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(gradient: _ratio == r ? AppGradients.accentGradient : null, color: _ratio == r ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: _ratio == r ? AppColors.accent : AppColors.glassBorder)),
                child: Text(r, style: TextStyle(color: _ratio == r ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 12),
        // Resolution selector
        Text('الجودة', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: _resolutions.map((r) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: _resolutions.last == r ? 0 : 8),
          child: GestureDetector(
            onTap: () => setState(() => _resolution = r),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(gradient: _resolution == r ? AppGradients.accentGradient : null, color: _resolution == r ? null : AppColors.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _resolution == r ? AppColors.accent : AppColors.glassBorder)),
              child: Text(r, textAlign: TextAlign.center, style: TextStyle(color: _resolution == r ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
          ),
        ))).toList()),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: _editMode ? 'اكتب تعليمات التعديل...' : l['imageDescription']),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_fix_high_rounded, size: 20),
          label: Text(_loading ? l['generating'] : (_editMode ? l['editImage'] : l['generateImage']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: _resultUrl!, fit: BoxFit.cover, width: double.infinity)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.online),
                const SizedBox(width: 6),
                Text('تم المعالجة بنجاح - $_resolution', style: TextStyle(color: AppColors.online, fontSize: 13)),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }
}