import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/ui/glass.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Transport results')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (list) {
            if (list.isEmpty) {
              return const GlassCard(child: Text('No trips found.'));
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final tr = list[i];
                final dep = tr.departureAt != null
                    ? DateFormat('MMM d • HH:mm').format(tr.departureAt!)
                    : (tr.date ?? '-');
                final arr = tr.arrivalAt != null
                    ? DateFormat('MMM d • HH:mm').format(tr.arrivalAt!)
                    : '-';

                return GlassCard(
                  child: ListTile(
                    title: Text(
                      '${tr.fromCity} -> ${tr.toCity}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text('${tr.type ?? ''} • $dep → $arr'),
                    trailing: Text(
                      tr.price == null
                          ? '-'
                          : '${tr.price!.toStringAsFixed(0)} ${tr.currency ?? 'MAD'}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    onTap: () => GoRouter.of(context).push('/trip/${tr.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
