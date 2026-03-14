import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/event_model.dart';
import '../../core/models/hebergement_model.dart';
import '../../core/models/trip_model.dart';

class RecommendationsBundle {
  final List<EventModel> events;
  final List<TripModel> trips;
  final List<HebergementModel> stays;

  const RecommendationsBundle({
    required this.events,
    required this.trips,
    required this.stays,
  });
}

class RecommendationsService {
  final Dio _dio;
  RecommendationsService(this._dio);

  Future<RecommendationsBundle> fetch({
    String? city,
    String? category,
    String? fromCity,
    String? toCity,
    String? date,
    String? transportType,
    double? maxEventPrice,
    double? maxNightPrice,
    int? limit,
  }) async {
    try {
      final r = await _dio.get(
        '/api/recommendations',
        queryParameters: {
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
          if (fromCity != null && fromCity.trim().isNotEmpty) 'fromCity': fromCity.trim(),
          if (toCity != null && toCity.trim().isNotEmpty) 'toCity': toCity.trim(),
          if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
          if (transportType != null && transportType.trim().isNotEmpty) 'transportType': transportType.trim(),
          if (maxEventPrice != null) 'maxEventPrice': maxEventPrice,
          if (maxNightPrice != null) 'maxNightPrice': maxNightPrice,
          if (limit != null) 'limit': limit,
        },
      );

      final map = Map<String, dynamic>.from((r.data as Map?) ?? {});
      final events = ((map['events'] as List?) ?? const [])
          .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final trips = ((map['trips'] as List?) ?? const [])
          .map((e) => TripModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final stays = ((map['hebergements'] as List?) ?? const [])
          .map((e) => HebergementModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return RecommendationsBundle(events: events, trips: trips, stays: stays);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final recommendationsServiceProvider = Provider<RecommendationsService>((ref) {
  final api = ref.read(apiClientProvider);
  return RecommendationsService(api.dio);
});
