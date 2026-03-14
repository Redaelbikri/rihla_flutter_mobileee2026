import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/gradients.dart';
import '../explore/explore_page.dart';
import '../home/home_page.dart';
import '../notifications/notifications_page.dart';
import '../notifications/notifications_service.dart';
import '../profile/profile_page.dart';
import '../reservations/bookings_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int idx;

  final pages = const [
    HomePage(),
    ExplorePage(),
    BookingsPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    idx = widget.initialIndex.clamp(0, pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: pages[idx]
                      .animate(key: ValueKey(idx))
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: 0.04, end: 0),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _PremiumNavBar(
                    index: idx,
                    onChanged: (v) => setState(() => idx = v),
                    scheme: scheme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumNavBar extends ConsumerWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final ColorScheme scheme;

  const _PremiumNavBar({
    required this.index,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x11FFFFFF)),
        boxShadow: const [
          BoxShadow(
              blurRadius: 30, offset: Offset(0, 18), color: Color(0x22000000)),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: index == 0,
              onTap: () => onChanged(0),
              scheme: scheme),
          _NavItem(
              icon: Icons.explore_rounded,
              label: 'Explore',
              active: index == 1,
              onTap: () => onChanged(1),
              scheme: scheme),
          _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Reservations',
              active: index == 2,
              onTap: () => onChanged(2),
              scheme: scheme),
          _NavItem(
              icon: Icons.notifications_active_rounded,
              label: 'Notifications',
              badge: unread > 0 ? unread : null,
              active: index == 3,
              onTap: () => onChanged(3),
              scheme: scheme),
          _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              active: index == 4,
              onTap: () => onChanged(4),
              scheme: scheme),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.scheme,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = active ? scheme.primary : const Color(0xFF5D6B7C);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                active ? scheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: c),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : badge!.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: c, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
          ),
        ),
      ),
    );
  }
}
