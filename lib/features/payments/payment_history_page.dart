import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/glass.dart';
import 'payments_service.dart';

final _paymentsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(paymentsServiceProvider).myPayments();
});

class PaymentHistoryPage extends ConsumerWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_paymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments History')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (list) {
            if (list.isEmpty) {
              return const GlassCard(child: Text('No payments yet.'));
            }
            return ListView(
              children: list.map((p) {
                final rawAmount = p['amountMad'] ?? p['amount'];
                final amount = (rawAmount is num)
                    ? (rawAmount / 100.0)
                    : double.tryParse('$rawAmount');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: ListTile(
                      title: Text(
                        (p['status'] ?? 'payment').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        'amountMad: ${amount?.toStringAsFixed(2) ?? '-'} • ${p['createdAt'] ?? ''}',
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
