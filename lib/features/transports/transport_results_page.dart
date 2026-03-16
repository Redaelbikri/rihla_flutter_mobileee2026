import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/trip_model.dart';
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

class TransportResultsPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_transportSearchProvider({
      'fromCity': fromCity,
      'toCity': toCity,
      'date': date,
      if (type != null) 'type': type!,
    }));

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF283593)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        _CityPill(city: fromCity, isOrigin: true),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white54, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                _typeIcon(type),
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        _CityPill(city: toCity, isOrigin: false),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text('$fromCity → $toCity',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: data.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      fromCity: fromCity,
                      toCity: toCity,
                      type: type,
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _TripCard(
                    trip: list[i],
                    index: i,
                    onTap: () =>
                        GoRouter.of(context).push('/trip/${list[i].id}'),
                  ),
                );
              },
              loading: () => SliverList.separated(
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _TripCardSkeleton(index: i),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.toString(),
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeIcon(String? t) {
    return switch ((t ?? '').toUpperCase()) {
      'BUS' => '🚌',
      'CAR' => '🚗',
      'FLIGHT' => '✈️',
      _ => '🚆',
    };
  }
}

// ─── City Pill ─────────────────────────────────────────────────────────────────
class _CityPill extends StatelessWidget {
  final String city;
  final bool isOrigin;
  const _CityPill({required this.city, required this.isOrigin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOrigin
                ? Icons.flight_takeoff_rounded
                : Icons.flight_land_rounded,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            city,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Trip Card ──────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final TripModel trip;
  final int index;
  final VoidCallback onTap;

  const _TripCard(
      {required this.trip, required this.index, required this.onTap});

  static const _typeColors = {
    'TRAIN': Color(0xFF1565C0),
    'BUS': Color(0xFF2E7D32),
    'CAR': Color(0xFFBF360C),
    'FLIGHT': Color(0xFF4527A0),
  };

  static const _typeIcons = {
    'TRAIN': Icons.train_rounded,
    'BUS': Icons.directions_bus_rounded,
    'CAR': Icons.directions_car_rounded,
    'FLIGHT': Icons.flight_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final color =
        _typeColors[trip.type?.toUpperCase()] ?? const Color(0xFF1565C0);
    final icon =
        _typeIcons[trip.type?.toUpperCase()] ?? Icons.directions_transit_rounded;

    final dep = trip.departureAt != null
        ? DateFormat('HH:mm').format(trip.departureAt!)
        : '--:--';
    final arr = trip.arrivalAt != null
        ? DateFormat('HH:mm').format(trip.arrivalAt!)
        : '--:--';
    final depDate = trip.departureAt != null
        ? DateFormat('MMM d').format(trip.departureAt!)
        : (trip.date ?? '');

    Duration? duration;
    if (trip.departureAt != null && trip.arrivalAt != null) {
      duration = trip.arrivalAt!.difference(trip.departureAt!);
    }
    final durationStr = duration != null
        ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip.type ?? 'Trip',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (trip.providerName != null &&
                      trip.providerName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trip.providerName!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    depDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Route timeline ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  // Departure
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep,
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.fromCity ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Timeline
                  Expanded(
                    child: Column(
                      children: [
                        if (durationStr != null)
                          Text(
                            durationStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withOpacity(0.45),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            Icon(icon, size: 16, color: color),
                            Expanded(
                              child: Container(
                                height: 2,
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: color, width: 2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Direct',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurface.withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrival
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arr,
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.toCity ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  if (trip.availableSeats != null) ...[
                    Icon(Icons.event_seat_rounded,
                        size: 14,
                        color: scheme.onSurface.withOpacity(0.45)),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.availableSeats} seats left',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trip.price == null
                            ? 'Price n/a'
                            : '${trip.price!.toStringAsFixed(0)} ${trip.currency ?? 'MAD'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: color,
                        ),
                      ),
                      Text(
                        'per seat',
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Select',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: index * 70), duration: 400.ms)
          .slideY(begin: 0.12, end: 0),
    );
  }
}

// ─── Skeleton loader ───────────────────────────────────────────────────────────
class _TripCardSkeleton extends StatelessWidget {
  final int index;
  const _TripCardSkeleton({required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white38)
        .fadeIn(delay: Duration(milliseconds: index * 80));
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final String? type;
  const _EmptyState(
      {required this.fromCity, required this.toCity, this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('🚫', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            'No trips found',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'No ${type ?? ''} trips from $fromCity to $toCity on $toCity.\nTry a different date or transport type.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Go back'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
