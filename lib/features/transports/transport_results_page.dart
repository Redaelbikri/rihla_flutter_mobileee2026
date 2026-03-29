import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/trip_model.dart';
import '../../core/ui/safe_network_image.dart';
import 'transports_service.dart';

final _transportSearchProvider = FutureProvider.autoDispose.family(
  (ref, Map<String, String> q) async {
    return ref.read(transportsServiceProvider).searchTrips(
          fromCity: q['fromCity']!,
          toCity: q['toCity']!,
          date: q['date']!,
          type: q['type'] ?? 'TRAIN',
        );
  },
);

class TransportResultsPage extends ConsumerStatefulWidget {
  final String fromCity;
  final String toCity;
  final String date;
  final String? type;

  const TransportResultsPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.date,
    this.type,
  });

  @override
  ConsumerState<TransportResultsPage> createState() => _TransportResultsPageState();
}

class _TransportResultsPageState extends ConsumerState<TransportResultsPage> {
  double _maxPrice = 1500;
  double _minRating = 4.0;
  String _locationFilter = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_transportSearchProvider({
      'fromCity': widget.fromCity,
      'toCity': widget.toCity,
      'date': widget.date,
      if (widget.type != null) 'type': widget.type!,
    }));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fromCity} to ${widget.toCity}'),
      ),
      body: Column(
        children: [
          _FiltersBar(
            maxPrice: _maxPrice,
            minRating: _minRating,
            locationFilter: _locationFilter,
            onPriceChanged: (v) => setState(() => _maxPrice = v),
            onRatingChanged: (v) => setState(() => _minRating = v),
            onLocationChanged: (v) => setState(() => _locationFilter = v.trim().toLowerCase()),
          ),
          Expanded(
            child: data.when(
              data: (list) {
                final filtered = list.where((trip) {
                  final price = trip.price ?? 0;
                  final rating = _ratingFor(trip);
                  final location = '${trip.fromCity ?? ''} ${trip.toCity ?? ''}'.toLowerCase();
                  return price <= _maxPrice && rating >= _minRating && (_locationFilter.isEmpty || location.contains(_locationFilter));
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No trips match these filters.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ResultCard(
                    trip: filtered[i],
                    index: i,
                    onTap: () => context.push('/trip/${filtered[i].id}'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  double _ratingFor(TripModel trip) {
    if (trip.capacity == null || trip.availableSeats == null || trip.capacity == 0) {
      return 4.6;
    }
    final usage = 1 - (trip.availableSeats! / trip.capacity!);
    return (4.2 + usage.clamp(0, 0.8)).clamp(4.0, 5.0);
  }
}

class _FiltersBar extends StatelessWidget {
  final double maxPrice;
  final double minRating;
  final String locationFilter;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onRatingChanged;
  final ValueChanged<String> onLocationChanged;

  const _FiltersBar({
    required this.maxPrice,
    required this.minRating,
    required this.locationFilter,
    required this.onPriceChanged,
    required this.onRatingChanged,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: const Color(0xFFF4F8FF),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterPill(
                  icon: Icons.payments_outlined,
                  label: 'Max ${maxPrice.round()} MAD',
                  onTap: () async {
                    final value = await showModalBottomSheet<double>(
                      context: context,
                      builder: (_) => _SliderSheet(
                        title: 'Maximum Price',
                        min: 100,
                        max: 2000,
                        value: maxPrice,
                      ),
                    );
                    if (value != null) onPriceChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPill(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating ${minRating.toStringAsFixed(1)}+',
                  onTap: () async {
                    final value = await showModalBottomSheet<double>(
                      context: context,
                      builder: (_) => _SliderSheet(
                        title: 'Minimum Rating',
                        min: 4.0,
                        max: 5.0,
                        step: 0.1,
                        value: minRating,
                      ),
                    );
                    if (value != null) onRatingChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onLocationChanged,
            decoration: InputDecoration(
              hintText: 'Filter by location',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: locationFilter.isNotEmpty ? const Icon(Icons.filter_alt_rounded) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final TripModel trip;
  final int index;
  final VoidCallback onTap;

  const _ResultCard({
    required this.trip,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dep = trip.departureAt != null ? DateFormat('HH:mm').format(trip.departureAt!) : '--:--';
    final arr = trip.arrivalAt != null ? DateFormat('HH:mm').format(trip.arrivalAt!) : '--:--';
    final price = (trip.price ?? 0).toStringAsFixed(0);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: SafeNetworkImage(
                  imageUrl: trip.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: const Color(0xFFE8F1FF),
                    child: const Icon(Icons.image_outlined, color: Color(0xFF9CB3D3)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${trip.fromCity ?? '-'} ? ${trip.toCity ?? '-'}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          (trip.type ?? 'Trip').toUpperCase(),
                          style: const TextStyle(color: Color(0xFF236ED4), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dep - $arr',
                    style: const TextStyle(color: Color(0xFF6A7F9C), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF5B400), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _ratingFor(trip).toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '$price ${trip.currency ?? 'MAD'}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1B74E4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 45 * index)).fadeIn().slideY(begin: 0.08, end: 0);
  }

  double _ratingFor(TripModel trip) {
    if (trip.capacity == null || trip.availableSeats == null || trip.capacity == 0) {
      return 4.6;
    }
    final usage = 1 - (trip.availableSeats! / trip.capacity!);
    return (4.2 + usage.clamp(0, 0.8)).clamp(4.0, 5.0);
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9E8FF)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2B73D8)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderSheet extends StatefulWidget {
  final String title;
  final double min;
  final double max;
  final double value;
  final double step;

  const _SliderSheet({
    required this.title,
    required this.min,
    required this.max,
    required this.value,
    this.step = 1,
  });

  @override
  State<_SliderSheet> createState() => _SliderSheetState();
}

class _SliderSheetState extends State<_SliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            Slider(
              min: widget.min,
              max: widget.max,
              value: _value,
              divisions: ((widget.max - widget.min) / widget.step).round(),
              label: widget.step < 1 ? _value.toStringAsFixed(1) : _value.round().toString(),
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _value),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


