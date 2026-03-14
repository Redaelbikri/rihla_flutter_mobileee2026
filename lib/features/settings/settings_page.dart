import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/ui/glass.dart';
import '../auth/auth_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            GlassCard(
              child: ListTile(
                title: const Text(
                  'API Base URL',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(AppConfig.baseUrl),
                trailing: const Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: ListTile(
                title: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('End your current session'),
                trailing: const Icon(Icons.logout_rounded),
                onTap: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go('/auth/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
