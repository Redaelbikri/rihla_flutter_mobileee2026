import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/glass.dart';
import '../../core/ui/primary_button.dart';
import 'auth_service.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final email = TextEditingController();
  final code = TextEditingController();
  final newPassword = TextEditingController();
  bool sent = false;
  bool loading = false;
  String? error;

  Future<void> sendOtp() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .forgotPassword(email: email.text.trim());
      if (mounted) {
        setState(() => sent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent if email exists.')),
        );
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> reset() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await ref.read(authServiceProvider).resetPassword(
            email: email.text.trim(),
            code: code.text.trim(),
            newPassword: newPassword.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  if (!sent)
                    PrimaryButton(
                      label: 'Send OTP',
                      loading: loading,
                      icon: Icons.mark_email_read_rounded,
                      onTap: sendOtp,
                    ),
                  if (sent) ...[
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'OTP Code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassword,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'New Password'),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Reset Password',
                      loading: loading,
                      icon: Icons.lock_reset_rounded,
                      onTap: reset,
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
