import 'package:flutter/foundation.dart';

class AppConfig {
  // For Android emulator pointing to backend on the same PC
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8080';
  // For physical device or desktop — backend runs on same laptop
  static const String defaultDesktopAndWebUrl = 'http://127.0.0.1:8080';
  // Current Wi-Fi LAN address from ipconfig on 2026-03-27
  static const String currentLanUrl = 'http://192.168.1.80:8080';

  // Override at build time:
  //   flutter run --dart-define=BASE_URL=http://192.168.x.x:8080
  static const String _explicitBaseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: '');

  // ── Stripe ────────────────────────────────────────────────────────────────
  // MUST match the Stripe account that owns the backend secret key.
  // Override at build time if needed with:
  // Supply at build time:
  //   --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51TBONNHWgarvtGrAJ8QCcdpYDDtvFN6NVDKBaNw23EPvHc4VrEIloJ8nKjGatY6nRgiQGMmrEeouDHCehnRrVumr00kA0Ng8mf',
  );

  // ── Google Sign-In ────────────────────────────────────────────────────────
  // Web OAuth client ID from Google Cloud Console.
  // Used as serverClientId so google_sign_in returns an idToken.
  // Supply at build time:
  //   --dart-define=GOOGLE_CLIENT_ID=980492524757-xxxx.apps.googleusercontent.com
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '980492524757-g1h19t4a2n30ut7vq6mi4uv6ooijt7sg.apps.googleusercontent.com',
  );

  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) return _explicitBaseUrl;
    if (kIsWeb) return defaultDesktopAndWebUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? currentLanUrl
        : defaultDesktopAndWebUrl;
  }

  static String backendHint() {
    if (kIsWeb) {
      return 'Web uses localhost by default. Current Wi-Fi LAN backend: $currentLanUrl.';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android emulator uses $defaultAndroidEmulatorUrl. Physical device on same Wi-Fi should use $currentLanUrl.';
    }
    return 'Desktop defaults to localhost. Current Wi-Fi LAN backend: $currentLanUrl.';
  }
}
