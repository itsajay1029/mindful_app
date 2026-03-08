import 'package:flutter/material.dart';

/// MVP Coach (AI Q&A): chat UI with placeholder responses.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromCoach: true,
      text: 'Hello! What would you like to focus on today?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(fromCoach: false, text: text));
      _messages.add(_ChatMessage(fromCoach: true, text: _coachReply(text)));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _coachReply(String userText) {
    final t = userText.toLowerCase();
    if (t.contains('motivation')) {
      return 'Let’s make it easy: pick a 2‑minute action you can do right now. What’s the smallest win?';
    }
    if (t.contains('conflict') || t.contains('disagree')) {
      return 'Try this script: “Help me understand what matters most to you here.” Then reflect back what you heard.';
    }
    if (t.contains('stress') || t.contains('burn')) {
      return 'Quick reset: 4‑second inhale, 6‑second exhale for 5 cycles. Want a 5‑minute reset audio?';
    }
    return 'Got it. Here’s a simple next step: define the goal, list 2 options, and pick the smallest experiment for today.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text('Coach Guide')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return _Bubble(message: m);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything…',
                      filled: true,
                      fillColor: const Color(0xFFF6F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  child: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCoach = message.fromCoach;

    final bubbleColor = isCoach ? Colors.white : cs.primary;
    final textColor = isCoach ? Colors.black.withValues(alpha: 0.85) : Colors.white;

    return Align(
      alignment: isCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          border: isCoach ? Border.all(color: Colors.black.withValues(alpha: 0.06)) : null,
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.05),
            )
          ],
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromCoach, required this.text});
  final bool fromCoach;
  final String text;
}
