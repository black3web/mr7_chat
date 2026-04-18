import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_chat_widgets.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});
  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<AiMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(AiMessage(
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
      _messages.insert(0,
          AiMessage(text: text, isUser: true, time: DateTime.now()));
      _loading = true;
    });
    try {
      final reply = await AiService().geminiChat(text, userId);
      if (mounted) {
        setState(() => _messages.insert(
            0, AiMessage(text: reply, isUser: false, time: DateTime.now())));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.insert(
            0,
            AiMessage(
                text: 'حدث خطأ. حاول مجددا.',
                isUser: false,
                time: DateTime.now(),
                isError: true)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
            AiScreenHeader(
              title: 'Gemini 2.5 Flash',
              subtitle: 'Google AI',
              color: const Color(0xFF4285F4),
              icon: Icons.auto_awesome_rounded,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                reverse: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (_loading && i == 0) return const AiTypingIndicator();
                  final msg = _messages[_loading ? i - 1 : i];
                  return AiMessageBubble(
                    msg: msg,
                    userPhotoUrl: me?.photoUrl,
                    userName: me?.name ?? '?',
                  );
                },
              ),
            ),
            AiInputBar(
              ctrl: _ctrl,
              onSend: _send,
              loading: _loading,
              hint: l['sendPrompt'],
            ),
          ]),
        ),
      ),
    );
  }
}