import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      title: 'Discover dream destinations',
      body: 'Find handpicked places, top stays, and travel ideas in seconds.',
      icon: Icons.explore_rounded,
      image: 'https://images.unsplash.com/photo-1539650116574-75c0c6d73f9e?auto=format&fit=crop&w=1080&q=80',
    ),
    _Slide(
      title: 'Book everything in one app',
      body: 'Reserve hotels, trips, and transport with a smooth booking flow.',
      icon: Icons.book_online_rounded,
      image: 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1080&q=80',
    ),
    _Slide(
      title: 'Travel with confidence',
      body: 'Track bookings, manage your profile, and enjoy premium UX.',
      icon: Icons.luggage_rounded,
      image: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=1080&q=80',
    ),
  ];

  Future<void> _complete() async {
    await ref.read(secureStoreProvider).writeOnboarded(true);
    if (!mounted) return;
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (v) => setState(() => _index = v),
              itemBuilder: (_, i) => _SlideView(data: _slides[i]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Rihla',
                          style: TextStyle(
                            color: Color(0xFF17406B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(onPressed: _complete, child: const Text('Skip')),
                    ],
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.8)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _slides.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: i == _index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _index ? const Color(0xFF1B74E4) : const Color(0x662A67A6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (_index == _slides.length - 1) {
                                    _complete();
                                    return;
                                  }
                                  _controller.nextPage(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOut,
                                  );
                                },
                                icon: Icon(_index == _slides.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                                label: Text(_index == _slides.length - 1 ? 'Start' : 'Continue'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String title;
  final String body;
  final IconData icon;
  final String image;

  const _Slide({
    required this.title,
    required this.body,
    required this.icon,
    required this.image,
  });
}

class _SlideView extends StatelessWidget {
  final _Slide data;
  const _SlideView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(data.image, fit: BoxFit.cover),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x220E2745), Color(0xCC0E2745)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 110, 24, 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 32),
                ).animate().scale(duration: 300.ms),
                const Spacer(),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(duration: 360.ms),
                const SizedBox(height: 10),
                Text(
                  data.body,
                  style: const TextStyle(
                    color: Color(0xFFD8E8FF),
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 120.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


