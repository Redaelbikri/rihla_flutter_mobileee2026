import 'package:flutter/foundation.dart';

import '../storage/secure_store.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthSession extends ChangeNotifier {
  final SecureStore _store;

  AuthSession(this._store);

  AuthStatus _status = AuthStatus.unknown;

  bool get initialized => _status != AuthStatus.unknown;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  Future<void> init() async {
    final token = await _store.readToken();
    _status =
        (token != null && token.isNotEmpty) ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    await _store.writeToken(token);
    _status =
        token.isNotEmpty ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _store.clear();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
