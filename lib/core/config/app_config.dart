class AppConfig {
  static const String baseUrl =
      String.fromEnvironment('BASE_URL', defaultValue: 'http://172.20.10.2:8080');

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        '',
  );
}
