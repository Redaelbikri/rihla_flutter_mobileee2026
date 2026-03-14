import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/event_model.dart';

class EventsService {
  final Dio _dio;
  EventsService(this._dio);

  Future<List<EventModel>> list(
      {String? keyword, String? city, String? category}) async {
    try {
      Response r;

      if (keyword != null && keyword.trim().isNotEmpty) {
        r = await _dio.get('/api/events/search',
            queryParameters: {'keyword': keyword.trim()});
      } else if (city != null && city.trim().isNotEmpty) {
        r = await _dio.get('/api/events/filter/city',
            queryParameters: {'city': city.trim()});
      } else if (category != null && category.trim().isNotEmpty) {
        r = await _dio.get('/api/events/filter/category',
            queryParameters: {'category': category.trim()});
      } else {
        r = await _dio.get('/api/events');
      }

      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list)
          .map(EventModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<EventModel> getById(String id) async {
    try {
      final r = await _dio.get('/api/events/$id');
      return EventModel.fromJson(Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> details(String id) async {
    try {
      final r = await _dio.get('/api/events/$id/details');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<bool> availability(String id, {int quantity = 1}) async {
    try {
      final r = await _dio.get(
        '/api/events/$id/availability',
        queryParameters: {'quantity': quantity},
      );
      return r.data == true;
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final eventsServiceProvider = Provider<EventsService>((ref) {
  final api = ref.read(apiClientProvider);
  return EventsService(api.dio);
});
