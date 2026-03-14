import 'package:flutter/material.dart';
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
import '../transports/transport_search_sheet.dart';

final _eventsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(eventsServiceProvider).list();
});

final _staysProvider = FutureProvider.autoDispose.family(
  (ref, Map<String, String> query) async {
    return ref.read(hebergementsServiceProvider).list(
          city: query['city'],
          type: query['type'],
        );
  },
);

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  final eventQ = TextEditingController();
  final hotelCity = TextEditingController(text: 'Marrakech');
  String hotelType = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    eventQ.dispose();
    hotelCity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final events = ref.watch(_eventsProvider);
    final stays = ref.watch(_staysProvider({
      'city': hotelCity.text.trim(),
      'type': hotelType,
    }));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore the best of Morocco',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Search culture, stays, and transport from one discovery hub.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: tabs,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: scheme.primary,
                  unselectedLabelColor: scheme.onSurface.withOpacity(0.54),
                  tabs: const [
                    Tab(text: 'Events'),
                    Tab(text: 'Stays'),
                    Tab(text: 'Transport'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: eventQ,
                          decoration: const InputDecoration(
                            labelText: 'Search events or festivals',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final query = eventQ.text.trim();
                              if (query.isEmpty) return;
                              final list = await ref
                                  .read(eventsServiceProvider)
                                  .list(keyword: query);
                              if (!context.mounted) return;
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (_) => _SearchResults(
                                  title: 'Event results',
                                  items: list.take(20).toList(),
                                  onTap: (id) {
                                    Navigator.pop(context);
                                    context.push('/event/$id');
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.travel_explore_rounded),
                            label: const Text('Search events'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Popular right now'),
                  const SizedBox(height: 10),
                  events.when(
                    data: (list) => _GridCards(
                      items: list.take(10).toList(),
                      onTap: (id) => context.push('/event/$id'),
                      scheme: scheme,
                    ),
                    loading: () => const _GridLoading(),
                    error: (e, _) => GlassCard(child: Text(e.toString())),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: hotelCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: hotelType.isEmpty ? null : hotelType,
                          decoration: const InputDecoration(
                            labelText: 'Stay type',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'HOTEL', child: Text('Hotel')),
                            DropdownMenuItem(value: 'RIAD', child: Text('Riad')),
                            DropdownMenuItem(value: 'HOSTEL', child: Text('Hostel')),
                            DropdownMenuItem(value: 'AIRBNB', child: Text('Airbnb')),
                            DropdownMenuItem(value: 'RESORT', child: Text('Resort')),
                            DropdownMenuItem(value: 'GUESTHOUSE', child: Text('Guest House')),
                          ],
                          onChanged: (value) => setState(() => hotelType = value ?? ''),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Refresh stays'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Handpicked stays'),
                  const SizedBox(height: 10),
                  stays.when(
                    data: (list) => _GridCards(
                      items: list.take(10).toList(),
                      onTap: (id) => context.push('/stay/$id'),
                      scheme: scheme,
                    ),
                    loading: () => const _GridLoading(),
                    error: (e, _) => GlassCard(child: Text(e.toString())),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search trains, buses, cars, and flights',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Open the transport search sheet and query your backend-connected trip inventory.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurface.withOpacity(0.68)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => showTransportSearch(context),
                            icon: const Icon(Icons.train_rounded),
                            label: const Text('Open transport search'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridCards extends StatelessWidget {
  final List items;
  final void Function(String id) onTap;
  final ColorScheme scheme;

  const _GridCards({
    required this.items,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 232,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
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
            ? [
                if ((it.city ?? '').isNotEmpty) it.city!,
                '${it.price?.toStringAsFixed(0) ?? '-'} MAD',
                if (eventDate != null) eventDate,
              ].join(' | ')
            : it is HebergementModel
                ? [
                    if ((it.city ?? '').isNotEmpty) it.city!,
                    '${it.pricePerNight?.toStringAsFixed(0) ?? '-'} MAD / night',
                  ].join(' | ')
                : '';
        final img = it.imageUrl?.toString();

        return InkWell(
          onTap: () => onTap(id),
          borderRadius: BorderRadius.circular(26),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.6)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 10),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(26)),
                    child: SafeNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      placeholder: Container(color: scheme.primary.withOpacity(0.08)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.64),
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
    );
  }
}

class _GridLoading extends StatelessWidget {
  const _GridLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 232,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(26),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final String title;
  final List items;
  final void Function(String id) onTap;

  const _SearchResults({
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ...items.map((it) {
            final id = it.id.toString();
            final name = it is EventModel
                ? it.title
                : it is HebergementModel
                    ? it.name
                    : 'Item';
            return ListTile(
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onTap(id),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
