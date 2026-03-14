import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/event_model.dart';
import '../../core/models/review_model.dart';
import '../../core/di/providers.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
import '../../core/ui/section_title.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../reviews/reviews_service.dart';
import 'events_service.dart';

final _eventProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, String id) async {
  final e = await ref.read(eventsServiceProvider).getById(id);
  final details = await ref.read(eventsServiceProvider).details(id);
  final availability = await ref.read(eventsServiceProvider).availability(id);
  final stats = await ref.read(reviewsServiceProvider).stats(type: 'EVENT', id: id);
  final reviews = await ref.read(reviewsServiceProvider).list(type: 'EVENT', id: id);
  return {
    'event': e,
    'details': details,
    'availability': availability,
    'stats': stats,
    'reviews': reviews,
  };
});

class EventDetailsPage extends ConsumerWidget {
  final String id;
  const EventDetailsPage({super.key, required this.id});

  bool _ensureAuthed(BuildContext context, WidgetRef ref) {
    final session = ref.read(authSessionProvider);
    if (session.isAuthenticated) return true;
    final from = GoRouterState.of(context).uri.toString();
    context.go('/auth/login?from=${Uri.encodeComponent(from)}');
    return false;
  }

  Future<void> _quickPay(BuildContext context, WidgetRef ref, EventModel e) async {
    if (!_ensureAuthed(context, ref)) return;
    final r = await ref.read(reservationsServiceProvider).createEvent(
          eventId: id,
          quantity: 1,
        );
    await ref.read(paymentsServiceProvider).payReservation(
          reservationId: r.id,
          amountMad: e.price ?? 0,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment success')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_eventProvider(id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (m) {
            final e = m['event'] as EventModel;
            final stats = Map<String, dynamic>.from((m['stats'] as Map?) ?? {});
            final details = Map<String, dynamic>.from((m['details'] as Map?) ?? {});
            final availability = m['availability'] == true;
            final reviews = (m['reviews'] as List<ReviewModel>);
            final dateStr = e.dateEvent != null
                ? DateFormat('EEE, MMM d • HH:mm').format(e.dateEvent!)
                : (e.dateEventRaw ?? '-');

            return ListView(
              children: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: SafeNetworkImage(
                        imageUrl: e.imageUrl,
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
                        e.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('${e.city ?? '-'} • $dateStr'),
                      const SizedBox(height: 6),
                      Text('${e.price ?? 0} MAD'),
                      const SizedBox(height: 6),
                      Text(
                        'Rating: ${stats['average'] ?? details['averageRating'] ?? '-'}',
                      ),
                      if (details['reviewCount'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Reviews: ${details['reviewCount']}'),
                      ],
                      Text(
                        'Availability: ${availability ? 'Available' : 'Unavailable'}',
                      ),
                      if (e.placesDisponibles != null) ...[
                        const SizedBox(height: 4),
                        Text('Places left: ${e.placesDisponibles}'),
                      ],
                      const SizedBox(height: 10),
                      Text(e.description ?? '-'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (_ensureAuthed(context, ref)) {
                                  context.push('/book/event/$id');
                                }
                              },
                              icon: const Icon(Icons.shopping_bag_rounded),
                              label: const Text('Reserver'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Payer maintenant',
                              icon: Icons.payments_rounded,
                              onTap: () async => _quickPay(context, ref, e),
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
                              extra: {'type': 'EVENT', 'targetId': id},
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
