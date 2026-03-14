import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';

class AssistantService {
  final Dio _dio;
  AssistantService(this._dio);

  /// Expected backend: POST /api/assistant/chat  body { message: "..." }
  Future<String> chat(String message) async {
    try {
      final r =
          await _dio.post('/api/assistant/chat', data: {'message': message});
      final data = r.data;
      if (data is String) return data;
      if (data is Map)
        return (data['reply'] ?? data['message'] ?? '').toString();
      return data.toString();
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final assistantServiceProvider = Provider<AssistantService>((ref) {
  final api = ref.read(apiClientProvider);
  return AssistantService(api.dio);
});
