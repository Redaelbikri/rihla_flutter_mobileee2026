import 'package:flutter/foundation.dart';

class AppConfig {
  // For Android emulator pointing to backend on the same PC
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8080';
  // For physical device or desktop — backend runs on same laptop
  static const String defaultDesktopAndWebUrl = 'http://127.0.0.1:8080';

  // Override at build time:
  //   flutter run --dart-define=BASE_URL=http://192.168.x.x:8080
  static const String _explicitBaseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: '');

  // IMPORTANT: This publishable key must match the same Stripe account
  // as the backend's STRIPE_SECRET_KEY (sk_test_51TAYJD2EPDYBF...).
  // Get your publishable key from https://dashboard.stripe.com/apikeys
  // and override at build time:
  //   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51Sxr5ZPOyuSYqxOrhp26ytuiaon4J4CO83yFw2blbOaiLPXA3Sl4K8fHFxF2q19w0rapg6o3F1IfIRA6g7cDTypN003iI8PXX9',
  );

  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) return _explicitBaseUrl;
    if (kIsWeb) return defaultDesktopAndWebUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? defaultAndroidEmulatorUrl
        : defaultDesktopAndWebUrl;
  }

  static String backendHint() {
    if (kIsWeb) {
      return 'Web uses localhost. Override with --dart-define=BASE_URL=http://YOUR_LAN_IP:8080.';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android emulator uses 10.0.2.2. Physical device on same Wi-Fi: --dart-define=BASE_URL=http://YOUR_LAN_IP:8080.';
    }
    return 'Desktop defaults to localhost. Override with --dart-define=BASE_URL=http://YOUR_LAN_IP:8080.';
  }
}
