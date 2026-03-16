import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assistant/assistant_chat_page.dart';
import '../explore/explore_page.dart';
import '../home/home_page.dart';
import '../itineraries/itinerary_planner_page.dart';
import '../notifications/notifications_service.dart';
import '../profile/profile_page.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _tabIdx;

  final _pages = const [
    HomePage(),
    ExplorePage(),
    AssistantChatPage(),
    ItineraryPlannerPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabIdx = widget.initialIndex.clamp(0, 4);
  }

  int get _navIdx => _tabIdx;

  void _onNavTap(int navIdx) {
    setState(() => _tabIdx = navIdx);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            bottom: 80,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _pages[_tabIdx].animate(key: ValueKey(_tabIdx)).fadeIn(
                    duration: 240.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),

          // Bottom nav
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _FloatingNavBar(
              navIdx: _navIdx,
              onTap: _onNavTap,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends ConsumerWidget {
  final int navIdx;
  final ValueChanged<int> onTap;
  final ColorScheme scheme;

  const _FloatingNavBar({
    required this.navIdx,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    final items = [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.explore_rounded, label: 'Explore'),
      _NavItemData(icon: Icons.smart_toy_rounded, label: 'AI Chat'),
      _NavItemData(icon: Icons.map_rounded, label: 'AI Plan'),
      _NavItemData(
          icon: Icons.person_rounded,
          label: 'Profile',
          badge: unread > 0 ? unread : null),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                blurRadius: 28,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.12),
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = navIdx == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? scheme.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: active ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                item.icon,
                                color: active
                                    ? scheme.primary
                                    : const Color(0xFF8A8078),
                                size: 24,
                              ),
                            ),
                            if (item.badge != null)
                              Positioned(
                                right: -8,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.tertiary,
                                    borderRadius: BorderRadius.circular(999),
                                    border:
                                        Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Text(
                                    item.badge! > 99
                                        ? '99+'
                                        : item.badge!.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: active
                                ? scheme.primary
                                : const Color(0xFF8A8078),
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 10,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final int? badge;
  const _NavItemData({required this.icon, required this.label, this.badge});
}
