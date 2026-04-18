import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../widgets/user_avatar.dart';

// ==========================================
// Gemini Chat Screen
// ==========================================
class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});
  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_AiMsg> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_AiMsg(
      text: 'مرحبا! انا Gemini 2.5 Flash. كيف يمكنني مساعدتك اليوم؟',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    _scroll.dispose(); 
    super.dispose(); 
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    _ctrl.clear();
    
    setState(() {
      _messages.insert(0, _AiMsg(text: text, isUser: true, time: DateTime.now()));
      _loading = true;
    });
    
    try {
      final reply = await AiService().geminiChat(text, userId);
      setState(() => _messages.insert(0, _AiMsg(text: reply, isUser: false, time: DateTime.now())));
    } catch (e) {
      setState(() => _messages.insert(0, _AiMsg(text: 'حدث خطأ. حاول مجددا.', isUser: false, time: DateTime.now(), isError: true)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = context.read<AppProvider>().currentUser;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            const _AiHeader(
              title: 'Gemini 2.5 Flash', 
              subtitle: 'Google AI', 
              color: Color(0xFF4285F4), 
              icon: Icons.auto_awesome_rounded
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_loading && i == 0) return const _TypingIndicator();
                  final msg = _messages[_loading ? i - 1 : i];
                  return _AiMessageBubble(msg: msg, userPhotoUrl: me?.photoUrl, userName: me?.name ?? '?');
                },
              ),
            ),
            _AiInputBar(ctrl: _ctrl, onSend: _send, loading: _loading, hint: l['sendPrompt']),
          ]),
        ),
      ),
    );
  }
}

// ==========================================
// DeepSeek Chat Screen
// ==========================================
class DeepSeekChatScreen extends StatefulWidget {
  const DeepSeekChatScreen({super.key});
  @override
  State<DeepSeekChatScreen> createState() => _DeepSeekChatScreenState();
}

class _DeepSeekChatScreenState extends State<DeepSeekChatScreen> {
  final _ctrl = TextEditingController();
  final List<_AiMsg> _messages = [];
  bool _loading = false;
  String _model = '1';
  String? _conversationId;

  static const _modelNames = {'1': 'DeepSeek V3.2', '2': 'DeepSeek R1', '3': 'DeepSeek Coder'};

  @override
  void initState() {
    super.initState();
    _messages.add(_AiMsg(
      text: 'مرحبا! انا DeepSeek. يمكنك الاختيار بين نماذج متعددة. كيف يمكنني مساعدتك؟', 
      isUser: false, 
      time: DateTime.now()
    ));
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    
    final userId = context.read<AppProvider>().currentUser?.id ?? '';
    _ctrl.clear();
    
    setState(() { 
      _messages.insert(0, _AiMsg(text: text, isUser: true, time: DateTime.now())); 
      _loading = true; 
    });
    
    try {
      final result = await AiService().deepSeekChat(text, userId, model: _model, conversationId: _conversationId);
      _conversationId = result['conversation_id'] as String?;
      setState(() => _messages.insert(0, _AiMsg(text: result['response'] as String, isUser: false, time: DateTime.now())));
    } catch (e) {
      setState(() => _messages.insert(0, _AiMsg(text: 'حدث خطأ. حاول مجددا.', isUser: false, time: DateTime.now(), isError: true)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = context.read<AppProvider>().currentUser;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            _AiHeader(
              title: 'DeepSeek', 
              subtitle: _modelNames[_model] ?? 'DeepSeek', 
              color: const Color(0xFF00BCD4), 
              icon: Icons.auto_awesome_rounded
            ),
            
            // Model selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: _modelNames.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { 
                      setState(() { 
                        _model = e.key; 
                        _conversationId = null; 
                        _messages.clear(); 
                        _messages.add(_AiMsg(text: 'تم تغيير النموذج الى ${e.value}', isUser: false, time: DateTime.now())); 
                      }); 
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _model == e.key ? const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]) : null,
                        color: _model == e.key ? null : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _model == e.key ? AppColors.accent : AppColors.glassBorder),
                      ),
                      child: Text(
                        e.value, 
                        style: TextStyle(
                          color: _model == e.key ? Colors.white : AppColors.textSecondary, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                    ),
                  ),
                )).toList()
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_loading && i == 0) return const _TypingIndicator();
                  final msg = _messages[_loading ? i - 1 : i];
                  return _AiMessageBubble(msg: msg, userPhotoUrl: me?.photoUrl, userName: me?.name ?? '?');
                },
              ),
            ),
            _AiInputBar(ctrl: _ctrl, onSend: _send, loading: _loading, hint: l['sendPrompt']),
          ]),
        ),
      ),
    );
  }
}

// ==========================================
// Shared AI widgets
// ==========================================
class _AiMsg {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;
  const _AiMsg({required this.text, required this.isUser, required this.time, this.isError = false});
}

class _AiHeader extends StatelessWidget {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  
  const _AiHeader({
    required this.title, 
    required this.subtitle, 
    required this.color, 
    required this.icon
  });
  
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.bgMedium, 
      border: Border(bottom: BorderSide(color: AppColors.glassBorder))
    ),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textSecondary), 
        onPressed: () => Navigator.pop(context)
      ),
      Container(
        width: 38, height: 38, 
        decoration: BoxDecoration(
          color: color.withOpacity(0.2), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: color.withOpacity(0.3))
        ), 
        child: Icon(icon, size: 20, color: color)
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: color)),
        ]
      ),
    ]),
  );
}

class _AiMessageBubble extends StatelessWidget {
  final _AiMsg msg;
  final String? userPhotoUrl;
  final String userName;
  
  const _AiMessageBubble({
    required this.msg, 
    this.userPhotoUrl, 
    required this.userName
  });
  
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 10, left: msg.isUser ? 48 : 0, right: msg.isUser ? 0 : 48),
    child: Row(
      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!msg.isUser) ...[
          Container(
            width: 30, height: 30, 
            decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(10)), 
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white)
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: msg.isUser ? AppColors.bubbleSelf : (msg.isError ? AppColors.accent.withOpacity(0.15) : AppColors.bubbleOther),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 18),
              ),
              border: Border.all(color: msg.isUser ? AppColors.bubbleSelfBorder : AppColors.bubbleOtherBorder),
            ),
            child: SelectableText(
              msg.text, 
              style: TextStyle(color: msg.isError ? AppColors.accent : Colors.white, fontSize: 14, height: 1.5)
            ),
          ),
        ),
        if (msg.isUser) ...[
          const SizedBox(width: 8),
          UserAvatar(photoUrl: userPhotoUrl, name: userName, size: 28),
        ],
      ],
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }
  
  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 30, height: 30, 
        decoration: BoxDecoration(gradient: AppGradients.accentGradient, borderRadius: BorderRadius.circular(10)), 
        child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white)
      ),
      const SizedBox(width: 8),
      AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bubbleOther, 
            borderRadius: BorderRadius.circular(18), 
            border: Border.all(color: AppColors.bubbleOtherBorder)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, 
            children: List.generate(3, (i) => Container(
              margin: EdgeInsets.only(left: i > 0 ? 5 : 0),
              width: 7, height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: AppColors.accent.withOpacity(_anim.value - i * 0.15 > 0.2 ? _anim.value - i * 0.15 : 0.2)
              ),
            ))
          ),
        ),
      ),
    ]),
  );
}

class _AiInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool loading;
  final dynamic hint; // Changed to dynamic to handle possible translation return types
  
  const _AiInputBar({
    required this.ctrl, 
    required this.onSend, 
    required this.loading, 
    required this.hint
  });
  
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: const BoxDecoration(
      color: AppColors.bgMedium, 
      border: Border(top: BorderSide(color: AppColors.glassBorder))
    ),
    child: Row(children: [
      Expanded(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 120),
          decoration: BoxDecoration(
            color: AppColors.bgLight, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: AppColors.glassBorder)
          ),
          child: TextField(
            controller: ctrl,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint.toString(), 
              border: InputBorder.none, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: loading ? null : onSend,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: loading ? null : AppGradients.accentGradient, 
            color: loading ? AppColors.bgLight : null, 
            borderRadius: BorderRadius.circular(14)
          ),
          child: loading 
            ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent)) 
            : const Icon(Icons.send_rounded, size: 22, color: Colors.white),
        ),
      ),
    ]),
  );
}
