import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  int rating = 5;
  final comment = TextEditingController();
  bool loading = false;

  Future<void> submit() async {
    final type = (widget.extra['type'] ?? '').toString();
    final targetId = (widget.extra['targetId'] ?? '').toString();
    if (type.isEmpty || targetId.isEmpty) return;
    if (comment.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await ref.read(reviewsServiceProvider).create(
            type: type,
            targetId: targetId,
            rating: rating.toDouble(),
            comment: comment.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review posted successfully.')),
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
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final type = (widget.extra['type'] ?? '').toString();
    final typeLabel = switch (type.toUpperCase()) {
      'EVENT' => 'Event',
      'HEBERGEMENT' => 'Stay',
      'TRANSPORT' => 'Transport',
      _ => type,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Write a Review')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'How was your experience?',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => rating = star);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: star <= rating
                                ? scheme.secondary
                                : scheme.onSurface.withOpacity(0.3),
                            size: 44,
                          ).animate(key: ValueKey('$star-$rating')).scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 150.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _ratingLabel(rating),
                    style: t.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: comment,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Share your experience...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Submit Review',
                  icon: Icons.send_rounded,
                  loading: loading,
                  onTap: submit,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Your review is sent to the live backend for this reservation.',
                    style: t.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
