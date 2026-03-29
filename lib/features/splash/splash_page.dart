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
  late final AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _boot();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1700));
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
    } catch (_) {
      if (!mounted) return;
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFEFF5FF),
                    Color(0xFFDDEBFF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -100,
            child: _blurCircle(
              const Color(0xFF8BC6FF).withOpacity(0.45),
              260,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: _blurCircle(
              const Color(0xFF60D3E8).withOpacity(0.34),
              300,
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _orbitCtrl,
              builder: (_, __) {
                return Transform.rotate(
                  angle: _orbitCtrl.value * pi * 2,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x332470D6), width: 1.2),
                    ),
                    child: Stack(
                      children: List.generate(4, (i) {
                        final angle = (i / 4) * pi * 2;
                        return Positioned(
                          left: 92 + cos(angle) * 80,
                          top: 92 + sin(angle) * 80,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2F89F5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D8BFF), Color(0xFF22B8CF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D8BFF).withOpacity(0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 48),
                ).animate().fadeIn(duration: 420.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 18),
                const Text(
                  'Rihla',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: Color(0xFF15345D),
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 8),
                const Text(
                  'Discover • Book • Travel',
                  style: TextStyle(
                    color: Color(0xFF4B6790),
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 44),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}


