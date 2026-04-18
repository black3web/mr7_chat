import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../services/story_service.dart';
import '../../models/story_model.dart';
import '../../widgets/user_avatar.dart';

class StoryViewScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  const StoryViewScreen({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progCtrl;
  int _current = 0;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _progCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _progCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
    _loadStory();
  }

  void _loadStory() {
    final story = widget.stories[_current];
    final currentUser = context.read<AppProvider>().currentUser;
    final userId = currentUser?.id ?? '';
    
    if (userId.isNotEmpty) {
      StoryService().viewStory(story.id, userId);
    }
    
    _progCtrl.reset();
    if (story.mediaType == StoryMediaType.video) {
      _videoCtrl?.dispose();
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          _videoCtrl!.play();
          _progCtrl.duration = _videoCtrl!.value.duration;
          _progCtrl.forward();
        });
    } else {
      _videoReady = false;
      _videoCtrl?.dispose();
      _videoCtrl = null;
      _progCtrl.duration = const Duration(seconds: 5);
      _progCtrl.forward();
    }
    setState(() {});
  }

  void _next() {
    if (_current < widget.stories.length - 1) {
      setState(() => _current++);
      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _loadStory();
    }
  }

  @override
  void dispose() {
    _progCtrl.dispose();
    _videoCtrl?.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_current];
    final appProvider = context.read<AppProvider>();
    final me = appProvider.currentUser;
    
    // التحقق من وجود المستخدم لتجنب أخطاء Null
    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final isOwn = story.userId == me.id;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          if (d.globalPosition.dx < MediaQuery.of(context).size.width / 2) {
            _prev();
          } else {
            _next();
          }
        },
        child: Stack(
          children: [
            // Media Layer
            Positioned.fill(
              child: story.mediaType == StoryMediaType.video && _videoReady && _videoCtrl != null
                  ? AspectRatio(
                      aspectRatio: _videoCtrl!.value.aspectRatio,
                      child: VideoPlayer(_videoCtrl!),
                    )
                  : CachedNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                    ),
            ),
            
            // Progress bars
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: List.generate(
                      widget.stories.length,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < widget.stories.length - 1 ? 4 : 0),
                          child: AnimatedBuilder(
                            animation: _progCtrl,
                            builder: (_, __) => LinearProgressIndicator(
                              value: i < _current ? 1.0 : i == _current ? _progCtrl.value : 0.0,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 2.5,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // User info & Actions
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      UserAvatar(photoUrl: story.userPhotoUrl, name: story.userName, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                shadows: [Shadow(blurRadius: 4)],
                              ),
                            ),
                            Text(
                              'منذ قليل',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isOwn)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          color: AppColors.bgCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (v) async {
                            if (v == 'delete') {
                              await StoryService().deleteStory(story.id);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded, color: AppColors.accent, size: 18),
                                  SizedBox(width: 8),
                                  Text('حذف القصة', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Description
            if (story.description != null && story.description!.isNotEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Text(
                  story.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    shadows: [Shadow(blurRadius: 8)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
            // Bottom bar - comment + like
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _commentCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'اكتب تعليقا...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (text) async {
                              if (text.trim().isEmpty) return;
                              _commentCtrl.clear();
                              // منطق إرسال الرسالة الخاصة يوضع هنا
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => StoryService().reactToStory(story.id, me.id, 'heart'),
                        child: const Icon(Icons.favorite_border_rounded, size: 28, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
