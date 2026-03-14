import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/reservation_model.dart';

class ReservationsService {
  final Dio _dio;
  ReservationsService(this._dio);

  Future<List<ReservationModel>> myReservations() async {
    try {
      final r = await _dio.get('/api/reservations/me');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list)
          .map(ReservationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<ReservationModel> createEvent({
    required String eventId,
    required int quantity,
  }) async {
    return _create({
      'event': {'id': eventId, 'quantity': quantity},
    });
  }

  Future<ReservationModel> createHebergement({
    required String hebergementId,
    required int quantity,
  }) async {
    return _create({
      'hebergement': {'id': hebergementId, 'quantity': quantity},
    });
  }

  Future<ReservationModel> createTransport({
    required String tripId,
    required int quantity,
  }) async {
    return _create({
      'transport': {'id': tripId, 'quantity': quantity},
    });
  }

  Future<ReservationModel> _create(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/api/reservations', data: body);
      return ReservationModel.fromJson(
        Map<String, dynamic>.from((r.data as Map?) ?? {}),
      );
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> cancel(String reservationId) async {
    try {
      await _dio.put('/api/reservations/$reservationId/cancel');
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getTickets(String reservationId) async {
    try {
      final r = await _dio.get('/api/reservations/$reservationId/tickets');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> getTicket(String ticketId) async {
    try {
      final r = await _dio.get('/api/reservations/tickets/$ticketId');
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final reservationsServiceProvider = Provider<ReservationsService>((ref) {
  final api = ref.read(apiClientProvider);
  return ReservationsService(api.dio);
});
