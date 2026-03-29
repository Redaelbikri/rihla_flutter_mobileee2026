import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/models/hebergement_model.dart';
import '../../core/models/review_model.dart';
import '../../core/ui/safe_network_image.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../reviews/reviews_service.dart';
import 'hebergements_service.dart';

final _stayProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final stay = await ref.read(hebergementsServiceProvider).getById(id);
  final stats = await ref.read(hebergementsServiceProvider).ratingStats(id).catchError((_) => <String, dynamic>{});
  final check = await ref.read(hebergementsServiceProvider).checkAvailability(id).catchError((_) => false);
  final reviews = await ref.read(reviewsServiceProvider).list(type: 'HEBERGEMENT', id: id).catchError((_) => <ReviewModel>[]);
  return {'stay': stay, 'stats': stats, 'check': check, 'reviews': reviews};
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

  Future<void> _quickPay(BuildContext context, WidgetRef ref, HebergementModel stay) async {
    if (!_ensureAuthed(context, ref)) return;
    try {
      final r = await ref.read(reservationsServiceProvider).createHebergement(hebergementId: id, quantity: 1);
      await ref.read(paymentsServiceProvider).payReservation(
        reservationId: r.id,
        amountMad: (stay.pricePerNight ?? 0).toDouble(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful')));
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_stayProvider(id));

    return Scaffold(
      body: data.when(
        data: (m) {
          final stay = m['stay'] as HebergementModel;
          final stats = Map<String, dynamic>.from((m['stats'] as Map?) ?? {});
          final reviews = m['reviews'] as List<ReviewModel>;
          final available = m['check'] == true;
          final rating = stay.rating ?? (stats['average'] as num?)?.toDouble() ?? 4.6;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 290,
                    backgroundColor: Colors.white,
                    leading: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.85)),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          SafeNetworkImage(
                            imageUrl: stay.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: Container(color: const Color(0xFFE8F1FF)),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x22000000), Color(0xC0000000)],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((stay.type ?? '').isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      stay.type!.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  stay.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, height: 1.15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFF2D8BFF), size: 18),
                              const SizedBox(width: 4),
                              Text(stay.city ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.star_rounded, color: Color(0xFFF5B400), size: 18),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: available ? const Color(0xFFE7F9ED) : const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  available ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color: available ? const Color(0xFF147A3C) : const Color(0xFFB3261E),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD8E8FF)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.nightlight_round, color: Color(0xFF2D8BFF)),
                                const SizedBox(width: 10),
                                Text(
                                  '${(stay.pricePerNight ?? 0).toStringAsFixed(0)} MAD / night',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1B74E4)),
                                ),
                              ],
                            ),
                          ),
                          if ((stay.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text('Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              stay.description!,
                              style: const TextStyle(color: Color(0xFF536D8E), height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Text('Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                              const Spacer(),
                              Text('${reviews.length}', style: const TextStyle(color: Color(0xFF6A7F9C))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (reviews.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text('No reviews yet. Be the first to leave one.'),
                            )
                          else
                            ...reviews.take(4).map(
                                  (r) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              r.userName ?? 'Traveler',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.star_rounded, color: Color(0xFFF5B400), size: 16),
                                            const SizedBox(width: 2),
                                            Text(r.rating.toStringAsFixed(1)),
                                          ],
                                        ),
                                        if (r.comment.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(r.comment, style: const TextStyle(color: Color(0xFF536D8E))),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (_ensureAuthed(context, ref)) {
                                context.push('/review/new', extra: {'type': 'HEBERGEMENT', 'targetId': id});
                              }
                            },
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Write a review'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (_ensureAuthed(context, ref)) context.push('/book/hotel/$id');
                          },
                          icon: const Icon(Icons.book_online_rounded),
                          label: const Text('Book'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _quickPay(context, ref, stay),
                          icon: const Icon(Icons.payments_rounded),
                          label: const Text('Pay Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}


