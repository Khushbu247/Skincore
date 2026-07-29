import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class _Msg {
  final String text;
  final bool isUser;
  const _Msg(this.text, this.isUser);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [
    const _Msg("Hi Riya 👋 I'm your SkinCore assistant. I can explain your scan results, suggest routine tweaks, or bust a myth. What's on your mind?", false),
    const _Msg('Why did my score drop last week?', true),
    const _Msg('Looking at your logs, hydration was below target 4 days in a row and sunscreen reapplication was missed twice. Both correlate with your score dip. Want a reminder tweak?', false),
  ];

  final _suggestions = const ['Yes, adjust reminders', 'Explain my last scan', 'Is this normal for my age?'];

  void _send([String? text]) {
    final content = text ?? _controller.text.trim();
    if (content.isEmpty) return;
    setState(() {
      _messages.add(_Msg(content, true));
      _controller.clear();
    });
    // TODO(Phase 11): replace with a real call to POST /api/v1/chatbot/message
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(const _Msg(
            "Got it — I've noted that. In the full app this connects to the Gemini-powered assistant for a tailored answer.", false));
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Dermatology AI', style: TextStyle(fontSize: 15)),
            Text('● Online', style: TextStyle(fontSize: 10.5, color: AppColors.success)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 1,
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      children: _suggestions
                          .map((s) => GestureDetector(
                                onTap: () => _send(s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.purple, width: 1.3),
                                  ),
                                  child: Text(s, style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600, fontSize: 12)),
                                ),
                              ))
                          .toList(),
                    ),
                  );
                }
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: msg.isUser ? AppColors.brandGradient : null,
                      color: msg.isUser ? null : Theme.of(context).cardColor,
                      border: msg.isUser ? null : Border.all(color: const Color(0xFFEFE7F0)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(msg.isUser ? 18 : 6),
                        bottomRight: Radius.circular(msg.isUser ? 6 : 18),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.isUser ? Colors.white : AppColors.ink, fontSize: 13.5, height: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Ask about your skin...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
