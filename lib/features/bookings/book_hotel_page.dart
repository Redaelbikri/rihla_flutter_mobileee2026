import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/hebergement_model.dart';
import '../../core/ui/safe_network_image.dart';
import '../hebergements/hebergements_service.dart';
import '../payments/payments_service.dart';
import '../reservations/reservations_service.dart';

final _stayProvider = FutureProvider.autoDispose.family<HebergementModel, String>(
  (ref, id) => ref.read(hebergementsServiceProvider).getById(id),
);

class BookHotelPage extends ConsumerStatefulWidget {
  final String id;
  const BookHotelPage({super.key, required this.id});

  @override
  ConsumerState<BookHotelPage> createState() => _BookHotelPageState();
}

class _BookHotelPageState extends ConsumerState<BookHotelPage> {
  int _rooms = 1;
  int _people = 2;
  DateTimeRange? _range;
  bool _loading = false;

  int get _nights {
    if (_range == null) return 1;
    final nights = _range!.end.difference(_range!.start).inDays;
    return nights <= 0 ? 1 : nights;
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range ?? DateTimeRange(start: now, end: now.add(const Duration(days: 2))),
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _confirm(HebergementModel stay, {required bool payNow}) async {
    setState(() => _loading = true);
    try {
      final reservation = await ref.read(reservationsServiceProvider).createHebergement(
            hebergementId: widget.id,
            quantity: _rooms,
          );

      if (payNow) {
        final total = ((stay.pricePerNight ?? 0) * _rooms * _nights).toDouble();
        await ref.read(paymentsServiceProvider).payReservation(
              reservationId: reservation.id,
              amountMad: total,
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payNow ? 'Booking confirmed and paid.' : 'Booking reserved successfully.'),
        ),
      );
      context.go('/bookings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_stayProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: data.when(
        data: (stay) => _BookingContent(
          stay: stay,
          rooms: _rooms,
          people: _people,
          nights: _nights,
          range: _range,
          onRoomsChanged: (v) => setState(() => _rooms = v),
          onPeopleChanged: (v) => setState(() => _people = v),
          onDatesTap: _selectDates,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
      bottomNavigationBar: data.maybeWhen(
        data: (stay) {
          final total = (stay.pricePerNight ?? 0) * _rooms * _nights;
          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Total price', style: TextStyle(color: Color(0xFF657F9F))),
                      const Spacer(),
                      Text(
                        '${total.toStringAsFixed(0)} MAD',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1B74E4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => _confirm(stay, payNow: false),
                          child: const Text('Reserve'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _loading ? null : () => _confirm(stay, payNow: true),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Confirm & Pay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _BookingContent extends StatelessWidget {
  final HebergementModel stay;
  final int rooms;
  final int people;
  final int nights;
  final DateTimeRange? range;
  final ValueChanged<int> onRoomsChanged;
  final ValueChanged<int> onPeopleChanged;
  final VoidCallback onDatesTap;

  const _BookingContent({
    required this.stay,
    required this.rooms,
    required this.people,
    required this.nights,
    required this.range,
    required this.onRoomsChanged,
    required this.onPeopleChanged,
    required this.onDatesTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = range == null
        ? 'Select dates'
        : '${range!.start.month}/${range!.start.day} - ${range!.end.month}/${range!.end.day}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            child: SafeNetworkImage(imageUrl: stay.imageUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 14),
        Text(stay.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(stay.city ?? '-', style: const TextStyle(color: Color(0xFF6A7F9C))),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD8E8FF)),
          ),
          child: Column(
            children: [
              _CounterRow(
                label: 'Rooms',
                value: rooms,
                onMinus: () => onRoomsChanged(rooms > 1 ? rooms - 1 : 1),
                onPlus: () => onRoomsChanged(rooms + 1),
              ),
              const SizedBox(height: 10),
              _CounterRow(
                label: 'People',
                value: people,
                onMinus: () => onPeopleChanged(people > 1 ? people - 1 : 1),
                onPlus: () => onPeopleChanged(people + 1),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onDatesTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF2D8BFF), size: 18),
                      const SizedBox(width: 8),
                      Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$nights nights', style: const TextStyle(color: Color(0xFF6A7F9C))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Price Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              _Line(label: '${(stay.pricePerNight ?? 0).toStringAsFixed(0)} MAD × $rooms room(s) × $nights night(s)'),
              _Line(label: 'Guests: $people'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _CounterRow({required this.label, required this.value, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  const _Line({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(color: Color(0xFF607A9B), fontWeight: FontWeight.w500)),
    );
  }
}


