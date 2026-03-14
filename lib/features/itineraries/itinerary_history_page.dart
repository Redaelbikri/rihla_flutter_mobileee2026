import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Itineraries')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (list) {
            if (list.isEmpty)
              return const GlassCard(child: Text('No itinerary history.'));
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final it = list[i];
                final payload = (it['payload'] is Map)
                    ? Map<String, dynamic>.from(it['payload'] as Map)
                    : <String, dynamic>{};
                final title =
                    payload['toCity'] ?? payload['fromCity'] ?? 'Itinerary';
                return GlassCard(
                  child: ListTile(
                    title: Text(
                      title.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle:
                        Text((it['createdAt'] ?? it['date'] ?? '').toString()),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Itinerary'),
                        content: SingleChildScrollView(
                            child: SelectableText(it.toString())),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
