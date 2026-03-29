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
    _tabIdx = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 90,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _pages[_tabIdx]
                  .animate(key: ValueKey(_tabIdx))
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: 0.04, end: 0),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: _FloatingNavBar(
              navIdx: _tabIdx,
              onTap: (i) => setState(() => _tabIdx = i),
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
      _NavItemData(icon: Icons.search_rounded, label: 'Search'),
      _NavItemData(icon: Icons.smart_toy_rounded, label: 'Assistant'),
      _NavItemData(icon: Icons.route_rounded, label: 'Trips'),
      _NavItemData(icon: Icons.person_rounded, label: 'Profile', badge: unread > 0 ? unread : null),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final active = i == navIdx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? scheme.primary.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(item.icon, size: 22, color: active ? scheme.primary : const Color(0xFF7D8CA1)),
                            if (item.badge != null)
                              Positioned(
                                top: -7,
                                right: -10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE83F6F),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    item.badge! > 99 ? '99+' : item.badge.toString(),
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
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: active ? scheme.primary : const Color(0xFF7D8CA1),
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          ),
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


