# AI App Context Index

This file exists to save tokens.

## Important Files

| File | Responsibility | When to Read |
|---|---|---|
| lib/main.dart | App startup, routes, deferred notification init | Initialization/env/router |
| pubspec.yaml | Dependencies, Dart SDK constraint | Package changes |
| lib/services/app_config.dart | dart-define environment config | Base URLs, media origins, Reverb config |
| lib/services/api_client.dart | Dio setup, token storage, auth header injection, image URL resolution, cache/notifiers | API auth, token, media URL, 401 handling |
| lib/services/api_response.dart | Typed JSON object validation and `data` response unwrapping | Service response parsing |
| lib/services/api_service.dart | Facade over app services, dashboard, notifications, favorites | Cross-feature API behavior |
| lib/services/timed_cache.dart | Generic bounded TTL cache | Cache memory and request reuse |
| lib/services/auth_service.dart | Login/register/logout/profile validation | Auth changes |
| lib/services/device_name_provider.dart | Stable bounded device label for issued API tokens | Login/register device metadata |
| lib/services/token_service.dart | List and revoke owned API tokens | Device session management |
| lib/services/cart_service.dart | Cart and checkout API calls | Cart/checkout changes |
| lib/services/coupon_service.dart | Coupon validation API | Coupon UI/API changes |
| lib/services/product_service.dart | Full product detail and add-ons API parsing | Product detail options/add-ons |
| lib/services/order_service.dart | Order list/detail/cancel API calls | Order changes |
| lib/services/profile_service.dart | Profile, Tangki, refill, transactions, account actions | Wallet/profile changes |
| lib/services/notification_service.dart | Local notifications and Reverb private-channel subscription | Realtime/broadcasting changes |
| lib/models/ | JSON models | Response parsing |
| lib/models/device_token_model.dart | Safe device-token metadata model without token secrets | Device session UI |
| lib/screens/home_screen.dart | Product browsing home/dashboard | Product browse UI |
| lib/screens/user/product_detail_screen.dart | Product detail/add-to-cart | Product detail UI |
| lib/screens/user/cart_index_screen.dart | Cart, coupon, checkout | Checkout/cart UI |
| lib/screens/user/order_history_screen.dart | Order history | Order list UI |
| lib/screens/user/order_detail_screen.dart | Order detail/cancel | Order status UI |
| lib/screens/user/tangki_screen.dart | Wallet/Tangki balance/refill | Wallet UI |
| lib/screens/user/transaction_history_screen.dart | Wallet transaction history | Transaction UI |
| lib/screens/user/profile_screen.dart | Profile/account settings | Auth/profile UI |
| lib/widgets/ | Shared widgets | UI reuse |
| lib/core/app_theme.dart | Material theme | Theme changes |
| lib/core/app_colors.dart | Color tokens | Design token changes |
| lib/core/app_motion.dart | Shared animation durations and curves | Motion/animation changes |
| lib/core/app_typography.dart | Serif title, monospace ledger, and money text roles | UI typography changes |
| lib/widgets/cafe_components.dart | Shared 8px cafe surfaces, section headers, money/ledger text, receipt/ticket dividers | UI refactor/shared component changes |
| android/app/build.gradle.kts | Android build/signing/cleartext config | Build/signing issues |

## Common App Debug Paths

| Symptom | Inspect First |
|---|---|
| Missing API base URL | lib/services/app_config.dart, dart-define keys |
| API 401 | lib/services/api_client.dart, lib/services/auth_service.dart |
| API 404 | endpoint path, AppConfig.apiBaseUrl |
| API 422 | request body fields in service file |
| JSON parse error | model classes, response assumptions |
| Product image missing | ApiClient.getFullImageUrl, public/storage origins |
| Wallet UI wrong | lib/services/profile_service.dart, lib/screens/user/tangki_screen.dart |
| Checkout fail | lib/services/cart_service.dart, lib/screens/user/cart_index_screen.dart |
| Coupon fail | lib/services/coupon_service.dart, cart screen subtotal assumptions |
| Reverb fail | lib/services/notification_service.dart, lib/services/app_config.dart |
| Android build fail | android/app/build.gradle.kts, android/build.gradle.kts, Gradle wrapper |
