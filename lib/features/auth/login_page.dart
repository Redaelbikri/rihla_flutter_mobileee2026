import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/gradients.dart';
import '../../core/ui/primary_button.dart';
import 'auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? from;
  const LoginPage({super.key, this.from});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? err;

  Future<void> submit() async {
    setState(() {
      loading = true;
      err = null;
    });

    try {
      final res = await ref.read(authServiceProvider).loginStep1(
            email: email.text.trim(),
            password: password.text,
          );

      final requiresOtp = (res['requiresOtp'] == true);
      if (requiresOtp && mounted) {
        final fromParam =
            (widget.from != null && widget.from!.isNotEmpty)
                ? '&from=${Uri.encodeComponent(widget.from!)}'
                : '';
        context.push(
          '/auth/otp?flow=login&email=${Uri.encodeComponent(email.text.trim())}$fromParam',
        );
      } else {
        final token = (res['accessToken'] ?? res['token'] ?? res['jwt'])?.toString();
        if (token != null && token.isNotEmpty) {
          await ref.read(authServiceProvider).setSessionToken(token);
          if (mounted) {
            final dest = (widget.from != null && widget.from!.isNotEmpty)
                ? widget.from!
                : '/app';
            context.go(dest);
          }
        } else {
          setState(() => err = 'Login response invalid: requiresOtp/token missing.');
        }
      }
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      final google = GoogleSignIn(scopes: const ['email', 'profile']);
      await google.signOut();
      final account = await google.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google idToken missing. Check native Google Sign-In setup.');
      }

      await ref.read(authServiceProvider).loginWithGoogleIdToken(idToken);
      if (mounted) {
        final dest = (widget.from != null && widget.from!.isNotEmpty)
            ? widget.from!
            : '/app';
        context.go(dest);
      }
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.lock_open_rounded, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome Back',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to continue your journey.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : () => context.push('/auth/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (err != null) ...[
                      const SizedBox(height: 10),
                      Text(err!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Log In',
                      loading: loading,
                      onTap: submit,
                      icon: Icons.lock_open_rounded,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading ? null : loginWithGoogle,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () => context.go('/auth/register'),
                          child: const Text(
                            'Join Rihla',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0, duration: 650.ms),
            ),
          ),
        ),
      ),
    );
  }
}
