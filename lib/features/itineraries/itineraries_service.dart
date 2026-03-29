import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';

class ItinerariesService {
  final Dio _dio;
  ItinerariesService(this._dio);

  Future<Map<String, dynamic>> generate({
    required String fromCity,
    required String toCity,
    required DateTime startDate,
    required int days,
    required List<String> interests,
    required double maxEventPrice,
    required double maxNightPrice,
    String? transportType,
    int limitPerDay = 3,
  }) async {
    final safeDays = days < 1 ? 1 : days;
    final endDate = startDate.add(Duration(days: safeDays - 1));
    final fmt = DateFormat('yyyy-MM-dd');

    try {
      final r = await _dio.post('/api/itineraries/generate', data: {
        'fromCity': fromCity,
        'toCity': toCity,
        'startDate': fmt.format(startDate),
        'endDate': fmt.format(endDate),
        'interests': interests,
        'maxEventPrice': maxEventPrice,
        'maxNightPrice': maxNightPrice,
        'transportType': transportType ?? 'TRAIN',
        'limitPerDay': limitPerDay,
      });
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<List<Map<String, dynamic>>> myHistory() async {
    try {
      final r = await _dio.get('/api/itineraries/me');
      final data = r.data;
      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);
      return List<Map<String, dynamic>>.from(list).map((item) {
        final map = Map<String, dynamic>.from(item);
        final payload = map['payload'];
        if (payload is Map) {
          map['payload'] = Map<String, dynamic>.from(payload);
        }
        return map;
      }).toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final itinerariesServiceProvider = Provider<ItinerariesService>((ref) {
  final api = ref.read(apiClientProvider);
  return ItinerariesService(api.dio);
});
