import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/notification_model.dart';
import '../../core/ui/glass.dart';
import 'notifications_service.dart';

final _notifsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.read(notificationsServiceProvider).myNotifications();
});

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_notifsProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

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
                child: Icon(Icons.notifications_active_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifications',
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              data.whenOrNull(
                data: (list) {
                  final unread = list.where((n) => !n.read).toList();
                  if (unread.isEmpty) return null;
                  return TextButton.icon(
                    onPressed: () async {
                      for (final n in unread) {
                        await ref
                            .read(notificationsServiceProvider)
                            .markRead(n.id);
                      }
                      ref.invalidate(_notifsProvider);
                      ref.invalidate(unreadCountProvider);
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: Text('Mark all (${unread.length})'),
                  );
                },
              ) ?? const SizedBox.shrink(),
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
                    Icon(Icons.notifications_none_rounded,
                        size: 56, color: scheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No notifications yet',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text("You're all caught up!", style: t.bodyMedium),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms);
            }

            return Column(
              children: list.asMap().entries.map((entry) {
                final i = entry.key;
                final n = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationCard(
                    notification: n,
                    onMarkRead: n.read
                        ? null
                        : () async {
                            await ref
                                .read(notificationsServiceProvider)
                                .markRead(n.id);
                            ref.invalidate(_notifsProvider);
                            ref.invalidate(unreadCountProvider);
                          },
                  ),
                ).animate().fadeIn(
                    delay: Duration(milliseconds: i * 40), duration: 350.ms);
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
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkRead;

  const _NotificationCard({required this.notification, this.onMarkRead});

  IconData _notifIcon(String title) {
    final tl = title.toLowerCase();
    if (tl.contains('payment') || tl.contains('paid')) return Icons.payments_rounded;
    if (tl.contains('reserv') || tl.contains('booking')) return Icons.receipt_long_rounded;
    if (tl.contains('cancel')) return Icons.cancel_rounded;
    if (tl.contains('confirm')) return Icons.check_circle_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final isUnread = !notification.read;
    final dateStr = _formatDate(notification.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isUnread
            ? scheme.primary.withOpacity(0.06)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread
              ? scheme.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isUnread ? scheme.primary : scheme.onSurface.withOpacity(0.15))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _notifIcon(notification.title),
                color: isUnread ? scheme.primary : scheme.onSurface.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isUnread
                                ? scheme.onSurface
                                : scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateStr != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (onMarkRead != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onMarkRead,
                      child: Text(
                        'Mark as read',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
