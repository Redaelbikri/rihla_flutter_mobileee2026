import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/review_model.dart';
import '../../core/models/trip_model.dart';
import '../../core/di/providers.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../reviews/reviews_service.dart';
import 'transports_service.dart';

final _tripProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, String id) async {
  final t = await ref.read(transportsServiceProvider).getTrip(id);
  final stats = await ref.read(transportsServiceProvider).ratingStats(id).catchError((_) => <String, dynamic>{});
  final check = await ref.read(transportsServiceProvider).checkAvailability(id).catchError((_) => false);
  final reviews = await ref.read(reviewsServiceProvider).list(type: 'TRANSPORT', id: id).catchError((_) => <ReviewModel>[]);
  return {'trip': t, 'stats': stats, 'check': check, 'reviews': reviews};
});

class TripDetailsPage extends ConsumerWidget {
  final String id;
  const TripDetailsPage({super.key, required this.id});

  bool _ensureAuthed(BuildContext context, WidgetRef ref) {
    final session = ref.read(authSessionProvider);
    if (session.isAuthenticated) return true;
    final from = GoRouterState.of(context).uri.toString();
    context.go('/auth/login?from=${Uri.encodeComponent(from)}');
    return false;
  }

  Future<void> _quickPay(BuildContext context, WidgetRef ref, TripModel tr) async {
    if (!_ensureAuthed(context, ref)) return;
    try {
      final r = await ref.read(reservationsServiceProvider).createTransport(
            tripId: id,
            quantity: 1,
          );
      await ref.read(paymentsServiceProvider).payReservation(
            reservationId: r.id,
            amountMad: tr.price ?? 0,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: Colors.green),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  IconData _transportIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'BUS': return Icons.directions_bus_rounded;
      case 'TRAIN': return Icons.train_rounded;
      case 'FLIGHT':
      case 'AIR': return Icons.flight_rounded;
      case 'CAR':
      case 'TAXI': return Icons.directions_car_rounded;
      case 'FERRY':
      case 'BOAT': return Icons.directions_boat_rounded;
      default: return Icons.commute_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_tripProvider(id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: data.when(
        data: (m) {
          final tr = m['trip'] as TripModel;
          final stats = Map<String, dynamic>.from((m['stats'] as Map?) ?? {});
          final check = m['check'] == true;
          final reviews = (m['reviews'] as List<ReviewModel>);
          final avgRating = (stats['average'] ?? stats['averageRating'] ?? 0.0) as num;
          final dep = tr.departureAt != null
              ? DateFormat('MMM d • HH:mm').format(tr.departureAt!)
              : '-';
          final arr = tr.arrivalAt != null
              ? DateFormat('MMM d • HH:mm').format(tr.arrivalAt!)
              : '-';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: scheme.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      SafeNetworkImage(
                        imageUrl: tr.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [scheme.primary, scheme.secondary],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      // Route display at the bottom
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((tr.type ?? '').isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_transportIcon(tr.type), size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      (tr.type ?? '').toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tr.fromCity ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Icon(_transportIcon(tr.type),
                                    color: Colors.white.withOpacity(0.7), size: 20),
                                Expanded(
                                  child: Text(
                                    tr.toCity ?? '-',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outline.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Departure',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface.withOpacity(0.5),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dep,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: scheme.outline.withOpacity(0.3),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Arrival',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface.withOpacity(0.5),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    arr,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 16),
                      // Rating + availability row
                      Row(
                        children: [
                          _StarRatingBar(rating: avgRating.toDouble()),
                          const SizedBox(width: 8),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          _AvailabilityBadge(available: check),
                        ],
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 20),
                      // Price + seats card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sell_rounded, color: scheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tr.price ?? 0} ${tr.currency ?? 'MAD'}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: scheme.primary,
                                  ),
                                ),
                                const Text('per seat', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            if (tr.availableSeats != null) ...[
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${tr.availableSeats}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: scheme.secondary,
                                    ),
                                  ),
                                  const Text('seats left', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      if ((tr.providerName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business_rounded,
                                  size: 16, color: scheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text(
                                'Operated by ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                tr.providerName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 250.ms),
                      ],
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                if (_ensureAuthed(context, ref)) {
                                  context.push('/book/transport/$id');
                                }
                              },
                              icon: const Icon(Icons.confirmation_num_rounded),
                              label: const Text('Book'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Pay Now',
                              icon: Icons.payments_rounded,
                              onTap: () async => _quickPay(context, ref, tr),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (_ensureAuthed(context, ref)) {
                              context.push(
                                '/review/new',
                                extra: {'type': 'TRANSPORT', 'targetId': id},
                              );
                            }
                          },
                          icon: const Icon(Icons.rate_review_rounded),
                          label: const Text('Write a Review'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 32),
                      // Reviews section
                      Row(
                        children: [
                          Text(
                            'Reviews',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Spacer(),
                          if (reviews.isNotEmpty)
                            Text(
                              '${reviews.length} total',
                              style: TextStyle(
                                color: scheme.onSurface.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 12),
                      if (reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_rounded,
                                  size: 40, color: scheme.onSurface.withOpacity(0.3)),
                              const SizedBox(height: 8),
                              Text(
                                'No reviews yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                'Be the first to share your experience!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                      ...reviews.asMap().entries.map((entry) {
                        final i = entry.key;
                        final r = entry.value;
                        return _ReviewCard(review: r, scheme: scheme)
                            .animate()
                            .fadeIn(delay: (450 + i * 80).ms)
                            .slideY(begin: 0.2, end: 0);
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

class _StarRatingBar extends StatelessWidget {
  final double rating;
  const _StarRatingBar({required this.rating});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, size: 18, color: scheme.secondary);
        } else if (i < rating) {
          return Icon(Icons.star_half_rounded, size: 18, color: scheme.secondary);
        }
        return Icon(Icons.star_outline_rounded, size: 18, color: scheme.secondary.withOpacity(0.4));
      }),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool available;
  const _AvailabilityBadge({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: available ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: available ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            available ? 'Available' : 'Unavailable',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: available ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final ColorScheme scheme;
  const _ReviewCard({required this.review, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary.withOpacity(0.2),
                child: Text(
                  (review.userName?.isNotEmpty == true)
                      ? review.userName![0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 13,
                            color: scheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: TextStyle(
              height: 1.5,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
