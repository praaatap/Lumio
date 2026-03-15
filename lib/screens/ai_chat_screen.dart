import 'package:flutter/material.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  static const routeName = '/ai-chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI ASSISTANT',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 3,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: const [
                _SpeakerLabel('AI'),
                _ChatBubble(
                  text:
                      'Hello. I am FlowMind. How may I assist your workflow today?',
                  isAi: true,
                ),
                SizedBox(height: 20),
                _ChatBubble(
                  text:
                      'I need to outline a new project strategy for a minimal UI kit.',
                  isAi: false,
                ),
                SizedBox(height: 20),
                _SpeakerLabel('AI'),
                _ChatBubble(
                  text:
                      'A minimal UI kit focuses on essential functional elements. Should we start with typography scale or core primitives?',
                  isAi: true,
                ),
                SizedBox(height: 20),
                _ChatBubble(
                  text:
                      'Let\'s begin with core primitives. I want everything to feel airy and precise.',
                  isAi: false,
                ),
                SizedBox(height: 20),
                _SpeakerLabel('AI'),
                _ChatBubble(
                  text:
                      'Understood. For an airy feel, we should prioritize generous whitespace and thin stroke weights. I can generate a list of base components next.',
                  isAi: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'FlowMind AI can make mistakes. Check important info.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerLabel extends StatelessWidget {
  const _SpeakerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(letterSpacing: 2),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isAi});

  final String text;
  final bool isAi;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 530),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isAi ? const Color(0xFFF1F1F3) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
