import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/hebergement_model.dart';

class HebergementsService {
  final Dio _dio;
  HebergementsService(this._dio);

  Future<List<HebergementModel>> list(
      {String? city, double? maxPrice, String? type}) async {
    try {
      final Response r;
      if (type != null && type.trim().isNotEmpty) {
        r = await _dio.get('/api/hebergements/filter/type/${type.trim()}');
      } else {
        r = await _dio.get('/api/hebergements', queryParameters: {
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (maxPrice != null) 'maxPrice': maxPrice,
        });
      }

      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list)
          .map(HebergementModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<HebergementModel> getById(String id) async {
    try {
      final r = await _dio.get('/api/hebergements/$id');
      return HebergementModel.fromJson(
          Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> ratingStats(String id) async {
    try {
      final r = await _dio.get('/api/hebergements/$id/rating-stats');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<bool> checkAvailability(String id, {int quantity = 1}) async {
    try {
      final r = await _dio.get('/api/hebergements/$id/check',
          queryParameters: {'quantity': quantity});
      return r.data == true;
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final hebergementsServiceProvider = Provider<HebergementsService>((ref) {
  final api = ref.read(apiClientProvider);
  return HebergementsService(api.dio);
});
