import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'auth_service.dart';

class AuthOtpPage extends ConsumerStatefulWidget {
  final String email;
  final String flow; // login | signup
  final String? from;

  const AuthOtpPage({
    super.key,
    required this.email,
    required this.flow,
    this.from,
  });

  @override
  ConsumerState<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends ConsumerState<AuthOtpPage> {
  final code = TextEditingController();
  bool loading = false;
  bool resending = false;
  String? error;

  bool get isSignup => widget.flow == 'signup';

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (isSignup) {
        await ref.read(authServiceProvider).verifyEmailOtp(
              email: widget.email,
              code: code.text.trim(),
            );
      } else {
        await ref.read(authServiceProvider).verifyLoginOtp(
              email: widget.email,
              code: code.text.trim(),
            );
      }
      if (mounted) {
        final dest =
            (widget.from != null && widget.from!.isNotEmpty)
                ? widget.from!
                : '/app';
        context.go(dest);
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resend() async {
    setState(() {
      resending = true;
      error = null;
    });
    try {
      await ref.read(authServiceProvider).resendOtp(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent')),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSignup ? 'Verify your email' : 'Verify your login',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.email),
                  const SizedBox(height: 12),
                  TextField(
                    controller: code,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Verify',
                    loading: loading,
                    icon: Icons.verified_rounded,
                    onTap: submit,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: resending ? null : resend,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(resending ? 'Resending...' : 'Resend OTP'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
