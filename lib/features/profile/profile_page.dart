import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_model.dart';
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

  void _init(UserModel u) {
    if (initialized) return;
    final parts = (u.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();
    firstName.text = parts.isNotEmpty ? parts.first : '';
    lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    phone.text = u.phone ?? '';
    initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_meProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 92),
      children: [
        data.when(
          data: (u) {
            _init(u);
            return _ProfileHeader(user: u, scheme: scheme, t: t)
                .animate()
                .fadeIn(duration: 400.ms);
          },
          loading: () => const _AvatarSkeleton(),
          error: (e, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        // Edit form
        data.when(
          data: (u) => GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstName,
                        decoration: const InputDecoration(labelText: 'First name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lastName,
                        decoration: const InputDecoration(labelText: 'Last name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Changes',
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
                      initialized = false;
                      ref.invalidate(_meProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile saved')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())));
                      }
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => GlassCard(child: Text(e.toString())),
        ),
        const SizedBox(height: 12),
        // Quick actions
        GlassCard(
          child: Column(
            children: [
              _ProfileMenuItem(
                icon: Icons.luggage_rounded,
                label: 'My Trips',
                subtitle: 'View your reservations & tickets',
                color: const Color(0xFF197278),
                onTap: () => context.push('/bookings'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                subtitle: 'View alerts and updates',
                color: const Color(0xFFD98F39),
                onTap: () => context.push('/notifications'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'AI Assistant',
                subtitle: 'Chat with your travel guide',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push('/assistant'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Itinerary Planner',
                subtitle: 'Plan your next trip',
                color: scheme.primary,
                onTap: () => context.push('/itinerary/planner'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.map_outlined,
                label: 'My Itineraries',
                subtitle: 'View past itinerary plans',
                color: scheme.primary,
                onTap: () => context.push('/itineraries'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.recommend_rounded,
                label: 'Recommendations',
                subtitle: 'Personalized suggestions for you',
                color: scheme.secondary,
                onTap: () => context.push('/recommendations'),
              ),
              const Divider(height: 1),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.credit_card_rounded,
                label: 'Payments & Invoices',
                subtitle: 'View payment history and invoices',
                color: const Color(0xFF0C6171),
                onTap: () => context.push('/payments'),
              ),
              const Divider(height: 1),
              _ProfileMenuItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                subtitle: 'App preferences',
                color: scheme.onSurface.withOpacity(0.5),
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 12),
        GlassCard(
          child: _ProfileMenuItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            subtitle: 'End your current session',
            color: Colors.red.shade600,
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final ColorScheme scheme;
  final TextTheme t;

  const _ProfileHeader({
    required this.user,
    required this.scheme,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.fullName ?? user.email ?? '?');

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName ?? 'Traveler',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email ?? '',
                  style: t.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.5)),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: t.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _AvatarSkeleton extends StatelessWidget {
  const _AvatarSkeleton();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1000.ms),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 16, color: Colors.white.withOpacity(0.6))
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1000.ms),
              const SizedBox(height: 6),
              Container(width: 100, height: 12, color: Colors.white.withOpacity(0.4))
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1000.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(subtitle,
                      style: t.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
