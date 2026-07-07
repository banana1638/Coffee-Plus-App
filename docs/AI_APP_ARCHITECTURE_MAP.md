# AI App Architecture Map

## Top-Level App Files

| File/Path | Responsibility | Notes |
|---|---|---|
| lib/main.dart | Flutter startup | App entry, MaterialApp routes, theme mode notifier |
| lib/services/ | API clients and app services | Dio API client, auth, cart, coupon, order, profile, notifications, Reverb |
| lib/models/ | Data models | Product, cart item, user, category, favorite, transaction |
| lib/screens/ | Screens | Home and user flows |
| lib/widgets/ | Shared widgets | Cards, auth modal, loading, tank visualization, active order card |
| lib/core/ | Theme/design system and utilities | App colors, Material theme, validators, error handler |
| pubspec.yaml | Dependencies | Dart SDK ^3.11.1, dio, secure storage, Reverb, notifications |
| android/ | Android project | Kotlin Gradle, app id com.coffeeplus.app, release signing guard |
| ios/ | iOS project | Standard Flutter iOS runner config |

## App Modules

| Module | Files | API Dependency | Risk |
|---|---|---|---|
| Auth | lib/services/auth_service.dart, lib/services/api_client.dart, lib/widgets/auth_modal.dart, lib/screens/user/profile_screen.dart | /login, /register, /logout, /profile | High |
| Device Sessions | lib/services/device_name_provider.dart, lib/services/token_service.dart, lib/models/device_token_model.dart, lib/screens/user/profile_screen.dart | /tokens, /tokens/{tokenId} | High |
| Products | lib/screens/home_screen.dart, lib/screens/user/product_detail_screen.dart, lib/models/product_model.dart, lib/models/category_model.dart, lib/services/api_service.dart, lib/services/product_service.dart | /dashboard, /products/{id} | Medium |
| Cart | lib/services/cart_service.dart, lib/screens/user/cart_index_screen.dart, lib/models/cart_item_model.dart | /cart, /cart/add, /cart/update, /cart/remove, /checkout | Medium |
| Orders | lib/services/order_service.dart, lib/screens/user/order_history_screen.dart, lib/screens/user/order_detail_screen.dart, lib/widgets/active_order_card.dart | /orders, /orders/{id}, /orders/{id}/cancel | High |
| Wallet/Tangki | lib/services/profile_service.dart, lib/screens/user/tangki_screen.dart, lib/screens/user/transaction_history_screen.dart, lib/widgets/tank_visualization.dart, lib/models/transaction_model.dart | /tangki, /tangki/refill, /transactions | High |
| Coupons | lib/services/coupon_service.dart, lib/screens/user/cart_index_screen.dart | /coupons/validate | High |
| Reverb/Broadcasting | lib/services/notification_service.dart, lib/services/app_config.dart | Reverb private user channel and configured auth endpoint | Medium |
| Env Config | lib/services/app_config.dart, .env.example.json, .env.local.example.json, .env.production.example.json | Base URL, public/storage origins, Reverb config | High |
| UI Theme | lib/core/app_theme.dart, lib/core/app_colors.dart, lib/widgets/ | None/direct | Medium |

## Validation Commands

Use detected commands only.

Detected commands:

flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=.env.local.json
