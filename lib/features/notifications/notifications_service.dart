import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/notification_model.dart';

class NotificationsService {
  final Dio _dio;
  NotificationsService(this._dio);

  Future<List<NotificationModel>> myNotifications() async {
    try {
      final r = await _dio.get('/api/notifications/me');
      final data = r.data;

      final list = (data is List)
          ? data
          : (data is Map && data['content'] is List ? data['content'] : []);

      return List<Map<String, dynamic>>.from(list)
          .map(NotificationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final r = await _dio.get('/api/notifications/me/unread-count');
      final map = Map<String, dynamic>.from((r.data as Map?) ?? {});
      final v = map['unread'];
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.put('/api/notifications/$id/read');
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final api = ref.read(apiClientProvider);
  return NotificationsService(api.dio);
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final service = ref.read(notificationsServiceProvider);
  try {
    yield await service.unreadCount();
  } catch (_) {
    yield 0;
  }
  yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
    try {
      return await service.unreadCount();
    } catch (_) {
      return 0;
    }
  });
});
