import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/di/providers.dart';
import '../../core/ui/glass.dart';
import '../../core/ui/gradients.dart';
import '../../core/ui/primary_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late final PageController _controller;
  int _index = 0;

  static const List<_OnboardData> _pages = [
    _OnboardData(
      city: 'Marrakech',
      title: 'Travel Morocco with style',
      body:
          'Discover souks, riads, desert escapes, and unforgettable events in one seamless app.',
      icon: Icons.travel_explore_rounded,
      accent: Color(0xFFD98F39),
    ),
    _OnboardData(
      city: 'Chefchaouen',
      title: 'Smart planning for every journey',
      body:
          'Search stays, compare transport, and generate itineraries around your real budget and dates.',
      icon: Icons.auto_awesome_rounded,
      accent: Color(0xFF0C6171),
    ),
    _OnboardData(
      city: 'Merzouga',
      title: 'Book with confidence',
      body:
          'Reserve experiences, follow notifications, and keep your whole trip organized from one place.',
      icon: Icons.payments_rounded,
      accent: Color(0xFFC96442),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  Future<void> _complete() async {
    final store = ref.read(secureStoreProvider);
    await store.writeOnboarded(true);
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintText = AppConfig.backendHint();
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'RIHLA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _complete,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) {
                      setState(() => _index = value);
                    },
                    itemBuilder: (context, i) {
                      return _OnboardItem(data: _pages[i]);
                    },
                  ),
                ),
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? const Color(0xFF0C6171)
                                  : const Color(0x330C6171),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        hintText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hintColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: _index == _pages.length - 1
                            ? 'Start Exploring'
                            : 'Continue',
                        icon: _index == _pages.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        onTap: () {
                          if (_index == _pages.length - 1) {
                            _complete();
                            return;
                          }
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ],
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

class _OnboardData {
  final String city;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  const _OnboardData({
    required this.city,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });
}

class _OnboardItem extends StatelessWidget {
  final _OnboardData data;

  const _OnboardItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.26),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
              ),
              Positioned(
                top: 28,
                left: 24,
                child: _CityBadge(city: data.city),
              ),
              Positioned(
                right: 24,
                top: 24,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 38),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: GlassCard(
                  padding: const EdgeInsets.all(22),
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 6,
                        decoration: BoxDecoration(
                          color: data.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CityBadge extends StatelessWidget {
  final String city;

  const _CityBadge({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            city,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
