import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: data.when(
          data: (list) {
            if (list.isEmpty) {
              return const GlassCard(child: Text('No notifications.'));
            }

            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = list[i];

                return GlassCard(
                  child: ListTile(
                    title: Text(
                      n.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(n.message),
                    trailing: n.read
                        ? const Icon(Icons.check_circle_rounded)
                        : IconButton(
                            icon: const Icon(Icons.mark_email_read_rounded),
                            onPressed: () async {
                              await ref
                                  .read(notificationsServiceProvider)
                                  .markRead(n.id);
                              ref.invalidate(_notifsProvider);
                              ref.invalidate(unreadCountProvider);
                            },
                          ),
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
