import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';
import 'widgets/chat_history_drawer.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isThinking = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _currentSessionId;
  String _currentSessionTitle = 'New Chat';
  List<ChatMessage> _messages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final l10n = AppLocalizations.of(context);
    _messages = [
      ChatMessage(
        text: "${l10n.translate('chat_welcome_title')}\n\n${l10n.translate('chat_welcome_sub')}",
        isUser: false,
        timestamp: DateTime.now(),
      )
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _cleanText(String input) {
    String text = input;
    // Remove markdown headers like ### or ##
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    // Remove horizontal lines ---
    text = text.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');
    // Remove blockquote >
    text = text.replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '');
    // Remove bold asterisks like *** or **
    text = text.replaceAll('***', '').replaceAll('**', '');
    return text.trim();
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentSessionTitle = 'New Chat';
      _addWelcomeMessage();
    });
  }

  void _loadSession(ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _currentSessionTitle = session.title;
      _messages = List.from(session.messages);
    });
    _scrollToBottom();
  }

  Future<void> _saveSession() async {
    if (_messages.length <= 1) return; // Only welcome message

    if (_currentSessionId == null) {
      _currentSessionId = DateTime.now().microsecondsSinceEpoch.toString();
      
      // Auto-generate title from the first user message
      final firstUserMsg = _messages.firstWhere((m) => m.isUser, orElse: () => _messages.first);
      final rawTitle = firstUserMsg.text.split('\n').first;
      _currentSessionTitle = rawTitle.length > 30 ? '${rawTitle.substring(0, 30)}...' : rawTitle;
    }

    final session = ChatSession(
      id: _currentSessionId!,
      title: _currentSessionTitle,
      updatedAt: DateTime.now(),
      messages: _messages,
    );
    
    await ref.read(chatRepositoryProvider).saveChatSession(session);
  }

  Future<void> _sendMessage([String? presetText]) async {
    final String query = (presetText ?? _textController.text).trim();
    if (query.isEmpty || _isThinking) return;

    final l10n = AppLocalizations.of(context);

    if (presetText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isThinking = true;
    });

    _scrollToBottom();
    // Save state after user message
    _saveSession();

    final history = _messages
        .where((m) => m.text.isNotEmpty)
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    final langCode = l10n.locale.languageCode;
    String langInstruction = '';
    if (langCode == 'hi') {
      langInstruction = '[User Language Preference: Please answer in Hindi (हिन्दी)]\n';
    } else if (langCode == 'mr') {
      langInstruction = '[User Language Preference: Please answer in Marathi (मराठी)]\n';
    }

    try {
      final apiService = ref.read(apiServiceProvider);
      final String rawReply = await apiService.sendChatMessage(
        '$langInstruction$query',
        history: history,
      );

      final String cleanReply = _cleanText(rawReply);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: cleanReply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
        // Save state after assistant message
        _saveSession();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: l10n.translate('chat_offline_fallback'),
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final faqQuestions = [
      l10n.translate('chat_faq_1'),
      l10n.translate('chat_faq_2'),
      l10n.translate('chat_faq_3'),
      l10n.translate('chat_faq_4'),
      l10n.translate('chat_faq_5'),
      l10n.translate('chat_faq_6'),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatHistoryDrawer(
        currentSessionId: _currentSessionId ?? '',
        onSessionSelected: _loadSession,
        onNewChat: _startNewChat,
      ),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('chat_appbar_title'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.translate('chat_active_status'),
                          style: const TextStyle(fontSize: 10.5, color: AppColors.success),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 20),
            tooltip: 'Chat History',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            tooltip: 'New Chat',
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // FAQ Header Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : const Color(0xFFF7EFF9),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.lineDark : AppColors.lineLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 14, color: AppColors.purple),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.translate('chat_faq_title'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: faqQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          elevation: 0,
                          pressElevation: 1,
                          side: BorderSide(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          backgroundColor: isDark
                              ? AppColors.purple.withValues(alpha: 0.15)
                              : Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                          label: Text(question),
                          onPressed: () => _sendMessage(question),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isThinking && index == _messages.length) {
                  return _buildThinkingBubble(isDark);
                }

                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Input Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.lineDark : AppColors.lineLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.bgLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.lineDark : AppColors.lineLight,
                        ),
                      ),
                      child: KeyboardListener(
                        focusNode: _inputFocusNode,
                        onKeyEvent: (KeyEvent event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              !HardwareKeyboard.instance.isShiftPressed) {
                            _sendMessage();
                          }
                        },
                        child: TextField(
                          controller: _textController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          maxLines: 4,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: l10n.translate('chat_input_hint'),
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8, top: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: msg.isUser ? AppColors.brandGradient : null,
                  color: msg.isUser
                      ? null
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  border: msg.isUser
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.lineDark : AppColors.lineLight,
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                  ),
                  boxShadow: msg.isUser
                      ? null
                      : [
                          BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: SelectableText(
                  msg.text,
                  style: TextStyle(
                    color: msg.isUser
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.ink),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.lineLight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'SkinCore AI is thinking...',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.mutedLight : AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
