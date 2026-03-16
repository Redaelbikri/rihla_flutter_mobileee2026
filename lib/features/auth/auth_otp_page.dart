import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focuses = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendCountdown = 60;
  Timer? _timer;

  bool get _isSignup => widget.flow == 'signup';

  String get _otp =>
      _ctrls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _submit() async {
    final otp = _otp;
    if (otp.length < 6) {
      setState(() => _error = 'Please enter the complete 6-digit code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignup) {
        await ref.read(authServiceProvider).verifyEmailOtp(
              email: widget.email,
              code: otp,
            );
      } else {
        await ref.read(authServiceProvider).verifyLoginOtp(
              email: widget.email,
              code: otp,
            );
      }
      if (mounted) {
        context.go((widget.from?.isNotEmpty == true) ? widget.from! : '/app');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      // Clear OTP on error
      for (final c in _ctrls) c.clear();
      if (mounted) _focuses[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .resendOtp(email: widget.email);
      if (mounted) {
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP resent to your email'),
            backgroundColor: const Color(0xFF0C6171),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _onDigitChange(String val, int index) {
    if (val.length == 1) {
      if (index < 5) {
        _focuses[index + 1].requestFocus();
      } else {
        _focuses[index].unfocus();
        _submit();
      }
    } else if (val.isEmpty && index > 0) {
      _focuses[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D1B2A),
                    Color(0xFF0C6171),
                    Color(0xFF1A8B74),
                  ],
                ),
              ),
            ),
          ),

          // Decorative
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Icon
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF197278),
                                    Color(0xFF0C6171)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0C6171)
                                        .withOpacity(0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1, 1)),

                            const SizedBox(height: 28),

                            Text(
                              _isSignup
                                  ? 'Verify your email'
                                  : 'Two-step verification',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                            const SizedBox(height: 10),

                            Text(
                              'Enter the 6-digit code sent to\n${widget.email}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                            const SizedBox(height: 36),

                            // OTP inputs
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (i) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  width: 48,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _ctrls[i].text.isNotEmpty
                                          ? const Color(0xFF0C6171)
                                          : Colors.grey.shade300,
                                      width: _ctrls[i].text.isNotEmpty ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _ctrls[i],
                                    focusNode: _focuses[i],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      counterText: '',
                                    ),
                                    onChanged: (val) =>
                                        _onDigitChange(val, i),
                                  ),
                                );
                              }),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.1, end: 0),

                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),

                            // Verify button
                            GestureDetector(
                              onTap: _loading ? null : _submit,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _loading
                                        ? [
                                            Colors.grey.shade700,
                                            Colors.grey.shade600
                                          ]
                                        : const [
                                            Color(0xFF0C6171),
                                            Color(0xFF197278)
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _loading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF0C6171)
                                                .withOpacity(0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Verify Code',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.verified_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                            const SizedBox(height: 20),

                            // Resend
                            GestureDetector(
                              onTap: (_resendCountdown > 0 || _resending)
                                  ? null
                                  : _resend,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _resending
                                    ? const CircularProgressIndicator(
                                        color: Colors.white60, strokeWidth: 2)
                                    : _resendCountdown > 0
                                        ? Text(
                                            'Resend code in ${_resendCountdown}s',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              fontSize: 14,
                                            ),
                                          )
                                        : const Text(
                                            'Resend code',
                                            style: TextStyle(
                                              color: Color(0xFFD98F39),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
