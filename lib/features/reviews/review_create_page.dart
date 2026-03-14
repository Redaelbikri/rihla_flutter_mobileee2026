import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'reviews_service.dart';

class ReviewCreatePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> extra; // {type, targetId}
  const ReviewCreatePage({super.key, required this.extra});

  @override
  ConsumerState<ReviewCreatePage> createState() => _ReviewCreatePageState();
}

class _ReviewCreatePageState extends ConsumerState<ReviewCreatePage> {
  double rating = 4.5;
  final comment = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    final type = (widget.extra['type'] ?? '').toString();
    final targetId = (widget.extra['targetId'] ?? '').toString();
    if (type.isEmpty || targetId.isEmpty) return;

    setState(() => loading = true);
    try {
      await ref.read(reviewsServiceProvider).create(
            type: type,
            targetId: targetId,
            rating: rating,
            comment: comment.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review posted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write review')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating: ${rating.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 40,
                    onChanged: (v) => setState(() => rating = v),
                  ),
                  TextField(
                    controller: comment,
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Submit',
                    icon: Icons.send_rounded,
                    loading: loading,
                    onTap: submit,
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
