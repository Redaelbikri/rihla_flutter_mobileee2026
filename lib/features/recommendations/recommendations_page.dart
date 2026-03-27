import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
import 'recommendations_service.dart';

final _recommendationsProvider = FutureProvider.autoDispose
    .family<RecommendationsBundle, (String, String, String, String, String, String)>((ref, q) async {
  final (city, category, fromCity, toCity, date, transportType) = q;
  return ref.read(recommendationsServiceProvider).fetch(
        city: city.isNotEmpty ? city : null,
        category: category.isNotEmpty ? category : null,
        fromCity: fromCity.isNotEmpty ? fromCity : null,
        toCity: toCity.isNotEmpty ? toCity : null,
        date: date.isNotEmpty ? date : null,
        transportType: transportType.isNotEmpty ? transportType : null,
      );
});

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() =>
      _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  final cityCtrl = TextEditingController(text: 'Marrakech');
  final categoryCtrl = TextEditingController();
  final fromCityCtrl = TextEditingController();
  final toCityCtrl = TextEditingController();
  String transportType = '';
  bool filtersExpanded = false;

  @override
  void dispose() {
    cityCtrl.dispose();
    categoryCtrl.dispose();
    fromCityCtrl.dispose();
    toCityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final data = ref.watch(_recommendationsProvider((
      cityCtrl.text.trim(),
      categoryCtrl.text.trim(),
      fromCityCtrl.text.trim(),
      toCityCtrl.text.trim(),
      '', // date not used in UI currently
      transportType,
    )));

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalized ideas for your next Moroccan escape',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Blend events, stays, and transport around one city or route.',
                  style: t.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                ),
                if (filtersExpanded) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Event category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fromCityCtrl,
                          decoration: const InputDecoration(labelText: 'From city'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: toCityCtrl,
                          decoration: const InputDecoration(labelText: 'To city'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['', 'TRAIN', 'BUS', 'CAR', 'FLIGHT']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value.isEmpty ? 'Any transport' : value),
                            selected: transportType == value,
                            onSelected: (_) => setState(() => transportType = value),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Refresh Recommendations',
                        icon: Icons.recommend_rounded,
                        onTap: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        filtersExpanded = !filtersExpanded;
                      }),
                      child: Text(filtersExpanded ? 'Less' : 'Filters'),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          data.when(
            data: (bundle) => _BundleView(bundle: bundle),
            loading: () => Column(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1000.ms),
                ),
              ),
            ),
            error: (e, _) => GlassCard(
              child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleView extends StatelessWidget {
  final RecommendationsBundle bundle;

  const _BundleView({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final hasData = bundle.events.isNotEmpty || bundle.stays.isNotEmpty || bundle.trips.isNotEmpty;
    if (!hasData) {
      return const GlassCard(
        child: Column(
          children: [
            Icon(Icons.travel_explore_rounded, size: 44, color: Color(0xFF0C6171)),
            SizedBox(height: 10),
            Text(
              'No recommendations matched these filters yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'Try another city, transport route, or broader budget to get backend-powered suggestions.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _Section(
          title: 'Recommended Events',
          icon: Icons.festival_rounded,
          empty: bundle.events.isEmpty,
          children: bundle.events
              .map(
                (e) => _CardItem(
                  title: e.title,
                  subtitle:
                      '${e.city ?? '-'} | ${e.price?.toStringAsFixed(0) ?? '-'} MAD',
                  imageUrl: e.imageUrl,
                  onTap: () => GoRouter.of(context).push('/event/${e.id}'),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        _Section(
          title: 'Recommended Stays',
          icon: Icons.hotel_rounded,
          empty: bundle.stays.isEmpty,
          children: bundle.stays
              .map(
                (s) => _CardItem(
                  title: s.name,
                  subtitle:
                      '${s.city ?? '-'} | ${s.pricePerNight?.toStringAsFixed(0) ?? '-'} MAD / night',
                  imageUrl: s.imageUrl,
                  onTap: () => GoRouter.of(context).push('/stay/${s.id}'),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        _Section(
          title: 'Recommended Transport',
          icon: Icons.train_rounded,
          empty: bundle.trips.isEmpty,
          children: bundle.trips
              .map(
                (trip) => _CardItem(
                  title: '${trip.fromCity ?? '-'} -> ${trip.toCity ?? '-'}',
                  subtitle:
                      '${trip.type ?? '-'} | ${trip.price?.toStringAsFixed(0) ?? '-'} MAD',
                  imageUrl: trip.imageUrl,
                  onTap: () => GoRouter.of(context).push('/trip/${trip.id}'),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool empty;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.empty,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: scheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        if (empty)
          GlassCard(
            child: Row(
              children: [
                Icon(Icons.search_off_rounded, color: scheme.onSurface.withOpacity(0.3)),
                const SizedBox(width: 8),
                Text('No results for current filters', style: t.bodyMedium),
              ],
            ),
          )
        else
          ...children,
      ],
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: SafeNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: scheme.primary.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
