import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_session.dart';
import '../config/app_config.dart';
import '../storage/secure_store.dart';

class ApiClient {
  final Dio dio;
  final SecureStore store;
  final AuthSession authSession;

  ApiClient({
    required this.dio,
    required this.store,
    required this.authSession,
  });

  factory ApiClient.create({required AuthSession authSession}) {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    final store = SecureStore();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await store.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto-logout only when an authenticated request fails.
        final status = error.response?.statusCode ?? 0;
        final hadAuthHeader =
            (error.requestOptions.headers['Authorization'] ?? '')
                .toString()
                .startsWith('Bearer ');
        final path = error.requestOptions.path.toString();
        final isAuthEndpoint = path.startsWith('/api/auth/');

        if ((status == 401 || status == 403) && hadAuthHeader && !isAuthEndpoint) {
          await authSession.logout();
        }
        handler.next(error);
      },
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ));
    }

    if (kDebugMode) {
      // Visible base URL in debug to verify dart-define injection
      // ignore: avoid_print
      print('BASE_URL => ${dio.options.baseUrl}');
    }
    return ApiClient(dio: dio, store: store, authSession: authSession);
  }
}
