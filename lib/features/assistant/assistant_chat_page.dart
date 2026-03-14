import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'assistant_service.dart';

class AssistantChatPage extends ConsumerStatefulWidget {
  const AssistantChatPage({super.key});

  @override
  ConsumerState<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends ConsumerState<AssistantChatPage> {
  final input = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool loading = false;

  final quickPrompts = const [
    'Suggest a weekend in Marrakech',
    'Build a 3-day Fes itinerary',
    'Recommend cheap transport options',
    'Plan a desert trip from Casablanca',
  ];

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    setState(() {
      messages.add({'role': 'user', 'text': text});
      loading = true;
    });

    try {
      final reply = await ref.read(assistantServiceProvider).chat(text);
      setState(() => messages.add({'role': 'assistant', 'text': reply}));
    } catch (e) {
      setState(() => messages.add({'role': 'assistant', 'text': e.toString()}));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await sendMessage(text);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Travel Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Morocco trip copilot',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ask for routes, budgets, places to stay, events, and day-by-day itineraries.',
                    style: t.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.68),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickPrompts
                        .map(
                          (prompt) => ActionChip(
                            label: Text(prompt),
                            onPressed: loading ? null : () => sendMessage(prompt),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: messages.length + (loading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (loading && i == messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: _TypingCard(),
                    );
                  }
                  final message = messages[i];
                  final isUser = message['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: isUser
                            ? Text(
                                message['text'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              )
                            : MarkdownBody(
                                data: message['text'] ?? '',
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ask anything about your trip',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Send message',
                    icon: Icons.send_rounded,
                    loading: loading,
                    onTap: send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingCard extends StatelessWidget {
  const _TypingCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        'Assistant is thinking...',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
