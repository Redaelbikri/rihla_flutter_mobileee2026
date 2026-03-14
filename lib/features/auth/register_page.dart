import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/gradients.dart';
import '../../core/ui/primary_button.dart';
import 'auth_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String? from;
  const RegisterPage({super.key, this.from});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final prenom = TextEditingController();
  final nom = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  String? err;

  Future<void> submit() async {
    setState(() {
      loading = true;
      err = null;
    });

    try {
      await ref.read(authServiceProvider).signup(
            prenom: prenom.text.trim(),
            nom: nom.text.trim(),
            email: email.text.trim(),
            password: password.text,
            telephone: phone.text.trim(),
          );

      if (mounted) {
        final fromParam =
            (widget.from != null && widget.from!.isNotEmpty)
                ? '&from=${Uri.encodeComponent(widget.from!)}'
                : '';
        context.push(
          '/auth/otp?flow=signup&email=${Uri.encodeComponent(email.text.trim())}$fromParam',
        );
      }
    } catch (e) {
      setState(() => err = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> joinWithGoogle() async {
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(Icons.person_add_alt_1_rounded, size: 32),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Join RIHLA',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your account in seconds.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: prenom,
                            decoration: const InputDecoration(labelText: 'Prenom'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: nom,
                            decoration: const InputDecoration(labelText: 'Nom'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phone,
                      decoration: const InputDecoration(labelText: 'Telephone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (err != null) ...[
                      const SizedBox(height: 10),
                      Text(err!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Join Rihla',
                      loading: loading,
                      onTap: submit,
                      icon: Icons.verified_user_rounded,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: loading ? null : joinWithGoogle,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('Join with Google'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: () => context.go('/auth/login'),
                          child: const Text(
                            'Sign in',
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
