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
import '../profile/profile_service.dart';

final _homeLoadProvider = FutureProvider((ref) async {
  final events = await ref.read(eventsServiceProvider).list();
  final stays = await ref.read(hebergementsServiceProvider).list();
  return {
    'events': events.take(8).toList(),
    'stays': stays.take(8).toList(),
  };
});

final _userNameProvider = FutureProvider.autoDispose((ref) async {
  try {
    final u = await ref.read(profileServiceProvider).me();
    return u.fullName ?? u.email ?? '';
  } catch (_) {
    return '';
  }
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final data = ref.watch(_homeLoadProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    final userName = ref.watch(_userNameProvider).value ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHero(
            greeting: _greeting(),
            userName: _firstName(userName),
            unread: unread,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 16),

          // Search bar
          _SearchBar()
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.06, end: 0),

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

          // Quick links row
          _QuickLinksRow()
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // AI Itinerary card
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
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Trip Planner',
                        style:
                            t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Let AI build a plan around your budget, dates & cities.',
                        style: t.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.62),
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
          ).animate().fadeIn(delay: 150.ms, duration: 420.ms),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String fullName) {
    if (fullName.isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/app?tab=1'),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded,
                color: const Color(0xFF0C6171).withOpacity(0.7), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search events, stays, transport...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C6171),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _QLinkData(
        icon: Icons.festival_rounded,
        label: 'Events',
        color: const Color(0xFFC96442),
        route: '/app?tab=1',
      ),
      _QLinkData(
        icon: Icons.hotel_rounded,
        label: 'Riads',
        color: const Color(0xFF0C6171),
        route: '/app?tab=1',
      ),
      _QLinkData(
        icon: Icons.train_rounded,
        label: 'Transport',
        color: const Color(0xFF197278),
        route: '/app?tab=1',
      ),
      _QLinkData(
        icon: Icons.route_rounded,
        label: 'Itinerary',
        color: const Color(0xFFD98F39),
        route: '/itinerary/planner',
      ),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: () => item.route.startsWith('/app')
                ? context.go(item.route)
                : context.push(item.route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: item.color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(item.icon, color: item.color, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QLinkData {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QLinkData(
      {required this.icon,
      required this.label,
      required this.color,
      required this.route});
}

class _HomeHero extends StatelessWidget {
  final String greeting;
  final String userName;
  final int unread;

  const _HomeHero({
    required this.greeting,
    required this.userName,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
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
            blurRadius: 32,
            offset: Offset(0, 16),
            color: Color(0x30000000),
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
                      userName.isNotEmpty
                          ? '$greeting, $userName!'
                          : '$greeting!',
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover Morocco\nbeyond the postcard',
                      style: t.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _HeroStat(value: '12+', label: 'Cities'),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _HeroStat(value: 'AI', label: 'Planning'),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _HeroStat(value: 'Live', label: 'Booking'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.2),
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
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      height: 240,
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
              ? '${price?.toStringAsFixed(0) ?? '-'} MAD/night'
              : '${price?.toStringAsFixed(0) ?? '-'} MAD';
          final subtitle = [
            if (city != null && city.isNotEmpty) city,
            priceLabel,
            if (eventDate != null) eventDate,
          ].join(' · ');
          final img = it.imageUrl?.toString();
          final tag = it is EventModel ? 'EVENT' : 'STAY';

          return InkWell(
            onTap: () => onTap(id),
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              width: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SafeNetworkImage(
                        imageUrl: img,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          decoration:
                              const BoxDecoration(gradient: AppGradients.oasis),
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
                    // Tag badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // Price badge
                    if (price != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD98F39).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${price.toStringAsFixed(0)} MAD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    // Content
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
                              fontSize: 17,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => Container(
          width: 220,
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
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load data. Check backend connection.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
