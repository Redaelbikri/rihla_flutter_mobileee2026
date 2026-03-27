import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/ui/glass.dart';
import 'payments_service.dart';

final _paymentsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(paymentsServiceProvider).myPayments();
});

final _invoicesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(paymentsServiceProvider).myInvoices();
});

class PaymentHistoryPage extends ConsumerStatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  ConsumerState<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends ConsumerState<PaymentHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payments = ref.watch(_paymentsProvider);
    final invoices = ref.watch(_invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Invoices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(6),
              child: TabBar(
                controller: _tabs,
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurface.withOpacity(0.5),
                indicator: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                tabs: const [
                  Tab(text: 'Payments'),
                  Tab(text: 'Invoices'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PaymentsList(data: payments),
                _InvoicesList(data: invoices),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> data;
  const _PaymentsList({required this.data});

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'SUCCEEDED':
      case 'PAID':
        return Colors.green.shade600;
      case 'PENDING':
        return Colors.orange.shade700;
      case 'FAILED':
      case 'REFUNDED':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return data.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  const Text('No payments yet.'),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = list[i];
            final rawAmount = p['amountMad'] ?? p['amount'];
            final amount = (rawAmount is num)
                ? (rawAmount as num).toDouble()
                : double.tryParse('$rawAmount');
            final status = p['status']?.toString();
            final statusColor = _statusColor(status);
            final dateStr = _formatDate(p['createdAt']?.toString());

            return GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.payments_rounded, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amount != null
                              ? '${amount.toStringAsFixed(2)} MAD'
                              : '-',
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        if (dateStr != null)
                          Text(dateStr, style: t.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
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
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50), duration: 350.ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateFormat('MMM d, yyyy • HH:mm').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _InvoicesList extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> data;
  const _InvoicesList({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return data.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 48, color: scheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  const Text('No invoices yet.'),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final inv = list[i];
            final rawAmount = inv['amountMad'] ?? inv['amount'] ?? inv['totalAmount'];
            final amount = (rawAmount is num)
                ? (rawAmount as num).toDouble()
                : double.tryParse('$rawAmount');
            final dateStr = _formatDate(
              inv['issuedAt']?.toString() ??
                  inv['createdAt']?.toString() ??
                  inv['date']?.toString(),
            );
            final invoiceNumber = (inv['factureNumber'] ?? inv['id'] ?? inv['_id'] ?? '')
                .toString();

            return GlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.description_rounded, color: scheme.secondary),
                ),
                title: Text(
                  invoiceNumber.isEmpty
                      ? 'Invoice'
                      : 'Invoice #${invoiceNumber.substring(0, invoiceNumber.length.clamp(0, 16))}',
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (amount != null)
                      Text('${amount.toStringAsFixed(2)} MAD',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary)),
                    if (dateStr != null) Text(dateStr),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50), duration: 350.ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
