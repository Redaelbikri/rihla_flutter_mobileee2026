import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/event_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/safe_network_image.dart';
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
  int _ticketCount = 1;
  bool _loading = false;

  void _vibrate() => HapticFeedback.selectionClick();

  Future<void> _processBooking(EventModel event, {bool payNow = false}) async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(reservationsServiceProvider).createEvent(
            eventId: widget.id,
            quantity: _ticketCount,
          );

      if (payNow) {
        final total = (event.price ?? 0) * _ticketCount;
        await ref.read(paymentsServiceProvider).payReservation(
              reservationId: res.id,
              amountMad: total.toDouble(),
            );
      }

      if (mounted) {
        _showConfirmation(payNow);
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

  void _showConfirmation(bool paid) {
    showDialog(
      context: context,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.92),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C6171), Color(0xFFD98F39)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                paid ? 'Payment Confirmed!' : 'Reservation Made!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            paid
                ? 'Your tickets are booked and paid. See you at the event!'
                : 'Your reservation is confirmed. You can pay later.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Great!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_eventProvider(widget.id));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Book Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: data.when(
        data: (event) => _buildUI(event),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildUI(EventModel event) {
    final totalPrice = (event.price ?? 0) * _ticketCount;
    final dateStr = event.dateEvent != null
        ? DateFormat('EEE, MMM d • HH:mm').format(event.dateEvent!)
        : null;

    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: SafeNetworkImage(
            imageUrl: event.imageUrl,
            fit: BoxFit.cover,
            placeholder: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF184E57), Color(0xFF0E6B72)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.85),
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
                // Event info
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      if ((event.category ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD98F39).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    const Color(0xFFD98F39).withOpacity(0.5)),
                          ),
                          child: Text(
                            event.category!.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFD98F39),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dateStr != null) ...[
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          text: dateStr,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if ((event.city ?? '').isNotEmpty) ...[
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          text: event.city!,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _InfoRow(
                        icon: Icons.confirmation_num_rounded,
                        text:
                            '${event.placesDisponibles ?? 'Available'} spots remaining',
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.08, duration: 500.ms).fadeIn(),

                const SizedBox(height: 16),

                // Ticket selection
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Tickets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCounter(
                        'Number of tickets',
                        _ticketCount,
                        (v) => setState(() => _ticketCount = v),
                        Icons.confirmation_num_outlined,
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
                            '${event.price?.toStringAsFixed(0) ?? '-'} MAD × $_ticketCount',
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
                        onTap: () => _processBooking(event, payNow: true),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              _loading ? null : () => _processBooking(event),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
