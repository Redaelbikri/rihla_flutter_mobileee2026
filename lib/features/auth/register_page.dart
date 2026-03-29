import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import 'auth_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String? from;
  const RegisterPage({super.key, this.from});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _err;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prenom = _prenomCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (prenom.isEmpty || nom.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _err = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await ref.read(authServiceProvider).signup(
            prenom: prenom,
            nom: nom,
            email: email,
            password: password,
            telephone: phone,
          );

      if (!mounted) return;
      final fromParam = (widget.from?.isNotEmpty == true)
          ? '&from=${Uri.encodeComponent(widget.from!)}'
          : '';
      context.push('/auth/otp?flow=signup&email=${Uri.encodeComponent(email)}$fromParam');
    } catch (e) {
      setState(() => _err = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinWithGoogle() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConfig.googleClientId,
      );
      await google.signOut();
      final account = await google.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google login failed: idToken is missing.');
      }
      await ref.read(authServiceProvider).loginWithGoogleIdToken(idToken);
      if (!mounted) return;
      context.go((widget.from?.isNotEmpty == true) ? widget.from! : '/app');
    } catch (e) {
      setState(() => _err = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  colors: [Color(0xFFFFFFFF), Color(0xFFEFF5FF), Color(0xFFDCEAFE)],
                ),
              ),
            ),
          ),
          Positioned(top: -100, left: -80, child: _blur(const Color(0x444EA7FF), 220)),
          Positioned(bottom: -100, right: -90, child: _blur(const Color(0x4430C1D6), 240)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create account',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF14385F)),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'Start booking premium trips with Rihla',
                    style: TextStyle(color: Color(0xFF5F7898), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.84),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _prenomCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'First name',
                                      prefixIcon: Icon(Icons.person_outline_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _nomCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Last name',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone number (optional)',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                ),
                              ),
                            ),
                            if (_err != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFC9C9)),
                                ),
                                child: Text(_err!, style: const TextStyle(color: Color(0xFFB3261E))),
                              ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _joinWithGoogle,
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                                label: const Text('Sign up with Google'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Already have an account?', style: TextStyle(color: Color(0xFF5F7898))),
                        TextButton(
                          onPressed: _loading ? null : () => context.go('/auth/login${widget.from != null ? '?from=${Uri.encodeComponent(widget.from!)}' : ''}'),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blur(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}


