import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/review_model.dart';
import '../../core/models/trip_model.dart';
import '../../core/di/providers.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
import '../../core/ui/section_title.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../reviews/reviews_service.dart';
import 'transports_service.dart';

final _tripProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, String id) async {
  final t = await ref.read(transportsServiceProvider).getTrip(id);
  final stats = await ref.read(transportsServiceProvider).ratingStats(id);
  final check = await ref.read(transportsServiceProvider).checkAvailability(id);
  final reviews =
      await ref.read(reviewsServiceProvider).list(type: 'TRANSPORT', id: id);
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
    final r = await ref.read(reservationsServiceProvider).createTransport(
          tripId: id,
          quantity: 1,
        );
    await ref.read(paymentsServiceProvider).payReservation(
          reservationId: r.id,
          amountMad: tr.price ?? 0,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment success')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_tripProvider(id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Transport Details')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (m) {
            final tr = m['trip'] as TripModel;
            final stats = Map<String, dynamic>.from((m['stats'] as Map?) ?? {});
            final check = m['check'] == true;
            final reviews = (m['reviews'] as List<ReviewModel>);
            final dep =
                tr.departureAt != null ? DateFormat('MMM d • HH:mm').format(tr.departureAt!) : '-';
            final arr =
                tr.arrivalAt != null ? DateFormat('MMM d • HH:mm').format(tr.arrivalAt!) : '-';

            return ListView(
              children: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: SafeNetworkImage(
                        imageUrl: tr.imageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            Container(color: scheme.primary.withOpacity(0.10)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tr.fromCity ?? '-'} -> ${tr.toCity ?? '-'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('${tr.type ?? '-'} • $dep → $arr'),
                      const SizedBox(height: 6),
                      Text('Price: ${tr.price ?? 0} ${tr.currency ?? 'MAD'}'),
                      Text(
                        'Rating: ${stats['average'] ?? stats['averageRating'] ?? '-'}',
                      ),
                      Text('Availability: ${check ? 'Available' : 'Unavailable'}'),
                      if (tr.availableSeats != null) ...[
                        const SizedBox(height: 4),
                        Text('Seats left: ${tr.availableSeats}'),
                      ],
                      if ((tr.providerName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Provider: ${tr.providerName}'),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (_ensureAuthed(context, ref)) {
                                  context.push('/book/transport/$id');
                                }
                              },
                              icon: const Icon(Icons.confirmation_num_rounded),
                              label: const Text('Reserver'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Payer maintenant',
                              icon: Icons.payments_rounded,
                              onTap: () async => _quickPay(context, ref, tr),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (_ensureAuthed(context, ref)) {
                            context.push(
                              '/review/new',
                              extra: {'type': 'TRANSPORT', 'targetId': id},
                            );
                          }
                        },
                        icon: const Icon(Icons.rate_review_rounded),
                        label: const Text('Write review'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const SectionTitle('Reviews'),
                if (reviews.isEmpty) const GlassCard(child: Text('No reviews yet')),
                ...reviews.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: ListTile(
                        title: Text(
                          r.comment,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('★ ${r.rating.toStringAsFixed(1)}'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
