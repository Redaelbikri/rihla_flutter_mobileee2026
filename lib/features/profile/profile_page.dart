import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import '../auth/auth_service.dart';
import 'profile_service.dart';

final _meProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(profileServiceProvider).me();
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  bool initialized = false;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_meProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
      children: [
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.person_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'My Profile',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/assistant'),
                child: const Text('Assistant'),
              ),
              TextButton(
                onPressed: () => context.push('/settings'),
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        data.when(
          data: (u) {
            if (!initialized) {
              final parts = (u.fullName ?? '')
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((x) => x.isNotEmpty)
                  .toList();
              firstName.text = parts.isNotEmpty ? parts.first : '';
              lastName.text =
                  parts.length > 1 ? parts.sublist(1).join(' ') : '';
              phone.text = u.phone ?? '';
              initialized = true;
            }

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${u.email ?? '-'}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: firstName,
                      decoration:
                          const InputDecoration(labelText: 'First name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: lastName,
                      decoration:
                          const InputDecoration(labelText: 'Last name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save',
                    icon: Icons.save_rounded,
                    loading: saving,
                    onTap: () async {
                      setState(() => saving = true);
                      try {
                        await ref.read(profileServiceProvider).update({
                          'prenom': firstName.text.trim(),
                          'nom': lastName.text.trim(),
                          'telephone': phone.text.trim(),
                        });
                        ref.invalidate(_meProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())));
                        }
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).logout();
                      if (context.mounted) context.go('/auth/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator())),
          error: (e, _) => GlassCard(child: Text(e.toString())),
        ),
      ],
    );
  }
}
