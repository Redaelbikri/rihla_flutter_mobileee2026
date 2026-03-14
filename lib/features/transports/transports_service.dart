import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/trip_model.dart';

class TransportsService {
  final Dio _dio;
  TransportsService(this._dio);
  Future<List<TripModel>> searchTrips({
    required String fromCity,
    required String toCity,
    required String date,
    String type = 'TRAIN',
  }) async {
    try {
      final r = await _dio.get(
        '/api/transports/trips/search',
        queryParameters: {
          'fromCity': fromCity,
          'toCity': toCity,
          'date': date,
          'type': type,
        },
      );

      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);

      return List<Map<String, dynamic>>.from(list)
          .map(TripModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<TripModel> getTrip(String id) async {
    try {
      final r = await _dio.get('/api/transports/trips/$id');
      return TripModel.fromJson(Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> ratingStats(String id) async {
    try {
      final r = await _dio.get('/api/transports/trips/$id/rating-stats');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<bool> checkAvailability(String id, {int quantity = 1}) async {
    try {
      final r = await _dio.get('/api/transports/trips/$id/check',
          queryParameters: {'quantity': quantity});
      return r.data == true;
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final transportsServiceProvider = Provider<TransportsService>((ref) {
  final api = ref.read(apiClientProvider);
  return TransportsService(api.dio);
});
