import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_model.dart';
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
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  void _init(UserModel u) {
    if (_initialized) return;
    final parts = (u.fullName ?? '').trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    _firstName.text = parts.isNotEmpty ? parts.first : '';
    _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _phone.text = u.phone ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileServiceProvider).update({
        'prenom': _firstName.text.trim(),
        'nom': _lastName.text.trim(),
        'telephone': _phone.text.trim(),
      });
      _initialized = false;
      ref.invalidate(_meProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(_meProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 98),
      children: [
        me.when(
          data: (u) {
            _init(u);
            return _ProfileHeader(user: u);
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator())),
          error: (e, _) => Text(e.toString()),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'First name'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Last name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _MenuItem(
                icon: Icons.receipt_long_rounded,
                title: 'Booking History',
                subtitle: 'See all your reservations',
                onTap: () => context.push('/bookings'),
              ),
              const Divider(height: 12),
              _MenuItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Updates and reminders',
                onTap: () => context.push('/notifications'),
              ),
              const Divider(height: 12),
              _MenuItem(
                icon: Icons.settings_rounded,
                title: 'Settings',
                subtitle: 'Language, preferences, privacy',
                onTap: () => context.push('/settings'),
              ),
              const Divider(height: 12),
              _MenuItem(
                icon: Icons.credit_card_rounded,
                title: 'Payments',
                subtitle: 'Invoices and payment history',
                onTap: () => context.push('/payments'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: _MenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'End current session',
            color: const Color(0xFFB3261E),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.fullName ?? user.email ?? '?');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B74E4), Color(0xFF51ADFF)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'Traveler', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.email ?? '', style: const TextStyle(color: Color(0xFFD6E8FF))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFF1B74E4),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF68829F), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF92A6C0)),
          ],
        ),
      ),
    );
  }
}


