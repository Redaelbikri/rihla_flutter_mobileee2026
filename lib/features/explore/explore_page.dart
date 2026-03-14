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
  (ref, Map<String, String> q) async {
    return ref.read(hebergementsServiceProvider).list(
          city: q['city'],
          type: q['type'],
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
  final hotelCity = TextEditingController();
  String hotelType = '';

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
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
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: TabBar(
            controller: tabs,
            tabs: const [
              Tab(text: 'Events'),
              Tab(text: 'Hotels'),
              Tab(text: 'Transport'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
                children: [
                  GlassCard(
                    child: TextField(
                      controller: eventQ,
                      decoration: InputDecoration(
                        labelText: 'Search events',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () async {
                            final q = eventQ.text.trim();
                            if (q.isEmpty) return;
                            final list =
                                await ref.read(eventsServiceProvider).list(keyword: q);
                            if (!mounted) return;
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
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle('Events'),
                  events.when(
                    data: (list) => _GridCards(
                      items: list.take(10).toList(),
                      onTap: (id) => context.push('/event/$id'),
                      scheme: scheme,
                    ),
                    loading: () => const _GridLoading(),
                    error: (e, _) => Text(e.toString()),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: hotelCity,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: hotelType.isEmpty ? null : hotelType,
                          decoration:
                              const InputDecoration(labelText: 'Hotel type'),
                          items: const [
                            DropdownMenuItem(value: 'HOTEL', child: Text('HOTEL')),
                            DropdownMenuItem(value: 'RIAD', child: Text('RIAD')),
                            DropdownMenuItem(
                                value: 'APPARTEMENT',
                                child: Text('APPARTEMENT')),
                            DropdownMenuItem(
                                value: 'MAISON_HOTE',
                                child: Text('MAISON_HOTE')),
                          ],
                          onChanged: (v) => setState(() => hotelType = v ?? ''),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref.invalidate(_staysProvider);
                            },
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Search hotels'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionTitle('Hotels'),
                  stays.when(
                    data: (list) => _GridCards(
                      items: list.take(10).toList(),
                      onTap: (id) => context.push('/stay/$id'),
                      scheme: scheme,
                    ),
                    loading: () => const _GridLoading(),
                    error: (e, _) => Text(e.toString()),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transport search',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => showTransportSearch(context),
                          icon: const Icon(Icons.train_rounded),
                          label: const Text('Open transport search'),
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
        mainAxisExtent: 190,
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
            ? '${it.city ?? '-'} • ${it.price?.toStringAsFixed(0) ?? '-'} MAD${eventDate != null ? ' • $eventDate' : ''}'
            : it is HebergementModel
                ? '${it.city ?? '-'} • ${it.pricePerNight?.toStringAsFixed(0) ?? '-'} MAD/night'
                : '';
        final img = it.imageUrl?.toString();

        return InkWell(
          onTap: () => onTap(id),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x11FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SafeNetworkImage(
                      imageUrl: img,
                      fit: BoxFit.cover,
                      placeholder: Container(color: scheme.primary.withOpacity(0.10)),
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
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                )
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
        mainAxisExtent: 190,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(24),
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
                  ?.copyWith(fontWeight: FontWeight.w900),
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
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
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
