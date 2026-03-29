import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import 'auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? from;
  const LoginPage({super.key, this.from});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _err;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _err = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final res = await ref.read(authServiceProvider).loginStep1(email: email, password: password);
      final requiresOtp = res['requiresOtp'] == true;

      if (!mounted) return;
      if (requiresOtp) {
        final fromParam = (widget.from?.isNotEmpty == true)
            ? '&from=${Uri.encodeComponent(widget.from!)}'
            : '';
        context.push('/auth/otp?flow=login&email=${Uri.encodeComponent(email)}$fromParam');
        return;
      }

      final token = (res['accessToken'] ?? res['token'] ?? res['jwt'])?.toString();
      if (token == null || token.isEmpty) {
        setState(() => _err = 'Unexpected server response. Please retry.');
        return;
      }

      await ref.read(authServiceProvider).setSessionToken(token);
      if (!mounted) return;
      context.go((widget.from?.isNotEmpty == true) ? widget.from! : '/app');
    } catch (e) {
      setState(() => _err = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
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
          Positioned(top: -80, right: -80, child: _blur(const Color(0x5558A6FF), 220)),
          Positioned(bottom: -100, left: -90, child: _blur(const Color(0x553FCFD8), 240)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 33, fontWeight: FontWeight.w800, color: Color(0xFF14385F)),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue your trip with Rihla',
                    style: TextStyle(color: Color(0xFF5F7898), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : () => context.push('/auth/forgot-password'),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                            if (_err != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFC9C9)),
                                ),
                                child: Text(_err!, style: const TextStyle(color: Color(0xFFB3261E))),
                              ),
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
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _loading ? null : _loginWithGoogle,
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                                label: const Text('Continue with Google'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 14),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('No account yet?', style: TextStyle(color: Color(0xFF5F7898))),
                        TextButton(
                          onPressed: _loading ? null : () => context.push('/auth/register${widget.from != null ? '?from=${Uri.encodeComponent(widget.from!)}' : ''}'),
                          child: const Text('Create one'),
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


