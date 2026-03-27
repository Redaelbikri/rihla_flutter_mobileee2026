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
      final rawItems = List<Map<String, dynamic>>.from(list);
      final models = await Future.wait(
        rawItems.map(_hydrateReservation),
      );
      models.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      return models;
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

  Future<ReservationModel> _hydrateReservation(
    Map<String, dynamic> raw,
  ) async {
    final itemType = _reservationType(raw);
    final itemId = _itemId(raw);
    final quantity = _quantity(raw);

    if (itemType == null || itemId == null) {
      return ReservationModel.fromJson(raw);
    }

    try {
      final detail = await _fetchReservationTarget(itemType, itemId);
      final enriched = Map<String, dynamic>.from(raw)
        ..['type'] = itemType
        ..['itemId'] = itemId
        ..addAll(_decorateReservation(itemType, detail, quantity));
      return ReservationModel.fromJson(enriched);
    } on DioException {
      return ReservationModel.fromJson(raw);
    }
  }

  String? _reservationType(Map<String, dynamic> raw) {
    if (raw['eventId'] != null) return 'EVENT';
    if (raw['hebergementId'] != null) return 'HEBERGEMENT';
    if (raw['transportTripId'] != null) return 'TRANSPORT';
    return raw['type']?.toString();
  }

  String? _itemId(Map<String, dynamic> raw) {
    return (raw['eventId'] ??
            raw['hebergementId'] ??
            raw['transportTripId'] ??
            raw['itemId'])
        ?.toString();
  }

  int _quantity(Map<String, dynamic> raw) {
    final value = raw['eventTickets'] ??
        raw['hebergementRooms'] ??
        raw['transportSeats'] ??
        raw['quantity'];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 1;
  }

  Future<Map<String, dynamic>> _fetchReservationTarget(
    String type,
    String id,
  ) async {
    switch (type.toUpperCase()) {
      case 'EVENT':
        final r = await _dio.get('/api/events/$id');
        return Map<String, dynamic>.from((r.data as Map?) ?? {});
      case 'HEBERGEMENT':
        final r = await _dio.get('/api/hebergements/$id');
        return Map<String, dynamic>.from((r.data as Map?) ?? {});
      case 'TRANSPORT':
        final r = await _dio.get('/api/transports/trips/$id');
        return Map<String, dynamic>.from((r.data as Map?) ?? {});
      default:
        return const {};
    }
  }

  Map<String, dynamic> _decorateReservation(
    String type,
    Map<String, dynamic> detail,
    int quantity,
  ) {
    switch (type.toUpperCase()) {
      case 'EVENT':
        final amount = _toDouble(detail['prix'] ?? detail['price']);
        return {
          'title': detail['nom'] ?? detail['title'] ?? 'Event reservation',
          'imageUrl': detail['imageUrl'],
          'amount': amount != null ? amount * quantity : null,
        };
      case 'HEBERGEMENT':
        final amount = _toDouble(
          detail['prixParNuit'] ?? detail['pricePerNight'] ?? detail['price'],
        );
        return {
          'title': detail['nom'] ?? detail['name'] ?? 'Stay reservation',
          'imageUrl': detail['imageUrl'],
          'amount': amount != null ? amount * quantity : null,
        };
      case 'TRANSPORT':
        final amount = _toDouble(detail['price'] ?? detail['amount']);
        final fromCity = detail['fromCity']?.toString() ?? '-';
        final toCity = detail['toCity']?.toString() ?? '-';
        return {
          'title': '$fromCity -> $toCity',
          'amount': amount != null ? amount * quantity : null,
        };
      default:
        return const {};
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}

final reservationsServiceProvider = Provider<ReservationsService>((ref) {
  final api = ref.read(apiClientProvider);
  return ReservationsService(api.dio);
});
