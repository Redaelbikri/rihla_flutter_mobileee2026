import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _s = FlutterSecureStorage();
  static const _kToken = 'jwt_token';
  static const _kOnboarded = 'onboarded';

  Future<void> writeToken(String token) => _s.write(key: _kToken, value: token);
  Future<String?> readToken() => _s.read(key: _kToken);
  Future<void> deleteToken() => _s.delete(key: _kToken);
  Future<void> clear() => _s.delete(key: _kToken);

  Future<void> writeOnboarded(bool value) =>
      _s.write(key: _kOnboarded, value: value ? 'true' : 'false');
  Future<bool> readOnboarded() async =>
      (await _s.read(key: _kOnboarded)) == 'true';
}
