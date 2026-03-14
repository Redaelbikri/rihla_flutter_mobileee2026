import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../auth/auth_session.dart';
import '../storage/secure_store.dart';

final authSessionProvider = Provider<AuthSession>((ref) {
  final session = AuthSession(SecureStore());
  session.init();
  return session;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.read(authSessionProvider);
  return ApiClient.create(authSession: session);
});
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());
