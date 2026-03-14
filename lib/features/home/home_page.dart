import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/event_model.dart';
import '../../core/models/hebergement_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/safe_network_image.dart';
import '../../core/ui/section_title.dart';
import '../events/events_service.dart';
import '../hebergements/hebergements_service.dart';

final _homeLoadProvider = FutureProvider((ref) async {
  final events = await ref.read(eventsServiceProvider).list();
  final stays = await ref.read(hebergementsServiceProvider).list();
  return {
    'events': events.take(5).toList(),
    'stays': stays.take(5).toList(),
  };
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(_homeLoadProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover the magic of Morocco',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Events, stays, transport and AI itineraries - all in one premium experience.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Shortcut(
                      icon: Icons.festival_rounded,
                      label: 'Events',
                      onTap: () => context.go('/app?tab=1'),
                    ),
                    _Shortcut(
                      icon: Icons.hotel_rounded,
                      label: 'Stays',
                      onTap: () => context.go('/app?tab=1'),
                    ),
                    _Shortcut(
                      icon: Icons.train_rounded,
                      label: 'Transport',
                      onTap: () => context.go('/app?tab=1'),
                    ),
                    _Shortcut(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Plan',
                      onTap: () => context.push('/itinerary/planner'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/recommendations'),
                    icon: const Icon(Icons.recommend_rounded),
                    label: const Text('Open recommendations'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/itinerary/planner'),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('AI Itinerary'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/assistant'),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Assistant'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 14),
          SectionTitle('Trending events'),
          data.when(
            data: (m) => _HorizontalCards(
              items: (m['events'] as List),
              onTap: (id) => context.push('/event/$id'),
              scheme: scheme,
            ),
            loading: () => const _ShimmerRow(),
            error: (e, _) => Text(e.toString()),
          ),
          const SizedBox(height: 16),
          SectionTitle('Top stays'),
          data.when(
            data: (m) => _HorizontalCards(
              items: (m['stays'] as List),
              onTap: (id) => context.push('/stay/$id'),
              scheme: scheme,
            ),
            loading: () => const _ShimmerRow(),
            error: (e, _) => Text(e.toString()),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 64,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x11FFFFFF)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalCards extends StatelessWidget {
  final List items;
  final void Function(String id) onTap;
  final ColorScheme scheme;

  const _HorizontalCards({
    required this.items,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          final id = it.id.toString();
          final title = it is EventModel
              ? it.title
              : it is HebergementModel
                  ? it.name
                  : 'Item';
          final eventDate = it is EventModel && it.dateEvent != null
              ? DateFormat('MMM d').format(it.dateEvent!)
              : null;
          final subtitle = it is EventModel
              ? '${it.city ?? '-'} • ${it.price?.toStringAsFixed(0) ?? '-'} MAD${eventDate != null ? ' • $eventDate' : ''}'
              : it is HebergementModel
                  ? '${it.city ?? '-'} • ${it.pricePerNight?.toStringAsFixed(0) ?? '-'} MAD/night'
                  : '';
          final img = it.imageUrl?.toString();

          return InkWell(
            onTap: () => onTap(id),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x11FFFFFF)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SafeNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: Container(color: scheme.primary.withOpacity(0.10)),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1000.ms),
      ),
    );
  }
}
