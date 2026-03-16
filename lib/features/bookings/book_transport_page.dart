import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';

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
  int _seatCount = 1;
  bool _loading = false;

  void _vibrate() => HapticFeedback.selectionClick();

  Future<void> _processBooking(TripModel trip, {bool payNow = false}) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(reservationsServiceProvider).createTransport(
            tripId: widget.id,
            quantity: _seatCount,
          );

      if (payNow) {
        final total = (trip.price ?? 0) * _seatCount;
        await ref.read(paymentsServiceProvider).payReservation(
              reservationId: res.id,
              amountMad: total.toDouble(),
            );
      }

      if (mounted) {
        final msg = payNow
            ? 'Trip booked & paid! Ticket details sent to your email.'
            : 'Seats reserved! Pay later from My Trips.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ]),
            backgroundColor: const Color(0xFF0C6171),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _typeIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'FLIGHT':
        return Icons.flight_rounded;
      case 'TRAIN':
        return Icons.train_rounded;
      case 'BUS':
        return Icons.directions_bus_rounded;
      case 'CAR':
        return Icons.directions_car_rounded;
      default:
        return Icons.directions_transit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_tripProvider(widget.id));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Book Transport',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: data.when(
        data: (trip) => _buildUI(trip),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildUI(TripModel trip) {
    final totalPrice = (trip.price ?? 0) * _seatCount;
    final depStr = trip.departureAt != null
        ? DateFormat('EEE, MMM d • HH:mm').format(trip.departureAt!)
        : null;
    final arrStr = trip.arrivalAt != null
        ? DateFormat('HH:mm').format(trip.arrivalAt!)
        : null;

    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0C2D3D),
                  const Color(0xFF0C6171),
                  const Color(0xFF164055).withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Trip route card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transport type badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFD98F39).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: const Color(0xFFD98F39)
                                      .withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcon(trip.type),
                                  color: const Color(0xFFD98F39),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (trip.type ?? 'TRANSPORT').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFD98F39),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if ((trip.providerName ?? '').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              trip.providerName!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Route display
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.fromCity ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (depStr != null)
                                  Text(
                                    depStr,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Icon(
                                _typeIcon(trip.type),
                                color: const Color(0xFFD98F39),
                                size: 28,
                              ),
                              Container(
                                width: 60,
                                height: 2,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0C6171),
                                      Color(0xFFD98F39)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  trip.toCity ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                if (arrStr != null)
                                  Text(
                                    'Arrives $arrStr',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (trip.availableSeats != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.event_seat_rounded,
                                color: Colors.white54, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${trip.availableSeats} seats available',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().slideY(begin: 0.08, duration: 500.ms).fadeIn(),

                const SizedBox(height: 16),

                // Seat selection
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Seats',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCounter(
                        'Number of seats',
                        _seatCount,
                        (v) => setState(() => _seatCount = v),
                        Icons.event_seat_rounded,
                      ),
                      const Divider(height: 32, color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              Text(
                                '$totalPrice MAD',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFD98F39),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${trip.price?.toStringAsFixed(0) ?? '-'} MAD × $_seatCount',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Pay Now',
                        loading: _loading,
                        icon: Icons.credit_card_rounded,
                        onTap: () => _processBooking(trip, payNow: true),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loading
                              ? null
                              : () => _processBooking(trip),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Reserve Without Paying'),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(begin: 0.1, delay: 100.ms, duration: 500.ms)
                    .fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(
      String title, int value, Function(int) onChanged, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD98F39), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
        Row(
          children: [
            _circleBtn(Icons.remove, () {
              if (value > 1) {
                _vibrate();
                onChanged(value - 1);
              }
            }),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _circleBtn(Icons.add, () {
              _vibrate();
              onChanged(value + 1);
            }),
          ],
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
