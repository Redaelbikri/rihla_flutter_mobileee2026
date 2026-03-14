import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/review_model.dart';

class ReviewsService {
  final Dio _dio;
  ReviewsService(this._dio);

  String _apiType(String type) {
    switch (type.toUpperCase()) {
      case 'EVENT':
        return 'EVENT';
      case 'HEBERGEMENT':
      case 'STAY':
      case 'HOTEL':
      case 'ACCOMMODATION':
        return 'ACCOMMODATION';
      case 'TRANSPORT':
      case 'TRIP':
        return 'TRANSPORT';
      default:
        return 'EVENT';
    }
  }

  Future<List<ReviewModel>> list({required String type, required String id}) async {
    try {
      final r = await _dio.get('/api/reviews/${_apiType(type)}/$id');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list)
          .map(ReviewModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> stats({required String type, required String id}) async {
    try {
      final r = await _dio.get('/api/reviews/${_apiType(type)}/$id/stats');
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> create({
    required String type,
    required String targetId,
    required double rating,
    required String comment,
  }) async {
    try {
      final dto = {
        'targetType': _apiType(type),
        'targetId': targetId,
        'rating': rating.round().clamp(1, 5),
        'commentaire': comment,
      };

      final form = FormData.fromMap({
        'dto': MultipartFile.fromString(
          jsonEncode(dto),
          filename: 'dto.json',
          contentType: DioMediaType('application', 'json'),
        ),
      });

      await _dio.post('/api/reviews', data: form);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final reviewsServiceProvider = Provider<ReviewsService>((ref) {
  final api = ref.read(apiClientProvider);
  return ReviewsService(api.dio);
});
