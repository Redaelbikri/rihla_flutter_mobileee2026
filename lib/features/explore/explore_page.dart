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

// ── Providers ────────────────────────────────────────────────────────────────

final _eventsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(eventsServiceProvider).list();
});

/// Key is a Dart record (city, type) — uses value equality, not reference
/// equality, so auto-dispose no longer kills the request before it resolves.
final _staysProvider =
    FutureProvider.autoDispose.family<List<HebergementModel>, (String, String)>(
  (ref, params) async {
    final (city, type) = params;
    return ref.read(hebergementsServiceProvider).list(
          city: city.isEmpty ? null : city,
          type: type.isEmpty ? null : type,
        );
  },
);

// ── ExplorePage ───────────────────────────────────────────────────────────────

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
    eventQ.dispose();
    hotelCity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final events = ref.watch(_eventsProvider);
    final stays = ref.watch(_staysProvider((
      hotelCity.text.trim(),
      hotelType,
    )));

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
              // ── Events tab (unchanged) ──────────────────────────────────
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

              // ── Stays tab (fixed provider key + dropdown) ───────────────
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
                            DropdownMenuItem(
                                value: 'HOTEL', child: Text('Hotel')),
                            DropdownMenuItem(
                                value: 'AIRBNB', child: Text('Airbnb')),
                            DropdownMenuItem(
                                value: 'GUEST_HOUSE',
                                child: Text('Guest House')),
                          ],
                          onChanged: (value) =>
                              setState(() => hotelType = value ?? ''),
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

              // ── Transport tab (full redesign) ───────────────────────────
              const _TransportTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Transport Tab ─────────────────────────────────────────────────────────────

class _TransportTab extends StatefulWidget {
  const _TransportTab();

  @override
  State<_TransportTab> createState() => _TransportTabState();
}

class _TransportTabState extends State<_TransportTab> {
  final _fromCity = TextEditingController();
  final _toCity = TextEditingController();
  DateTime? _travelDate;
  String _type = 'TRAIN';

  static const _primaryColor = Color(0xFF0C6171);
  static const _secondaryColor = Color(0xFF197278);

  static const _types = [
    ('TRAIN', Icons.train_rounded, 'Train'),
    ('BUS', Icons.directions_bus_rounded, 'Bus'),
    ('CAR', Icons.directions_car_rounded, 'Car'),
    ('FLIGHT', Icons.flight_rounded, 'Flight'),
  ];

  static const _popularRoutes = [
    (
      from: 'Casablanca',
      to: 'Marrakech',
      icon: Icons.train_rounded,
      price: 89,
      type: 'TRAIN',
    ),
    (
      from: 'Fes',
      to: 'Rabat',
      icon: Icons.directions_bus_rounded,
      price: 45,
      type: 'BUS',
    ),
    (
      from: 'Tangier',
      to: 'Agadir',
      icon: Icons.flight_rounded,
      price: 320,
      type: 'FLIGHT',
    ),
  ];

  @override
  void dispose() {
    _fromCity.dispose();
    _toCity.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  void _search() {
    final from = _fromCity.text.trim();
    final to = _toCity.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both From and To cities.')),
      );
      return;
    }
    final date = _travelDate != null
        ? DateFormat('yyyy-MM-dd').format(_travelDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    context.push(
      '/transport/results?fromCity=$from&toCity=$to&date=$date&type=$_type',
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: _primaryColor, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _travelDate != null
        ? DateFormat('EEE, MMM d yyyy').format(_travelDate!)
        : 'Select travel date';

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      children: [
        // ── Search form card ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 24,
                offset: Offset(0, 8),
                color: Color(0x18000000),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.route_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your ride',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                      ),
                      Text(
                        'Trains, buses, cars & flights',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // From field
              TextField(
                controller: _fromCity,
                style: const TextStyle(color: Colors.black87),
                decoration: _fieldDecoration(
                  label: 'From city',
                  icon: Icons.flight_takeoff_rounded,
                ),
              ),
              const SizedBox(height: 10),

              // Swap arrow
              Center(
                child: GestureDetector(
                  onTap: () {
                    final tmp = _fromCity.text;
                    _fromCity.text = _toCity.text;
                    _toCity.text = tmp;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert_rounded,
                        color: _primaryColor, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // To field
              TextField(
                controller: _toCity,
                style: const TextStyle(color: Colors.black87),
                decoration: _fieldDecoration(
                  label: 'To city',
                  icon: Icons.flight_land_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // Date picker row
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: Colors.grey.shade500, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            color: _travelDate != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down_rounded,
                          color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Transport type chips
              Text(
                'Transport type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _types.map((t) {
                  final (value, icon, label) = t;
                  final selected = _type == value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color:
                                  selected ? Colors.white : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        selected: selected,
                        selectedColor: _primaryColor,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? _primaryColor
                                : Colors.grey.shade200,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onSelected: (_) => setState(() => _type = value),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Search button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 22),
                    label: const Text(
                      'Search Transport',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Popular routes section ────────────────────────────────────────
        const SectionTitle('Popular routes'),
        const SizedBox(height: 12),

        ..._popularRoutes.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PopularRouteCard(
              from: route.from,
              to: route.to,
              icon: route.icon,
              price: route.price,
              onTap: () {
                _fromCity.text = route.from;
                _toCity.text = route.to;
                setState(() => _type = route.type);
              },
            ),
          );
        }),
      ],
    );
  }
}

// ── Popular Route Card ────────────────────────────────────────────────────────

class _PopularRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final IconData icon;
  final int price;
  final VoidCallback onTap;

  const _PopularRouteCard({
    required this.from,
    required this.to,
    required this.icon,
    required this.price,
    required this.onTap,
  });

  static const _primaryColor = Color(0xFF0C6171);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.7)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              offset: Offset(0, 6),
              color: Color(0x10000000),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primaryColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Route label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        from,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Colors.black45),
                      ),
                      Text(
                        to,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From $price MAD',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Tap to pre-fill hint
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Use',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets (unchanged) ────────────────────────────────────────────────

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
                      placeholder:
                          Container(color: scheme.primary.withOpacity(0.08)),
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
                        style:
                            const TextStyle(fontWeight: FontWeight.w800),
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
              title:
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
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
