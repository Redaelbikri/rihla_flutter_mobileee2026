# Backend → Frontend Mapping

## Auth
- `POST /api/auth/signup` → `lib/features/auth/register_page.dart`
- `POST /api/auth/verify-email` → `lib/features/auth/auth_otp_page.dart`
- `POST /api/auth/login` → `lib/features/auth/login_page.dart`
- `POST /api/auth/verify-login` → `lib/features/auth/auth_otp_page.dart`
- `POST /api/auth/forgot-password` → `lib/features/auth/forgot_password_page.dart`
- `POST /api/auth/reset-password` → `lib/features/auth/forgot_password_page.dart`
- `POST /api/auth/google` → `lib/features/auth/login_page.dart`, `register_page.dart`

## User/Profile
- `GET /api/users/me` → `lib/features/profile/profile_page.dart`
- `PUT /api/users/me` → `lib/features/profile/profile_page.dart`

## Events
- `GET /api/events` → `home_page.dart`, `explore_page.dart`
- `GET /api/events/search` → `explore_page.dart`
- `GET /api/events/filter/city` → reusable in `events_service.dart`
- `GET /api/events/filter/category` → reusable in `events_service.dart`
- `GET /api/events/{id}` → `event_details_page.dart`
- `GET /api/events/{id}/details` → `event_details_page.dart`
- `GET /api/events/{id}/availability` → `book_event_page.dart`

## Hebergements
- `GET /api/hebergements` → `home_page.dart`, `explore_page.dart`
- `GET /api/hebergements/filter/type/{type}` → `explore_page.dart`
- `GET /api/hebergements/{id}` → `hebergement_details_page.dart`
- `GET /api/hebergements/{id}/rating-stats` → `hebergement_details_page.dart`
- `GET /api/hebergements/{id}/check` → `book_hotel_page.dart`

## Transports
- `GET /api/transports/trips/search` → `transport_search_sheet.dart`, `transport_results_page.dart`
- `GET /api/transports/trips/{id}` → `trip_details_page.dart`
- `GET /api/transports/trips/{id}/rating-stats` → `trip_details_page.dart`
- `GET /api/transports/trips/{id}/check` → `book_transport_page.dart`

## Reservations
- `POST /api/reservations` → `book_event_page.dart`, `book_hotel_page.dart`, `book_transport_page.dart`
- `GET /api/reservations/me` → `bookings_page.dart`
- `PUT /api/reservations/{id}/cancel` → `bookings_page.dart`

## Payments
- `POST /api/payments/create-intent` → `payments_service.dart`
- `GET /api/payments/me` → `payment_history_page.dart`

## Notifications
- `GET /api/notifications/me` → `notifications_page.dart`
- `GET /api/notifications/me/unread-count` → `notifications_service.dart`
- `PUT /api/notifications/{id}/read` → `notifications_page.dart`

## Reviews
- `GET /api/reviews/{type}/{id}` → details pages
- `GET /api/reviews/{type}/{id}/stats` → details pages
- `POST /api/reviews` → `review_create_page.dart`

## Assistant
- `POST /api/assistant/chat` → `assistant_chat_page.dart`

## Itineraries
- `POST /api/itineraries/generate` → `itinerary_planner_page.dart`
- `GET /api/itineraries/me` → `itinerary_history_page.dart`

## Recommendations
- `GET /api/recommendations` → `recommendations_page.dart`
