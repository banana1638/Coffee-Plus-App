<div align="center">

<!-- HERO BANNER -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=6F4E37,C8A96E&height=200&section=header&text=Coffee%20Plus%2B&fontSize=72&fontColor=FFFFFF&fontAlignY=38&desc=Your%20Premium%20Coffee%20Experience%2C%20Reimagined&descAlignY=60&descSize=18&animation=fadeIn" width="100%"/>

<!-- BADGES -->
<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Laravel-Backend-FF2D20?style=for-the-badge&logo=laravel&logoColor=white"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge&logo=apple&logoColor=white"/>
  <img src="https://img.shields.io/badge/Version-1.0.0-6F4E37?style=for-the-badge"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Real--time-WebSocket-brightgreen?style=flat-square&logo=socket.io"/>
  <img src="https://img.shields.io/badge/Auth-Biometric%20%2B%20JWT-blue?style=flat-square&logo=auth0"/>
  <img src="https://img.shields.io/badge/Theme-Dark%20%7C%20Light%20%7C%20System-purple?style=flat-square"/>
  <img src="https://img.shields.io/badge/Cache-TTL%20TimedCache-orange?style=flat-square"/>
</p>

<br/>

> **Coffee Plus+** is a full-featured loyalty coffee ordering app built with Flutter.  
> Order your favourite brew, earn OZ points, redeem rewards — all with biometric security.

<br/>

</div>

---

## 📸 Screenshots

<div align="center">
<table>
  <tr>
    <td align="center"><b>🏠 Home</b></td>
    <td align="center"><b>☕ Product Detail</b></td>
    <td align="center"><b>🛒 Cart</b></td>
    <td align="center"><b>🪣 Tangki OZ</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/home.png" width="180" alt="Home Screen"/></td>
    <td><img src="docs/screenshots/product.png" width="180" alt="Product Detail"/></td>
    <td><img src="docs/screenshots/cart.png" width="180" alt="Cart"/></td>
    <td><img src="docs/screenshots/tangki.png" width="180" alt="Tangki"/></td>
  </tr>
  <tr>
    <td align="center"><b>🎁 Points Mall</b></td>
    <td align="center"><b>🔔 Notifications</b></td>
    <td align="center"><b>👤 Profile</b></td>
    <td align="center"><b>🌙 Dark Mode</b></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/mall.png" width="180" alt="Points Mall"/></td>
    <td><img src="docs/screenshots/notifications.png" width="180" alt="Notifications"/></td>
    <td><img src="docs/screenshots/profile.png" width="180" alt="Profile"/></td>
    <td><img src="docs/screenshots/dark.png" width="180" alt="Dark Mode"/></td>
  </tr>
</table>
</div>

---

## ✨ Features

<table>
  <tr>
    <td width="50%">

### ☕ Ordering
- **Smart Menu** — Browse by category with instant search & debounce
- **Product Customiser** — Choose size, temperature, and add-ons
- **Favourites** — Save your go-to orders for one-tap reorder
- **Active Order Card** — Track your live order status from the Home screen

    </td>
    <td width="50%">

### 🪣 OZ Loyalty System
- **Tank Visualisation** — Animated OZ level indicator
- **Earn on Every Order** — OZ points awarded automatically
- **Redeem at Checkout** — Use OZ instead of cash for any item
- **Points Mall** — Exchange OZ for free drinks, discounts & badges

    </td>
  </tr>
  <tr>
    <td>

### 🛒 Cart & Checkout
- **Mixed Payment** — Combine OZ redemption + cash in one order
- **Coupon System** — Apply discount codes at checkout
- **Biometric Auth** — Fingerprint / Face ID confirms every purchase
- **Animated Total** — Smooth price transitions as cart updates

    </td>
    <td>

### 🔔 Real-time Notifications
- **Laravel Reverb** — WebSocket-powered live order updates
- **Push Notifications** — Local alerts even when app is in background
- **Exponential Backoff** — Smart reconnection with jitter on disconnect
- **Channel Auth** — Private per-user channels via JWT bearer token

    </td>
  </tr>
  <tr>
    <td>

### 👤 Account & Profile
- **Secure Auth** — JWT login / register with Remember Me
- **Biometric Login** — Unlock with Face ID or fingerprint
- **Profile Editor** — Update name, email, password
- **Theme Switcher** — Light, Dark, and System-default modes
- **Account Deletion** — Password-confirmed permanent deletion

    </td>
    <td>

### ⚡ Performance & UX
- **TimedCache** — TTL-based in-memory cache (no redundant API calls)
- **Shimmer Loading** — Skeleton screens while data loads
- **RepaintBoundary** — Isolates expensive widget repaints
- **`Future.wait`** — Parallel API calls where possible
- **CancelToken** — Cancels in-flight requests on navigation

    </td>
  </tr>
</table>

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
│                                                                 │
│  ┌─────────────┐   ┌─────────────────────────────────────────┐  │
│  │   Screens   │   │            State Layer                  │  │
│  │  ─────────  │   │  ValueNotifier  │  TimedCache           │  │
│  │  Home       │   │  authState      │  dashboard (2 min)    │  │
│  │  Cart       │   │  cartCount      │  notifications (1 min)│  │
│  │  Tangki     │   │  notifCount     │  profiles (5 min)     │  │
│  │  Profile    │   │  themeMode      │                       │  │
│  │  Mall       │   └─────────────────────────────────────────┘  │
│  └──────┬──────┘                    │                           │
│         │                           │                           │
│  ┌──────▼──────────────────────────▼──────────────────────────┐ │
│  │                     ApiService (Facade)                     │ │
│  │   login() │ fetchDashboard() │ validateCoupon() │ logout()  │ │
│  └──────┬────────────────────────────────────────────────────-┘ │
│         │                                                        │
│  ┌──────▼────────────────────────────────────────────────────┐  │
│  │                  Sub-Services (SRP)                        │  │
│  │  AuthService │ CartService │ CouponService │ OrderService  │  │
│  │  ProfileService │ FavoriteService │ NotificationService    │  │
│  └──────┬────────────────────────────────────────────────────┘  │
│         │                                                        │
│  ┌──────▼────────────────────────────────────────────────────┐  │
│  │   ApiClient (implements ApiClientContract)                 │  │
│  │   Dio + Interceptors + FlutterSecureStorage + TimedCache   │  │
│  └──────┬───────────────────────┬────────────────────────────┘  │
│         │                       │                               │
└─────────┼───────────────────────┼───────────────────────────────┘
          │ REST (HTTP/HTTPS)      │ WebSocket (Reverb)
          ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Laravel Backend                            │
│   API Routes │ Sanctum Auth │ Broadcasting │ MySQL Database     │
└─────────────────────────────────────────────────────────────────┘
```

**Key Design Patterns Used:**

| Pattern | Where | Why |
|---|---|---|
| **Facade** | `ApiService` | Single entry point for all UI ↔ API interactions |
| **Singleton** | `ApiClient`, `ApiService` | Shared state (auth token, notifiers) across the app |
| **Dependency Inversion** | `ApiClientContract` | Decouples services from implementation — enables mock testing |
| **Strategy** | `BiometricService` | Platform-specific auth (Android / iOS) behind a common interface |
| **Observer** | `ValueNotifier` | Reactive UI updates without a heavy state management framework |

---

## 📦 Tech Stack

### Frontend

| Package | Version | Purpose |
|---|---|---|
| `flutter` | 3.x | UI framework |
| `dio` | ^5.4.0 | HTTP client with interceptors |
| `flutter_secure_storage` | ^9.0.0 | Encrypted token storage (Keychain / Keystore) |
| `local_auth` | ^2.3.0 | Fingerprint / Face ID authentication |
| `flutter_local_notifications` | ^17.2.3 | Background push notifications |
| `pusher_reverb_flutter` | ^0.0.4 | WebSocket real-time events (Laravel Reverb) |
| `cached_network_image` | ^3.3.0 | Image caching with placeholder support |
| `shared_preferences` | ^2.5.4 | Theme persistence |
| `intl` | ^0.20.2 | Date/currency formatting |

### Backend

| Technology | Purpose |
|---|---|
| **Laravel 11** | REST API + Authentication (Sanctum) |
| **Laravel Reverb** | WebSocket server for real-time events |
| **MySQL** | Primary database |
| **Laravel Broadcasting** | Private channel event broadcasting |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.1`
- Dart SDK `^3.11.1`
- Android Studio / Xcode
- A running [Laravel backend](#) with Reverb configured

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/banana1638/Coffee-Plus-App.git
cd Coffee-Plus-App

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run
```

### Environment Configuration

The app reads its API endpoint from compile-time environment variables. Set them at build time — **never hardcode production URLs in source code**.

```bash
# Development
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.x/coffee_plus/public/api \
  --dart-define=REVERB_HOST=192.168.1.x \
  --dart-define=REVERB_KEY=your_app_key

# Production build (use your real domain + HTTPS)
flutter build apk \
  --dart-define=API_BASE_URL=https://your-domain.com/api \
  --dart-define=REVERB_HOST=your-domain.com \
  --dart-define=REVERB_KEY=your_production_key
```

> 💡 **Tip:** Store these values in a `.env.local` file and add it to `.gitignore` to keep credentials out of version control.

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── app_colors.dart        # Theme colour tokens (light + dark)
│   ├── app_theme.dart         # MaterialApp theme configuration
│   ├── app_logger.dart        # 🆕 Production-safe logging utility
│   ├── app_routes.dart        # 🆕 Centralised route name constants
│   ├── timed_cache.dart       # 🆕 TTL-based in-memory cache
│   ├── validators.dart        # 🆕 Email, password, name validators
│   └── error_handler.dart     # 🆕 User-friendly error messages
│
├── models/
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── cart_item_model.dart
│   ├── category_model.dart
│   ├── favorite_model.dart
│   └── transaction_model.dart
│
├── services/
│   ├── api_client.dart        # Dio + interceptors + TimedCache
│   ├── api_service.dart       # Facade — single public API surface
│   ├── auth_service.dart      # Login / Register / Logout / Token
│   ├── biometric_service.dart # Face ID / Fingerprint authentication
│   ├── cart_service.dart      # Cart CRUD + checkout
│   ├── coupon_service.dart    # Coupon validation
│   ├── favorite_service.dart  # Favourites management
│   ├── notification_service.dart # Reverb WebSocket + local notifications
│   ├── notification_utils.dart
│   ├── order_service.dart     # Order history + detail + cancel
│   └── profile_service.dart   # Profile / password / Tangki / delete account
│
├── screens/
│   ├── home_screen.dart       # Menu + search + active order
│   ├── main_wrapper.dart      # Bottom nav shell
│   └── user/
│       ├── cart_index_screen.dart
│       ├── notification_screen.dart
│       ├── order_detail_screen.dart
│       ├── order_history_screen.dart
│       ├── points_mall_screen.dart
│       ├── product_detail_screen.dart
│       ├── profile_screen.dart
│       ├── tangki_screen.dart
│       └── transaction_history_screen.dart
│
├── widgets/
│   ├── active_order_card.dart
│   ├── auth_modal.dart        # Login / Register bottom sheet
│   ├── coffee_card.dart
│   ├── coffee_loading_overlay.dart
│   ├── shimmer_loading.dart
│   └── tank_visualization.dart # Animated OZ tank widget
│
└── main.dart
```

---

## 🔒 Security

| Area | Implementation |
|---|---|
| **Token Storage** | `flutter_secure_storage` — AES-encrypted on Android (Keystore), Keychain on iOS |
| **Checkout Auth** | Biometric (fingerprint / Face ID) required before every payment |
| **API Auth** | JWT Bearer token injected via Dio interceptor |
| **Session Expiry** | 401 interceptor automatically clears auth state |
| **Input Validation** | Email format, password strength (≥8 chars, uppercase, number) enforced client-side |
| **Logging** | `AppLogger` — sensitive details suppressed in release builds |
| **Cache TTL** | Dashboard: 2 min · Notifications: 1 min · Profiles: 5 min |

> ⚠️ **Production Checklist**
> - [ ] Enable HTTPS — replace all `http://` URLs
> - [ ] Move API keys to `--dart-define` or a secrets manager
> - [ ] Set `useTLS: true` on Laravel Reverb connection
> - [ ] Add server-side rate limiting on `/login` endpoint

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Test files are located in `test/`:
- `models_test.dart` — Unit tests for data model parsing
- `notification_utils_test.dart` — Unit tests for notification filtering logic
- `widget_test.dart` — Widget smoke tests

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

```bash
# 1. Fork the repository and create your branch
git checkout -b feature/your-feature-name

# 2. Commit your changes (follow Conventional Commits)
git commit -m "feat: add OZ transaction export"

# 3. Push and open a Pull Request
git push origin feature/your-feature-name
```

**Code Style:** This project uses `flutter_lints` with additional rules defined in `analysis_options.yaml`. Run `flutter analyze` before submitting a PR.

---

## 📄 License

```
MIT License — Copyright (c) 2025 Coffee Plus+

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files, to deal in the Software
without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software.
```

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=6F4E37,C8A96E&height=120&section=footer&animation=fadeIn" width="100%"/>

**Built with ☕ and Flutter**

*If this project helped you, consider giving it a ⭐*

</div>