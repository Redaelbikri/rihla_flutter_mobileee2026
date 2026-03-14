import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/ui/glass.dart';
import 'itineraries_service.dart';

final _historyProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(itinerariesServiceProvider).myHistory();
});

class ItineraryHistoryPage extends ConsumerWidget {
  const ItineraryHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_historyProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Itineraries')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 56, color: scheme.primary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text('No itineraries yet',
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text('Plan your first trip with AI.'),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/itinerary/planner'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Plan a trip'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final it = list[i];
                final payload = (it['payload'] is Map)
                    ? Map<String, dynamic>.from(it['payload'] as Map)
                    : <String, dynamic>{};
                final fromCity = payload['fromCity']?.toString() ?? '-';
                final toCity = payload['toCity']?.toString() ?? '-';
                final dateStr = _formatDate(
                    it['createdAt']?.toString() ?? it['date']?.toString());
                final days = (payload['days'] as List?)?.length ?? 0;

                return GlassCard(
                  child: InkWell(
                    onTap: () => context.push('/itinerary/result', extra: payload),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.map_rounded, color: scheme.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$fromCity → $toCity',
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (days > 0) ...[
                                    _Badge(label: '$days days', color: scheme.primary),
                                    const SizedBox(width: 6),
                                  ],
                                  if (dateStr != null)
                                    Text(dateStr,
                                        style: t.bodySmall?.copyWith(
                                            color: scheme.onSurface.withOpacity(0.5))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: scheme.primary),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                    delay: Duration(milliseconds: i * 50), duration: 350.ms);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(e.toString(), style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
