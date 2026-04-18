import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import 'gemini_chat_screen.dart';

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

  static const _modelNames = {
    '1': 'DeepSeek V3.2',
    '2': 'DeepSeek R1',
    '3': 'DeepSeek Coder'
  };

  @override
  void initState() {
    super.initState();
    _addBotMsg('مرحباً! أنا DeepSeek. اختر النموذج المناسب واسألني ما تريد.');
  }

  void _addBotMsg(String text, {bool isError = false}) {
    setState(() {
      _messages.insert(0, _AiMsg(text: text, isUser: false, time: DateTime.now(), isError: isError));
    });
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.insert(0, _AiMsg(text: text, isUser: true, time: DateTime.now()));
      _loading = true;
    });
    _ctrl.clear();

    try {
      final res = await AiService().chatWithDeepSeek(text, model: _model, conversationId: _conversationId);
      if (mounted) {
        setState(() {
          _loading = false;
          _addBotMsg(res['text']);
          _conversationId = res['conversationId'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _addBotMsg('عذراً، حدث خطأ في الاتصال بالخادم.', isError: true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = context.read<AppProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.mainGradient),
        child: SafeArea(child: Column(children: [
          _AiHeader(title: 'DeepSeek AI', onBack: () => Navigator.pop(context)),
          
          // Model Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: _modelNames.entries.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _model = e.key),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _model == e.key ? AppGradients.accentGradient : null,
                    color: _model == e.key ? null : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _model == e.key ? AppColors.accent : AppColors.glassBorder),
                  ),
                  child: Text(e.value, style: TextStyle(color: _model == e.key ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            )).toList()),
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
          _AiInputBar(ctrl: _ctrl, onSend: _send, loading: _loading, hint: 'اسأل DeepSeek...'),
        ])),
      ),
    );
  }
}

// الأجزاء المفقودة التي تم إضافتها لإصلاح الأخطاء
class _AiMsg {
  final String text;
  final bool isUser;
  final DateTime time;
  final bool isError;
  _AiMsg({required this.text, required this.isUser, required this.time, this.isError = false});
}

class _AiHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _AiHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  final _AiMsg msg;
  final String? userPhotoUrl;
  final String userName;
  const _AiMessageBubble({required this.msg, this.userPhotoUrl, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.accent.withOpacity(0.2) : AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: msg.isError ? Colors.red : AppColors.glassBorder),
              ),
              child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          if (msg.isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.bgCard,
      backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
      child: userPhotoUrl == null ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
    );
  }
}

class _AiInputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool loading;
  final String hint;
  const _AiInputBar({required this.ctrl, required this.onSend, required this.loading, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: AppColors.glassBorder))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          onPressed: loading ? null : onSend,
          icon: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, color: AppColors.accent),
        ),
      ]),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text('DeepSeek يكتب الآن...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
    );
  }
}
