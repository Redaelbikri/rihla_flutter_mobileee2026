import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/di/providers.dart';
import '../../core/models/user_model.dart';

class ProfileService {
  final Dio _dio;
  ProfileService(this._dio);

  Future<UserModel> me() async {
    try {
      final r = await _dio.get('/api/users/me');
      return UserModel.fromJson(Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<UserModel> update(Map<String, dynamic> body) async {
    try {
      final r = await _dio.put('/api/users/me', data: body);
      return UserModel.fromJson(Map<String, dynamic>.from(r.data as Map));
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  final api = ref.read(apiClientProvider);
  return ProfileService(api.dio);
});
