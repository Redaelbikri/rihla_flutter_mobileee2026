import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/safe_network_image.dart';
import 'recommendations_service.dart';

final _recommendationsProvider = FutureProvider.autoDispose.family<RecommendationsBundle, Map<String, String>>((ref, q) async {
  return ref.read(recommendationsServiceProvider).fetch(
        city: q['city'],
        category: q['category'],
        fromCity: q['fromCity'],
        toCity: q['toCity'],
        date: q['date'],
        transportType: q['transportType'],
      );
});

class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const q = <String, String>{'city': 'Marrakech'};
    final data = ref.watch(_recommendationsProvider(q));

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (bundle) => ListView(
            children: [
              _Section(
                title: 'Recommended events',
                children: bundle.events
                    .map((e) => _CardItem(
                          title: e.title,
                          subtitle: '${e.city ?? '-'} • ${e.price?.toStringAsFixed(2) ?? '-'} MAD',
                          imageUrl: e.imageUrl,
                          onTap: () => context.push('/event/${e.id}'),
                        ))
                    .toList(),
              ),
              _Section(
                title: 'Recommended stays',
                children: bundle.stays
                    .map((s) => _CardItem(
                          title: s.name,
                          subtitle: '${s.city ?? '-'} • ${s.pricePerNight?.toStringAsFixed(2) ?? '-'} MAD/night',
                          imageUrl: s.imageUrl,
                          onTap: () => context.push('/stay/${s.id}'),
                        ))
                    .toList(),
              ),
              _Section(
                title: 'Recommended trips',
                children: bundle.trips
                    .map((t) => _CardItem(
                          title: '${t.fromCity ?? '-'} → ${t.toCity ?? '-'}',
                          subtitle: '${t.type ?? '-'} • ${t.price?.toStringAsFixed(2) ?? '-'} MAD',
                          imageUrl: t.imageUrl,
                          onTap: () => context.push('/trip/${t.id}'),
                        ))
                    .toList(),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(child: Text('$title: no results for current filters.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CardItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 56,
              height: 56,
              child: SafeNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: Container(color: Theme.of(context).colorScheme.primary.withOpacity(0.08)),
              ),
            ),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        ),
      ),
    );
  }
}
