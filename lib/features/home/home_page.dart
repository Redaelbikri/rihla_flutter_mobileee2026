import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/event_model.dart';
import '../../core/models/hebergement_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/gradients.dart';
import '../../core/ui/safe_network_image.dart';
import '../../core/ui/section_title.dart';
import '../events/events_service.dart';
import '../hebergements/hebergements_service.dart';
import '../notifications/notifications_service.dart';

final _homeLoadProvider = FutureProvider((ref) async {
  final events = await ref.read(eventsServiceProvider).list();
  final stays = await ref.read(hebergementsServiceProvider).list();
  return {
    'events': events.take(6).toList(),
    'stays': stays.take(6).toList(),
  };
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(_homeLoadProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHero(greeting: _greeting(), unread: unread)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: 22),
          SectionTitle(
            'Trending Events',
            action: 'See all',
            onAction: () => context.go('/app?tab=1'),
          ),
          const SizedBox(height: 12),
          data.when(
            data: (m) => _HorizontalCards(
              items: (m['events'] as List),
              onTap: (id) => context.push('/event/$id'),
            ),
            loading: () => const _ShimmerRow(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 22),
          SectionTitle(
            'Iconic Stays',
            action: 'See all',
            onAction: () => context.go('/app?tab=1'),
          ),
          const SizedBox(height: 12),
          data.when(
            data: (m) => _HorizontalCards(
              items: (m['stays'] as List),
              onTap: (id) => context.push('/stay/$id'),
            ),
            loading: () => const _ShimmerRow(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 22),
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.oasis,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child:
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a custom Morocco itinerary?',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Let the assistant build a plan around your budget, dates, and preferred cities.',
                        style: t.bodyMedium?.copyWith(
                          color: scheme.onSurface.withOpacity(0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.push('/assistant'),
                  child: const Text('Open'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 420.ms),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HomeHero extends StatelessWidget {
  final String greeting;
  final int unread;

  const _HomeHero({required this.greeting, required this.unread});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF184E57),
            Color(0xFF0E6B72),
            Color(0xFFD98F39),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 28,
            offset: Offset(0, 16),
            color: Color(0x26000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover Morocco beyond the postcard',
                      style: t.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAction(
                icon: Icons.festival_rounded,
                label: 'Festivals',
                onTap: () => context.go('/app?tab=1'),
              ),
              _QuickAction(
                icon: Icons.hotel_rounded,
                label: 'Riads & Hotels',
                onTap: () => context.go('/app?tab=1'),
              ),
              _QuickAction(
                icon: Icons.train_rounded,
                label: 'Transport',
                onTap: () => context.go('/app?tab=1'),
              ),
              _QuickAction(
                icon: Icons.route_rounded,
                label: 'Itinerary',
                onTap: () => context.push('/itinerary/planner'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    value: '12+',
                    label: 'Cities ready to explore',
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    value: 'Live',
                    label: 'Backend-ready discovery',
                  ),
                ),
                Expanded(
                  child: _HeroStat(
                    value: 'AI',
                    label: 'Personal travel planning',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalCards extends StatelessWidget {
  final List items;
  final void Function(String id) onTap;

  const _HorizontalCards({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
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
          final price = it is EventModel
              ? it.price
              : it is HebergementModel
                  ? it.pricePerNight
                  : null;
          final city = it is EventModel
              ? it.city
              : it is HebergementModel
                  ? it.city
                  : null;
          final priceLabel = it is HebergementModel
              ? '${price?.toStringAsFixed(0) ?? '-'} MAD / night'
              : '${price?.toStringAsFixed(0) ?? '-'} MAD';
          final subtitle = [
            if (city != null && city.isNotEmpty) city,
            priceLabel,
            if (eventDate != null) eventDate,
          ].join(' | ');
          final img = it.imageUrl?.toString();

          return InkWell(
            onTap: () => onTap(id),
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 238,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SafeNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          decoration: const BoxDecoration(gradient: AppGradients.oasis),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppGradients.sunsetOverlay,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          it is EventModel ? 'EVENT' : 'STAY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.86),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => Container(
          width: 238,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(28),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1000.ms),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
