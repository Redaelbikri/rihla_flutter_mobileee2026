import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/ui/gradients.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final controller = PageController();
  int index = 0;

  final pages = const [
    _OnboardItem(
      title: 'Plan better trips',
      body:
          'Discover events, stays, and transport in one place with real-time availability.',
      icon: Icons.travel_explore_rounded,
    ),
    _OnboardItem(
      title: 'Smart itineraries',
      body:
          'Generate AI itineraries based on your budget, interests, and dates.',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardItem(
      title: 'Book and pay securely',
      body:
          'Reserve tickets, rooms, and seats then pay with a streamlined checkout.',
      icon: Icons.payments_rounded,
    ),
  ];

  Future<void> complete() async {
    final store = ref.read(secureStoreProvider);
    await store.writeOnboarded(true);
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (v) => setState(() => index = v),
                  itemBuilder: (context, i) => pages[i],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(i == index ? 0.9 : 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: complete,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0E5A6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        if (index == pages.length - 1) {
                          complete();
                        } else {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      icon: Icon(
                        index == pages.length - 1
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(index == pages.length - 1 ? 'Start' : 'Next'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardItem extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _OnboardItem({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: t.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
