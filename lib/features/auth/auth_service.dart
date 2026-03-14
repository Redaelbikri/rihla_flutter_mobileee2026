import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_helpers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/di/providers.dart';

class AuthService {
  final Dio _dio;
  final AuthSession _session;

  AuthService(this._dio, this._session);

  Future<Map<String, dynamic>> loginStep1({
    required String email,
    required String password,
  }) async {
    try {
      final r = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    try {
      final r = await _dio.post(
        '/api/auth/verify-login',
        data: {'email': email, 'code': code},
      );
      final token = _readTokenFromJwtResponse(r.data);
      await _session.setToken(token);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<Map<String, dynamic>> signup({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String telephone,
  }) async {
    final body = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'telephone': telephone,
    };
    try {
      final r = await _dio.post('/api/auth/signup', data: body);
      return Map<String, dynamic>.from((r.data as Map?) ?? {});
    } on DioException catch (e) {
      // Backends sometimes expose /register instead of /signup.
      if (e.response?.statusCode == 404) {
        final r = await _dio.post('/api/auth/register', data: body);
        return Map<String, dynamic>.from((r.data as Map?) ?? {});
      }
      throw dioToApiError(e);
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final r = await _dio.post(
        '/api/auth/verify-email',
        data: {'email': email, 'code': code},
      );
      final token = _readTokenFromJwtResponse(r.data);
      await _session.setToken(token);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await _dio.post('/api/auth/resend-otp', data: {'email': email});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/api/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/api/auth/reset-password', data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> loginWithGoogleIdToken(String idToken) async {
    try {
      final r = await _dio.post('/api/auth/google', data: {'idToken': idToken});
      final token = _readTokenFromJwtResponse(r.data);
      await _session.setToken(token);
    } on DioException catch (e) {
      throw dioToApiError(e);
    }
  }

  Future<void> logout() async {
    await _session.logout();
  }

  Future<void> setSessionToken(String token) async {
    await _session.setToken(token);
  }

  String _readTokenFromJwtResponse(dynamic data) {
    final map = Map<String, dynamic>.from((data as Map?) ?? {});
    final token = map['accessToken'] ?? map['token'] ?? map['jwt'];
    if (token == null || token.toString().isEmpty) {
      throw ApiError(message: 'JWT missing in auth response');
    }
    return token.toString();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiClientProvider);
  final session = ref.read(authSessionProvider);
  return AuthService(api.dio, session);
});
