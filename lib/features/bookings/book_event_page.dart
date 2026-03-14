import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/event_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../events/events_service.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';

final _eventProvider = FutureProvider.autoDispose.family<EventModel, String>(
  (ref, id) => ref.read(eventsServiceProvider).getById(id),
);

class BookEventPage extends ConsumerStatefulWidget {
  final String id;
  const BookEventPage({super.key, required this.id});

  @override
  ConsumerState<BookEventPage> createState() => _BookEventPageState();
}

class _BookEventPageState extends ConsumerState<BookEventPage> {
  final qty = TextEditingController(text: '1');
  bool loading = false;

  Future<void> _reserveOnly(EventModel event) async {
    setState(() => loading = true);
    try {
      final quantity = int.tryParse(qty.text.trim()) ?? 1;
      await ref.read(reservationsServiceProvider).createEvent(
            eventId: widget.id,
            quantity: quantity,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Reservation created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _reserveAndPay(EventModel event) async {
    setState(() => loading = true);
    try {
      final quantity = int.tryParse(qty.text.trim()) ?? 1;
      final r = await ref.read(reservationsServiceProvider).createEvent(
            eventId: widget.id,
            quantity: quantity,
          );
      final amountMad = (event.price ?? 0) * quantity;
      await ref.read(paymentsServiceProvider).payReservation(
            reservationId: r.id,
            amountMad: amountMad,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Payment success')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_eventProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Book Event')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (event) => GlassCard(
            child: Column(
              children: [
                Text(
                  event.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tickets'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${(event.price ?? 0) * (int.tryParse(qty.text) ?? 1)} MAD',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Reserve',
                  loading: loading,
                  icon: Icons.shopping_bag_rounded,
                  onTap: () => _reserveOnly(event),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: loading ? null : () => _reserveAndPay(event),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Pay now'),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}
