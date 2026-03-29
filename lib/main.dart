import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final stripeKey = AppConfig.stripePublishableKey;
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    Stripe.merchantIdentifier = 'merchant.com.rihla';
    await Stripe.instance.applySettings();
    // ignore: avoid_print
    print('✅ Stripe initialized with key: ${stripeKey.substring(0, 20)}...');

    // IMPORTANT: Verify key account matches backend.
    // If accounts don't match, Stripe will return "No such payment_intent".
    // Current frontend account prefix: pk_test_51TBONNHWgarvtGr...
    // Backend secret key must be from the same Stripe account.
  } else {
    // ignore: avoid_print
    print(
      '⚠️  STRIPE_PUBLISHABLE_KEY not configured.\n'
      '   Run with: --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_51TBONNHWgarvtGr...\n'
      '   IMPORTANT: The publishable key must match the backend secret key account.\n'
      '   Backend secret key must start with: sk_test_51TBONNHWgarvtGr...',
    );
  }

  runApp(const ProviderScope(child: RihlaApp()));
}

class RihlaApp extends ConsumerWidget {
  const RihlaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'RIHLA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
