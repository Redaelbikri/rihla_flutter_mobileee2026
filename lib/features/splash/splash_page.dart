import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../profile/profile_service.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _boot();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final session = ref.read(authSessionProvider);
    final store = ref.read(secureStoreProvider);

    await session.init();
    final onboarded = await store.readOnboarded();
    if (!mounted) return;

    if (!onboarded) {
      context.go('/onboarding');
      return;
    }

    if (session.isAuthenticated) {
      try {
        await ref.read(profileServiceProvider).me();
      } catch (_) {
        await session.logout();
      }
    }

    if (!mounted) return;
    context.go(session.isAuthenticated ? '/app' : '/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C2D3D),
                    Color(0xFF0C6171),
                    Color(0xFF1A8B74),
                    Color(0xFFD98F39),
                  ],
                  stops: [0.0, 0.38, 0.72, 1.0],
                ),
              ),
            ),
          ),

          // Rotating decorative ring
          Center(
            child: AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _rotateCtrl.value * 2 * pi,
                  child: child,
                );
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: List.generate(6, (i) {
                    final angle = (i / 6) * 2 * pi;
                    return Positioned(
                      left: 95 + 88 * cos(angle),
                      top: 95 + 88 * sin(angle),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Second static ring
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF197278), Color(0xFFD98F39)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD98F39).withOpacity(0.5),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0C6171).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 1000.ms),

                const SizedBox(height: 24),

                const Text(
                  'RIHLA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 10),

                Text(
                  'Morocco. Reimagined.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 60),

                // Loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeOut(
                          delay: Duration(milliseconds: i * 200),
                          duration: const Duration(milliseconds: 600),
                        )
                        .then()
                        .fadeIn(duration: const Duration(milliseconds: 600));
                  }),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
