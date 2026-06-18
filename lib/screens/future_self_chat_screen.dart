import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/operator_style.dart';
import 'package:operator_os/providers/ai_providers.dart';
import 'package:operator_os/providers/ai_service_provider.dart';
import 'package:operator_os/providers/auth_provider.dart';
import 'package:operator_os/widgets/operator_card.dart';

class FutureSelfChatScreen extends ConsumerStatefulWidget {
  const FutureSelfChatScreen({super.key});

  @override
  ConsumerState<FutureSelfChatScreen> createState() => _FutureSelfChatScreenState();
}

class _FutureSelfChatScreenState extends ConsumerState<FutureSelfChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _typing = false;

  static const _quickPrompts = [
    'What am I avoiding?',
    'What should I focus on this week?',
    'What would future me regret?',
    'What is the next high-leverage move?',
    'Where am I lying to myself?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _typing = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final rag = ref.read(ragServiceProvider);
      final ai = ref.read(aiServiceProvider);

      final memoryContext = await rag.buildContext(userId, text, k: 8);
      final prompt = '''You are the user's future self, 5 years ahead, speaking through Operator OS.
You have witnessed the outcomes of their current habits, quests, decisions, and Campaign Seasons.
Use the context below from their journal, missions, and weekly reviews.
Do not pretend to know things outside the context. If memory is thin, say that clearly.

Context:
$memoryContext

User: $text

Return this structure when useful:
FUTURE SELF — direct answer
HARD TRUTH — what they may be avoiding
NEXT MOVE — one action
MEMORY SIGNAL — what context influenced the answer

Future Self:''';

      final response = await ai.generateText(prompt, maxTokens: 650);
      setState(() {
        _messages.add(_Message(
          text: response ?? 'The future is unclear right now. Keep building.',
          isUser: false,
          memoryContext: memoryContext,
        ));
        _typing = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(text: 'Error: $e', isUser: false));
        _typing = false;
      });
    }
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final showIntro = _messages.isEmpty && !_typing;
    return Scaffold(
      backgroundColor: OperatorPalette.voidBlack,
      appBar: AppBar(
        title: const Text('Future Self Portal'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: showIntro ? 1 : _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, index) {
                if (showIntro) return _PortalIntro(onPrompt: _send);
                if (index == _messages.length && _typing) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          if (!showIntro)
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(prompt),
                    onPressed: _typing ? null : () => _send(prompt),
                  );
                },
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask your future self...',
                        filled: true,
                        fillColor: OperatorPalette.panelDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _typing ? null : () => _send(),
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

class _PortalIntro extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const _PortalIntro({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    return OperatorCard(
      label: 'FUTURE SELF PORTAL',
      title: 'Ask about the decision underneath the decision.',
      icon: Icons.forum_outlined,
      accentColor: OperatorPalette.hologramBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FUTURE SELF PORTAL', style: OperatorTextStyles.overline),
          const SizedBox(height: 8),
          const Text('Ask about the decision underneath the decision.', style: OperatorTextStyles.title),
          const SizedBox(height: 8),
          const Text(
            'The portal uses Memory Archive context when available. Stronger reflections create stronger answers.',
            style: OperatorTextStyles.body,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _FutureSelfChatScreenState._quickPrompts.map((prompt) {
              return ActionChip(
                label: Text(prompt),
                onPressed: () => onPrompt(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final String? memoryContext;

  _Message({required this.text, required this.isUser, this.memoryContext});
}

class _ChatBubble extends StatelessWidget {
  final _Message message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final hasMemory = !message.isUser &&
        message.memoryContext != null &&
        message.memoryContext!.trim().isNotEmpty &&
        message.memoryContext != 'No relevant entries found.';

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser
              ? OperatorPalette.parchmentGold
              : OperatorPalette.panelRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: message.isUser
                ? OperatorPalette.parchmentGold
                : OperatorPalette.borderDim,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? OperatorPalette.voidBlack : OperatorPalette.textPrimary,
                height: 1.35,
              ),
            ),
            if (hasMemory) ...[
              const SizedBox(height: 10),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: OperatorPalette.hologramBlue,
                collapsedIconColor: OperatorPalette.textMuted,
                title: const Text('Memory signal used', style: OperatorTextStyles.muted),
                children: [
                  Text(
                    message.memoryContext!,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: OperatorTextStyles.muted,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
