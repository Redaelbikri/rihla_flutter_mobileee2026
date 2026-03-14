import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../core/api/api_helpers.dart';
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
    final intent = await createIntent(
      reservationId: reservationId,
      amountMad: amountMad,
    );
    final clientSecret = intent['clientSecret']?.toString();
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('clientSecret missing from /api/payments/create-intent');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'RIHLA',
        allowsDelayedPaymentMethods: true,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
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
}

final paymentsServiceProvider = Provider<PaymentsService>((ref) {
  final api = ref.read(apiClientProvider);
  return PaymentsService(api.dio);
});
