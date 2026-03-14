import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
    'Suggest a weekend trip',
    'Recommend events near me',
    'Build a 3-day itinerary',
    'Find cheap transport options',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: messages.length + (loading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (loading && i == messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: GlassCard(child: Text('Assistant is typing...')),
                    );
                  }
                  final m = messages[i];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: GlassCard(
                        child: isUser
                            ? Text(
                                m['text'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              )
                            : MarkdownBody(
                                data: m['text'] ?? '',
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontWeight: FontWeight.w700),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: quickPrompts
                          .map(
                            (p) => ActionChip(
                              label: Text(p),
                              onPressed: loading ? null : () => sendMessage(p),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Ask anything...'),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Send',
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
