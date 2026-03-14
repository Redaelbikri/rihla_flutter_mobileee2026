import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/reservation_model.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../payments/payments_service.dart';
import 'reservations_service.dart';

final _myBookingsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(reservationsServiceProvider).myReservations();
});

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_myBookingsProvider);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
      children: [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_long_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'My Reservations',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/payments'),
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: const Text('Payments'),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 12),
        data.when(
          data: (list) {
            if (list.isEmpty) {
              return GlassCard(
                child: Column(
                  children: [
                    Icon(Icons.luggage_rounded, size: 56, color: scheme.primary.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('No reservations yet', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Start exploring events, stays and transport.', style: t.bodyMedium),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/app?tab=1'),
                      icon: const Icon(Icons.explore_rounded),
                      label: const Text('Explore'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms);
            }
            return Column(
              children: list.asMap().entries.map((entry) {
                final i = entry.key;
                final b = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReservationCard(
                    reservation: b,
                    onCancel: () async {
                      await ref.read(reservationsServiceProvider).cancel(b.id);
                      ref.invalidate(_myBookingsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reservation cancelled')),
                        );
                      }
                    },
                    onPay: () => context.push('/payments'),
                    onTickets: () => _showTickets(context, ref, b),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 60), duration: 400.ms),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => GlassCard(
            child: Text(e.toString(), style: const TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  void _showTickets(BuildContext context, WidgetRef ref, ReservationModel b) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TicketsSheet(reservationId: b.id, reservationTitle: b.title),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final VoidCallback onTickets;

  const _ReservationCard({
    required this.reservation,
    required this.onCancel,
    required this.onPay,
    required this.onTickets,
  });

  Color _statusColor(BuildContext context, String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'CONFIRMED':
        return Colors.green.shade600;
      case 'PENDING':
        return Colors.orange.shade700;
      case 'CANCELLED':
        return Colors.red.shade600;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }

  IconData _typeIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'EVENT':
        return Icons.festival_rounded;
      case 'HEBERGEMENT':
        return Icons.hotel_rounded;
      case 'TRANSPORT':
        return Icons.train_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final status = reservation.status;
    final statusColor = _statusColor(context, status);
    final canCancel = (status?.toUpperCase() != 'CANCELLED' && status?.toUpperCase() != 'CONFIRMED');
    final dateStr = reservation.createdAt != null
        ? _formatDate(reservation.createdAt!)
        : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(reservation.type), color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.title ?? 'Reservation',
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateStr != null) ...[
                      const SizedBox(height: 2),
                      Text(dateStr, style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.5))),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status ?? '-',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (reservation.type != null) ...[
                _Chip(label: reservation.type!, icon: _typeIcon(reservation.type)),
                const SizedBox(width: 8),
              ],
              if (reservation.quantity != null) ...[
                _Chip(label: '×${reservation.quantity}', icon: Icons.confirmation_num_outlined),
                const SizedBox(width: 8),
              ],
              if (reservation.amount != null && reservation.amount! > 0)
                _Chip(
                  label: '${reservation.amount!.toStringAsFixed(0)} MAD',
                  icon: Icons.payments_outlined,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTickets,
                  icon: const Icon(Icons.confirmation_num_rounded, size: 16),
                  label: const Text('Tickets'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.credit_card_rounded, size: 16),
                  label: const Text('Payments'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  child: const Icon(Icons.cancel_outlined, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketsSheet extends ConsumerWidget {
  final String reservationId;
  final String? reservationTitle;

  const _TicketsSheet({required this.reservationId, this.reservationTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(reservationsServiceProvider).getTickets(reservationId),
      builder: (context, snap) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservationTitle ?? 'Tickets',
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snap.hasError)
                Text('Could not load tickets: ${snap.error}',
                    style: const TextStyle(color: Colors.red))
              else if ((snap.data ?? []).isEmpty)
                Column(
                  children: [
                    Icon(Icons.confirmation_num_outlined, size: 48, color: scheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    const Text('No tickets found for this reservation.'),
                  ],
                )
              else
                ...((snap.data ?? []).map((ticket) => _TicketItem(ticket: ticket))),
            ],
          ),
        );
      },
    );
  }
}

class _TicketItem extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _TicketItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = (ticket['status'] ?? '').toString().toUpperCase();
    final statusColor = status == 'VALID'
        ? Colors.green.shade600
        : status == 'USED'
            ? Colors.grey
            : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.confirmation_num_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['type']?.toString() ?? 'Ticket',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (ticket['id'] != null)
                  Text(
                    'ID: ${ticket['id']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
