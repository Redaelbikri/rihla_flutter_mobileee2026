# RIHLA Mobile

Flutter mobile frontend aligned with the provided Spring Boot microservices backend.

## Run

```bash
flutter pub get
flutter run \
  --dart-define=BASE_URL=http://10.0.2.2:8080 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

Use your real API Gateway URL in `BASE_URL`.

## Backend features covered

- Auth: signup, OTP email verification, login + OTP, forgot/reset password, Google auth
- Profile: get/update my profile
- Events: list, search, city/category filter, details, availability
- Hebergements: list, filter, details, rating stats, availability
- Transports: search, details, rating stats, availability
- Reservations: create event/hotel/transport booking, list my reservations, cancel
- Payments: create Stripe intent, payment sheet, payment history
- Notifications: list, unread count, mark as read
- Reviews: list, stats, create
- AI assistant: chat
- Itineraries: generate + history
- Recommendations: list personalized travel recommendations

## Important notes

Google Sign-In needs native Android/iOS configuration.
Stripe payment needs a valid publishable key and supported device setup.
