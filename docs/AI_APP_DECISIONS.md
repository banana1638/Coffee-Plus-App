# AI App Decisions

Record meaningful app decisions only.

### 2026-07-07 - Mobile Cafe Object UI System

Context:
- The app needs a UI refactor based on a cafe ordering design prompt rather than a generic card-heavy mobile layout.
- The app must preserve backend authority for product prices, checkout totals, wallet balance, and payment status.

Decision:
- Build the UI around reusable app-level typography and cafe surface components before touching individual screens.
- Use serif text for titles and recipe-like headers, monospace text with tabular figures for money/order/ledger values, and default Material text for body copy.
- Keep brand green for actions and active states, caramel accent for money, and warning/error/success as separate semantic states.
- Reserve the perforated visual only for order detail pickup tickets.

Reason:
- Shared primitives reduce repeated hand-styled containers and make future UI passes easier to keep consistent.
- Keeping money and payment confirmation visually conservative supports the app/backend trust boundary.

Trade-offs:
- Pros:
  - More consistent dark/light UI.
  - Lower chance of future screens mixing money color and action color.
  - Cleaner path for continuing the refactor screen by screen.
- Cons:
  - First pass touches several visible screens but still leaves secondary screens for later detailed polish.

Affected files:
- lib/core/app_typography.dart
- lib/widgets/cafe_components.dart
- lib/core/app_theme.dart
- lib/widgets/coffee_card.dart
- lib/screens/home_screen.dart
- lib/screens/user/product_detail_screen.dart
- lib/screens/user/cart_index_screen.dart
- lib/screens/user/order_detail_screen.dart
- lib/screens/user/tangki_screen.dart
- lib/widgets/auth_modal.dart
- docs/AI_APP_UI_GUIDELINES.md

Validation:
- `git diff --check` passed. Flutter/Dart tool validation timed out in the agent shell and needs manual rerun.

## Template

### YYYY-MM-DD - Decision Title

Context:
- TODO

Decision:
- TODO

Reason:
- TODO

Trade-offs:
- Pros:
  - TODO
- Cons:
  - TODO

Affected files:
- TODO

Validation:
- TODO

### 2026-07-07 - Transaction Lists Use Summary Payloads

Context:
- The backend now keeps `GET /api/tangki`, `GET /api/transactions`, and `GET /api/refunds` lightweight by omitting embedded order details.
- Full order detail remains available from `GET /api/transactions/{bill_id}`.

Decision:
- Treat `order_details` as optional in transaction summary models.
- Render transaction and Tangki rows from summary fields only.
- Fetch full order detail on tap by `bill_id`, then pass the returned `order` object to `OrderDetailScreen`.
- Cache fetched transaction details for the app session.

Reason:
- Keeps list screens aligned with the backend performance optimization and avoids retaining large order item payloads unnecessarily.

Trade-offs:
- Pros:
  - Smaller list payloads and lower memory pressure.
  - Detail screen still receives full authoritative backend order data.
- Cons:
  - Opening a detail can require one additional request on first access.

Affected files:
- lib/models/transaction_model.dart
- lib/services/profile_service.dart
- lib/services/api_service.dart
- lib/screens/user/transaction_history_screen.dart
- lib/screens/user/tangki_screen.dart
- test/models_test.dart
- docs/AI_API_CONSUMER_CONTRACT.md

Validation:
- Backend route/controller/resource contract inspected; Flutter validation pending.

### 2026-07-07 - Laravel UI Tokens as Flutter Theme Source

Context:
- The Laravel Coffee-Plus UI defines the product look through CSS variables in `resources/css/app.css` and Tailwind utility composition in Blade components.
- The Flutter app previously used a purple/blue visual direction that did not match the Laravel web UI.

Decision:
- Use the Laravel `cp-*` visual language as Flutter's app theme baseline.
- Keep Flutter-specific dark-mode equivalents because the Laravel web CSS currently defines a light color scheme only.
- Start with shared tokens, Material theme, Home browsing, product cards, mobile navigation, and product detail controls before deeper per-screen polishing.

Reason:
- Shared tokens provide the widest visual alignment with the smallest behavioral risk.
- Mobile flows should preserve native bottom navigation and modal product detail instead of copying desktop layout mechanics directly.

Trade-offs:
- Pros:
  - Large visual shift with limited API and business-logic risk.
  - Dark mode remains supported.
  - Future screens can reuse the same Coffee Plus design tokens.
- Cons:
  - Some secondary screens still need a second pass to remove old hardcoded colors and match Laravel card/table patterns precisely.

Affected files:
- lib/core/app_colors.dart
- lib/core/app_theme.dart
- lib/screens/home_screen.dart
- lib/widgets/coffee_card.dart
- lib/screens/main_wrapper.dart
- lib/screens/user/product_detail_screen.dart
- lib/screens/user/order_detail_screen.dart
- lib/screens/user/order_history_screen.dart
- lib/screens/user/tangki_screen.dart
- lib/screens/user/transaction_history_screen.dart
- lib/screens/user/points_mall_screen.dart
- lib/models/product_model.dart

Validation:
- Static diff review and `git diff --check` passed; Flutter analyzer/test timed out in the agent shell and require manual rerun.

### 2026-06-14 - App-Only Codex Memory Boundary

Context:
- Coffee-Plus-App is the Flutter mobile API consumer for the Coffee Plus system.
- Coffee-Plus backend is a separate Laravel repository.

Decision:
- Create only app-side memory, contracts, and skills in this repository.
- Document backend expectations without creating backend ownership or Laravel backend skills here.

Reason:
- Prevent app tasks from modifying backend truth for money, payment, wallet, ownership, roles, or permissions.

Trade-offs:
- Pros:
  - Clear repository boundary.
  - Safer API-consumer review workflow.
  - Lower risk of mixing client UI behavior with backend authority.
- Cons:
  - Backend contract verification still requires opening the separate Coffee-Plus repository.

Affected files:
- AGENTS.md
- docs/AI_APP_*.md
- docs/AI_API_CONSUMER_CONTRACT.md
- .codex/skills/app-*/SKILL.md
- .codex/skills/flutter-client-architect/SKILL.md

Validation:
- Documentation-only change; Flutter validation attempted separately.

### 2026-06-28 - Device Token Responsibilities

Context:
- The backend exposes owned device-token metadata and revocation endpoints.

Decision:
- Keep device-name generation, token API access, and Profile presentation in separate classes.
- Treat `revoked_current` from the backend as authoritative and clear local credentials after current/all-device revocation.

Reason:
- Keeps token secrets and lifecycle handling out of widgets while preserving the backend as authorization authority.

Trade-offs:
- Pros:
  - Testable device metadata normalization.
  - Centralized credential cleanup.
- Cons:
  - Platform host names may be generic, so the fallback label identifies the platform rather than a unique physical device.

Affected files:
- lib/services/device_name_provider.dart
- lib/services/token_service.dart
- lib/models/device_token_model.dart
- lib/screens/user/profile_screen.dart

Validation:
- Backend controller and feature tests inspected; Flutter validation pending.

### 2026-06-29 - Lazy Tabs and Scoped Reactive State

Context:
- `IndexedStack` mounted every main tab at startup, triggering hidden-screen data loads.
- Every product card observed the full favorites list.
- Reverb reconnect delays could survive intentional disconnects.

Decision:
- Lazily create each authenticated main tab and retain it after first access.
- Use cancelable reconnect timers guarded by authentication and explicit connection intent.
- Expose per-product favorite listenables while retaining the full list for customization-level favorite logic.
- Tie loading overlay lifetime directly to the request future.

Reason:
- Reduces startup network work, retained widget state, background wakeups, unnecessary rebuilds, and artificial loading time without changing API contracts.

Trade-offs:
- Pros:
  - Lower startup cost and background activity.
  - Existing tab state remains available after first access.
- Cons:
  - First access to a tab performs its initial load at that time.
  - FavoriteService retains one lightweight boolean notifier per product displayed.

Affected files:
- lib/screens/main_wrapper.dart
- lib/services/notification_service.dart
- lib/widgets/coffee_loading_overlay.dart
- lib/services/favorite_service.dart
- lib/widgets/coffee_card.dart

Validation:
- Static control-flow review complete; Flutter analyzer, tests, and device lifecycle checks pending.

### 2026-07-03 - Fetch Full Product Data on Detail Open

Context:
- Dashboard products are intentionally lightweight and currently omit add-ons.
- The Laravel product detail endpoint exists but Flutter did not consume it.

Decision:
- Fetch `GET /products/{id}` through a dedicated `ProductService` when the detail sheet opens.
- Keep the Dashboard product as fallback until the detail response explicitly contains an `addons` array.

Reason:
- Keeps the Dashboard response small while allowing product-specific add-ons to load only when needed.
- Distinguishes a valid empty add-ons array from an omitted backend field.

Trade-offs:
- Pros:
  - No Dashboard payload expansion.
  - Retryable failure state without blocking the existing product view.
- Cons:
  - Opening product detail performs one additional request.

Affected files:
- lib/services/product_service.dart
- lib/services/api_service.dart
- lib/screens/user/product_detail_screen.dart

Validation:
- Consumer parsing tests added; Flutter analyzer and full tests pending.

### 2026-07-03 - Upgrade Platform Packages in One Compatibility Baseline

Context:
- Several security- and platform-facing packages were on older major versions.
- The current Flutter 3.44.4 and Android toolchain support their latest resolvable releases.

Decision:
- Upgrade the platform packages together and migrate only their required call sites.
- Keep API contracts, storage keys, authentication behavior, and UI flows unchanged.
- Pin local-auth platform packages to explicit compatible constraints instead of `any`.
- Retain pusher_reverb_flutter 0.0.4 until a release offers cancelable or safely handled internal reconnects.
- Make Reverb opt-in through environment configuration so deployments without a realtime server do not create background connection work.
- Override path_provider_android to 2.2.22 until its newer registration mechanism works with the app's Android build configuration.

Reason:
- A single validated dependency baseline avoids mixing old platform interfaces with new transitive implementations.
- Explicit constraints make dependency resolution reproducible.

Trade-offs:
- Pros:
  - Current plugin fixes and platform support.
  - Reproducible local-auth dependency resolution.
- Cons:
  - Native notification, secure-storage, biometric, and Reverb workflows still need manual device checks.
  - Built-in Kotlin migration remains pending for a future Flutter release.
  - Reverb remains below its latest published version because 0.0.8 conflicts with the app's lifecycle-aware reconnect policy.
  - path_provider_android remains pinned because 2.3.1 passed compilation but failed repeated Android 14 cold-start checks.

Affected files:
- pubspec.yaml
- pubspec.lock
- lib/services/biometric_service.dart
- lib/services/notification_service.dart
- android/app/build.gradle.kts
- lib/services/app_config.dart
- environment JSON examples

Validation:
- Flutter analyzer and all 26 tests passed.
- Android debug APK built with the local environment configuration.
- Android 14 ARM64 validation exposed the Reverb 0.0.8 reconnect regression and confirmed secure-storage migration completed successfully.
