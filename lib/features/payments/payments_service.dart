import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../core/api/api_helpers.dart';
import '../../core/config/app_config.dart';
import '../../core/di/providers.dart';

class PaymentsService {
  final Dio _dio;
  PaymentsService(this._dio);

  Future<Map<String, dynamic>> createIntent({
    required String reservationId,
    required double amountMad,
  }) async {
    try {
      final r = await _dio.post('/api/payments/create-intent', data: {
        'reservationId': reservationId,
        'amountMad': amountMad.round(),
      });
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> payReservation({
    required String reservationId,
    required double amountMad,
  }) async {
    // Guard: Stripe must be initialized with the correct publishable key
    if (AppConfig.stripePublishableKey.isEmpty) {
      throw Exception(
        'Stripe publishable key not configured.\n'
        'Run with: --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...\n'
        'The publishable key MUST be from the same Stripe account as the backend secret key.',
      );
    }

    final intent = await createIntent(
      reservationId: reservationId,
      amountMad: amountMad,
    );

    // Backend returns {paymentIntentId, clientSecret}
    // Flutter Stripe SDK needs clientSecret, NOT paymentIntentId
    final clientSecret = intent['clientSecret']?.toString();
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception(
        'clientSecret missing from /api/payments/create-intent response.\n'
        'Check backend payment-service logs.',
      );
    }

    // Validate: clientSecret must start with "pi_" or "seti_" prefix extracted correctly
    // Format: pi_XXXXXXXX_secret_YYYYYYYY
    if (!clientSecret.contains('_secret_')) {
      throw Exception(
        'Invalid clientSecret format received from backend.\n'
        'Expected format: pi_xxx_secret_yyy\n'
        'Received: ${clientSecret.substring(0, clientSecret.length.clamp(0, 20))}...',
      );
    }

    final paymentIntentId = intent['paymentIntentId']?.toString();

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RIHLA',
          allowsDelayedPaymentMethods: false,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF0C6171),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 16,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Notify backend of payment success.
      // Stripe webhooks can't reach a local IP, so we trigger it manually.
      // stripe.skipVerification=true on the backend skips signature check.
      if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
        try {
          await _dio.post('/api/payments/webhook', data: {
            'type': 'payment_intent.succeeded',
            'data': {
              'object': {'id': paymentIntentId}
            },
          });
        } catch (_) {
          // Non-critical: webhook call failed, reservation stays PENDING_PAYMENT
        }
      }
    } on StripeException catch (e) {
      final code = e.error.stripeErrorCode ?? '';
      final msg = e.error.message ?? e.error.localizedMessage;

      // Detect account mismatch: frontend publishable key account ≠ backend secret key account
      if (code == 'resource_missing' || (msg?.contains('No such payment_intent') == true)) {
        throw Exception(
          'Stripe account mismatch detected!\n\n'
          'The PaymentIntent was created by the backend using a secret key from one Stripe account, '
          'but the frontend publishable key belongs to a different account.\n\n'
          'Fix: The backend STRIPE_SECRET_KEY must match the frontend publishable key account (51TBONNHW).\n'
          'Current frontend key: pk_test_51TBONNHWgarvtGr...\n'
          'Backend secret key must start with: sk_test_51TBONNHWgarvtGr...\n\n'
          'Original Stripe error: $msg',
        );
      }

      // User cancelled payment — not an error
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Payment cancelled.');
      }

      throw Exception('Payment failed: $msg');
    }
  }

  Future<List<Map<String, dynamic>>> myPayments() async {
    try {
      final r = await _dio.get('/api/payments/me');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<List<Map<String, dynamic>>> myInvoices() async {
    try {
      final r = await _dio.get('/api/payments/invoices/me');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    try {
      final r = await _dio.get('/api/payments/invoices/$id');
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  final api = ref.read(apiClientProvider);
  return PaymentsService(api.dio);
});
