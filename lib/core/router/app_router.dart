import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_otp_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../features/assistant/assistant_chat_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/bookings/book_event_page.dart';
import '../../features/bookings/book_hotel_page.dart';
import '../../features/bookings/book_transport_page.dart';
import '../../features/events/event_details_page.dart';
import '../../features/hebergements/hebergement_details_page.dart';
import '../../features/itineraries/itinerary_history_page.dart';
import '../../features/itineraries/itinerary_planner_page.dart';
import '../../features/itineraries/itinerary_result_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/reservations/bookings_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/payments/payment_history_page.dart';
import '../../features/recommendations/recommendations_page.dart';
import '../../features/reviews/review_create_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/splash/splash_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/transports/transport_results_page.dart';
import '../../features/transports/trip_details_page.dart';
import '../di/providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: '/auth/login',
        builder: (_, s) => LoginPage(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, s) => RegisterPage(from: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, s) => AuthOtpPage(
          email: s.uri.queryParameters['email'] ?? '',
          flow: s.uri.queryParameters['flow'] ?? 'login',
          from: s.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/app',
        builder: (_, s) {
          final tab = int.tryParse(s.uri.queryParameters['tab'] ?? '0') ?? 0;
          return AppShell(initialIndex: tab);
        },
      ),
      GoRoute(
          path: '/event/:id',
          builder: (_, s) => EventDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/trip/:id',
          builder: (_, s) => TripDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/stay/:id',
          builder: (_, s) =>
              HebergementDetailsPage(id: s.pathParameters['id']!)),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(
          path: '/assistant', builder: (_, __) => const AssistantChatPage()),
      GoRoute(
        path: '/review/new',
        builder: (_, s) =>
            ReviewCreatePage(extra: (s.extra as Map<String, dynamic>?) ?? {}),
      ),
      GoRoute(
        path: '/transport/results',
        builder: (_, s) {
          final qp = s.uri.queryParameters;
          return TransportResultsPage(
            fromCity: qp['fromCity'] ?? '',
            toCity: qp['toCity'] ?? '',
            date: qp['date'] ?? '',
            type: qp['type'],
          );
        },
      ),
      GoRoute(
          path: '/payments', builder: (_, __) => const PaymentHistoryPage()),
      GoRoute(
          path: '/recommendations', builder: (_, __) => const RecommendationsPage()),
      GoRoute(
          path: '/itineraries',
          builder: (_, __) => const ItineraryHistoryPage()),
      GoRoute(
          path: '/itinerary/planner',
          builder: (_, __) => const ItineraryPlannerPage()),
      GoRoute(
        path: '/itinerary/result',
        builder: (_, s) => ItineraryResultPage(
          data: (s.extra as Map<String, dynamic>?) ?? const <String, dynamic>{},
        ),
      ),
      GoRoute(
        path: '/book/event/:id',
        builder: (_, s) => BookEventPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/hotel/:id',
        builder: (_, s) => BookHotelPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/transport/:id',
        builder: (_, s) => BookTransportPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bookings',
        builder: (_, __) => Scaffold(
          appBar: AppBar(
            title: const Text('My Trips'),
            backgroundColor: const Color(0xFF0C6171),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          backgroundColor: const Color(0xFFF5F7FA),
          body: const BookingsPage(),
        ),
      ),
    ],
    redirect: (context, state) {
      final loc = state.uri.path;
      final fullLoc = state.uri.toString();
      final authed = session.isAuthenticated;
      final initialized = session.initialized;

      final isAuth = loc.startsWith('/auth');
      final isSplash = loc == '/splash';
      final isOnboarding = loc == '/onboarding';

      final isPublicDetail = [
        '/event/',
        '/stay/',
        '/trip/',
      ].any((p) => loc.startsWith(p));

      if (!initialized) return isSplash ? null : '/splash';

      if (!authed) {
        if (isAuth || isSplash || isOnboarding || isPublicDetail) return null;
        final from = Uri.encodeComponent(fullLoc);
        return '/auth/login?from=$from';
      }

      if (authed && (isAuth || isSplash || isOnboarding)) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }
        return '/app';
      }

      return null;
    },
  );
});
