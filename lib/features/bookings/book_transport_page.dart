import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/trip_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';
import '../transports/transports_service.dart';

final _tripProvider = FutureProvider.autoDispose.family<TripModel, String>(
  (ref, id) => ref.read(transportsServiceProvider).getTrip(id),
);

class BookTransportPage extends ConsumerStatefulWidget {
  final String id;
  const BookTransportPage({super.key, required this.id});

  @override
  ConsumerState<BookTransportPage> createState() => _BookTransportPageState();
}

class _BookTransportPageState extends ConsumerState<BookTransportPage> {
  final seats = TextEditingController(text: '1');
  bool loading = false;

  Future<void> _reserveOnly(TripModel trip) async {
    setState(() => loading = true);
    try {
      final quantity = int.tryParse(seats.text.trim()) ?? 1;
      await ref.read(reservationsServiceProvider).createTransport(
            tripId: widget.id,
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

  Future<void> _reserveAndPay(TripModel trip) async {
    setState(() => loading = true);
    try {
      final quantity = int.tryParse(seats.text.trim()) ?? 1;
      final r = await ref.read(reservationsServiceProvider).createTransport(
            tripId: widget.id,
            quantity: quantity,
          );
      final amountMad = (trip.price ?? 0) * quantity;
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
    final data = ref.watch(_tripProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Book Transport')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (trip) => GlassCard(
            child: Column(
              children: [
                Text(
                  '${trip.fromCity ?? '-'} -> ${trip.toCity ?? '-'}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: seats,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seats'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${(trip.price ?? 0) * (int.tryParse(seats.text) ?? 1)} MAD',
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Reserve',
                  loading: loading,
                  icon: Icons.confirmation_num_rounded,
                  onTap: () => _reserveOnly(trip),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: loading ? null : () => _reserveAndPay(trip),
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
