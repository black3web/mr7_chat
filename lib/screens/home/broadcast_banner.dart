import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../services/admin_service.dart';

class BroadcastBanner extends StatefulWidget {
  const BroadcastBanner({super.key});
  @override
  State<BroadcastBanner> createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends State<BroadcastBanner> {
  Map<String, dynamic>? _current;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AdminService().getBroadcasts().listen((list) {
      if (list.isEmpty) { setState(() => _visible = false); return; }
      final userId = context.read<AppProvider>().currentUser?.id ?? '';
      final filtered = list.where((b) => !(b['dismissedBy']?[userId] ?? false)).toList();
      if (filtered.isEmpty) { setState(() => _visible = false); return; }
      setState(() { _current = filtered.first; _visible = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _current == null) return const SizedBox();
    final msg = _current!['message'] as String? ?? '';
    final title = _current!['title'] as String? ?? '';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppGradients.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.campaign_rounded, size: 18, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title.isNotEmpty) Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
        GestureDetector(
          onTap: () {
            final userId = context.read<AppProvider>().currentUser?.id ?? '';
            AdminService().dismissBroadcast(_current!['id'], userId);
            setState(() => _visible = false);
          },
          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
        ),
      ]),
    );
  }
}
