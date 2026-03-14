import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/hebergement_model.dart';
import '../../core/models/review_model.dart';
import '../../core/di/providers.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
import '../../core/ui/section_title.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../reviews/reviews_service.dart';
import 'hebergements_service.dart';

final _stayProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, String id) async {
  final s = await ref.read(hebergementsServiceProvider).getById(id);
  final stats = await ref.read(hebergementsServiceProvider).ratingStats(id);
  final check = await ref.read(hebergementsServiceProvider).checkAvailability(id);
  final reviews =
      await ref.read(reviewsServiceProvider).list(type: 'ACCOMMODATION', id: id);
  return {'stay': s, 'stats': stats, 'check': check, 'reviews': reviews};
});

class HebergementDetailsPage extends ConsumerWidget {
  final String id;
  const HebergementDetailsPage({super.key, required this.id});

  bool _ensureAuthed(BuildContext context, WidgetRef ref) {
    final session = ref.read(authSessionProvider);
    if (session.isAuthenticated) return true;
    final from = GoRouterState.of(context).uri.toString();
    context.go('/auth/login?from=${Uri.encodeComponent(from)}');
    return false;
  }

  Future<void> _quickPay(
    BuildContext context,
    WidgetRef ref,
    HebergementModel stay,
  ) async {
    if (!_ensureAuthed(context, ref)) return;
    final r = await ref.read(reservationsServiceProvider).createHebergement(
          hebergementId: id,
          quantity: 1,
        );
    await ref.read(paymentsServiceProvider).payReservation(
          reservationId: r.id,
          amountMad: stay.pricePerNight ?? 0,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment success')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_stayProvider(id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hotel Details')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (m) {
            final s = m['stay'] as HebergementModel;
            final stats = Map<String, dynamic>.from((m['stats'] as Map?) ?? {});
            final check = m['check'] == true;
            final reviews = (m['reviews'] as List<ReviewModel>);
            final rating = s.rating ?? (stats['average'] as num?)?.toDouble();

            return ListView(
              children: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: SafeNetworkImage(
                        imageUrl: s.imageUrl,
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
                        s.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text('${s.city ?? '-'} • ${s.type ?? '-'}'),
                      const SizedBox(height: 6),
                      Text('${s.pricePerNight ?? 0} MAD/night'),
                      const SizedBox(height: 6),
                      Text(
                        'Rating: ${rating ?? stats['averageRating'] ?? '-'}',
                      ),
                      Text('Availability: ${check ? 'Available' : 'Unavailable'}'),
                      if (s.roomsAvailable != null) ...[
                        const SizedBox(height: 4),
                        Text('Rooms: ${s.roomsAvailable}'),
                      ],
                      const SizedBox(height: 10),
                      Text(s.description ?? '-'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (_ensureAuthed(context, ref)) {
                                  context.push('/book/hotel/$id');
                                }
                              },
                              icon: const Icon(Icons.hotel_rounded),
                              label: const Text('Reserver'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Payer maintenant',
                              icon: Icons.payments_rounded,
                              onTap: () async => _quickPay(context, ref, s),
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
                              extra: {'type': 'ACCOMMODATION', 'targetId': id},
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
