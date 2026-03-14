import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/ui/gradients.dart';
import '../profile/profile_service.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(seconds: 1));
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                  const SizedBox(height: 22),
                  Text(
                    'RIHLA',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Travel, events, bookings and AI planning',
                    style: theme.textTheme.bodyLarge,
                  ).animate().fadeIn(delay: 250.ms, duration: 600.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
