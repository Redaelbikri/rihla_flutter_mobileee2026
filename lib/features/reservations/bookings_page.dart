import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'reservations_service.dart';

final _myBookingsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(reservationsServiceProvider).myReservations();
});

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_myBookingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
      children: [
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.receipt_long_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'My Reservations',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/payments'),
                child: const Text('Payments history'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        data.when(
          data: (list) {
            if (list.isEmpty) {
              return const GlassCard(child: Text('No reservations yet.'));
            }
            return Column(
              children: list.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title ?? 'Reservation',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text('Type: ${b.type ?? '-'} • Status: ${b.status ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('Amount: ${b.amount?.toStringAsFixed(2) ?? '-'} MAD'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await ref
                                      .read(reservationsServiceProvider)
                                      .cancel(b.id);
                                  ref.invalidate(_myBookingsProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cancelled')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.cancel_rounded),
                                label: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Payments',
                                icon: Icons.payments_rounded,
                                onTap: () => context.push('/payments'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => GlassCard(child: Text(e.toString())),
        ),
      ],
    );
  }
}
