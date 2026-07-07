# AI App Task State

## Current Status

Last updated:
- 2026-07-07

Current task:
- Smooth and standardize UI motion for the mobile UI refactor without changing API behavior.

Current phase:
- Motion pass implemented; validation pending.

## 2026-07-07 Motion Smoothing Pass

- Added `AppMotion` shared duration and curve tokens for consistent, smoother UI motion.
- Smoothed Home category/content switching with fade + small slide transition.
- Added a lightweight press-scale interaction to product cards while keeping repaint isolated.
- Updated bottom navigation selected-icon scaling to use the shared motion curve and duration.
- Updated favorite icon switching, Tangki content refresh, cart total tween, shimmer sweep, and coffee loading loop to use smoother shared curves.
- API impact: none.
- UX impact: transitions should feel less abrupt and more consistent across browsing, cart, Tangki, and product detail.
- Token/env impact: none.
- Remaining risk: manual device check should confirm animations feel smooth on the connected phone and do not make product browsing feel slower.

## 2026-07-07 Mobile UI Refactor Branch

- Created branch `codex-ui-refactor` for UI-only work.
- Added shared typography helpers for serif titles, monospace ledger values, and tabular money figures.
- Added shared cafe UI components for 8px bordered surfaces, section headers, money text, ledger text, dividers, and the single allowed pickup-ticket perforation element.
- Updated Material theme defaults toward the restrained Coffee Plus design language: no card elevation, 8px cards/inputs, semantic brand color for actions, and serif title roles.
- Refactored Home dashboard/header/search/category/product-card surfaces toward the menu-board browsing model.
- Refactored Product Detail configuration controls toward a recipe-card model while preserving existing add-to-cart behavior.
- Refactored Cart balance/item/checkout summary toward a receipt model while keeping checkout and coupon behavior unchanged.
- Refactored Order Detail toward a pickup-ticket model and moved the perforation visual there only.
- Refactored Tangki status/refill/recent transactions toward stored-value card and ledger semantics without changing backend-authoritative balance/payment behavior.
- Refactored Auth modal toward a restrained security-entry style and theme-based success/error colors.
- API impact: none; no endpoint, request body, response parsing, token, or backend authority behavior changed in this pass.
- UX impact: key mobile user paths now share a stricter cafe ordering visual system with better dark/light semantic consistency.
- Token/env impact: none.
- Validation: `git diff --check` passed. `dart format`, `flutter analyze`, and `dart analyze lib` timed out in this shell without diagnostics.
- Remaining risk: manual device/analyzer validation is required; several secondary screens still need a later detailed UI pass for complete system-wide visual parity.

## 2026-07-07 Product Grid Overflow Fix

- Fixed Home product card bottom overflow observed on device after the UI refactor.
- Reduced the two-column product grid `childAspectRatio` from `0.68`/`0.75` to `0.62` for product, collection, and skeleton grids so two-line product names plus rating/OZ/price/action rows fit without clipping.
- API impact: none.
- UX impact: product cards are slightly taller and avoid the yellow/black Flutter overflow warning.
- Token/env impact: none.
- Remaining risk: manual device check should confirm the first viewport still shows enough product density after taller cards.

## 2026-07-07 Coffee Loading Color Update

- Changed global coffee color tokens from the brand emerald color to coffee-specific brown tones.
- Updated `CoffeeLoadingIndicator` defaults so the cup outline, liquid, and steam use warm coffee colors in both light and dark mode.
- Preserved `CoffeePainterConfig` overrides for call sites that need custom loading colors.
- API impact: none.
- UX impact: loading animation now visually reads as coffee instead of brand-green liquid.
- Token/env impact: none.
- Remaining risk: visual confirmation on device is recommended because perceived contrast can vary by display brightness.

## 2026-07-07 User-Facing Network Error Sanitization

- Replaced the Home error state's raw `DioException.toString()` display with `ErrorHandler.toUserMessage`.
- Replaced direct `snapshot.error` rendering in Notification, Order History, and Transaction History screens with sanitized ErrorHandler messages.
- Updated timeout and connection error messages to avoid exposing Dio class names, request timeout durations, or internal client configuration.
- Added a test proving connection timeout messages do not include `DioException`, `connectTimeout`, or the concrete 10-second duration.
- API impact: none.
- UX impact: offline/timeout states now show a concise user-safe message and retain retry behavior.
- Token/env impact: none.
- Remaining risk: manual device validation should confirm the exact offline screen copy across Home, Notifications, Orders, and Transactions.

## 2026-07-07 Transaction Payload Performance Sync

- Verified Laravel backend routes:
  - `GET /api/tangki`
  - `GET /api/transactions`
  - `GET /api/transactions/{bill_id}`
  - `GET /api/refunds`
- Verified backend list controllers now select summary transaction columns only and do not eager-load order detail relations.
- Confirmed `TransactionResource.order_details` is optional because it uses `whenLoaded`.
- Confirmed detail response shape is `{ "order": OrderResource }` from `TransactionController::showOrderDetail`.
- Added `ProfileService.fetchTransactionDetail(billId)` and `ApiService.fetchTransactionDetail(billId)` to load order detail on demand.
- Added session-level detail caching by `bill_id` to avoid repeat detail payload requests.
- Added `ProfileService.fetchRefunds()` and `ApiService.fetchRefunds()` for backend refund summary endpoint compatibility.
- Updated Transaction History and Tangki recent transaction rows to render from summary fields and fetch detail only when tapped.
- Added `Transaction.timestamp` parsing and a model test proving `order_details` can be absent.
- API impact: new Flutter consumption of `GET /transactions/{bill_id}`; list parsing treats `order_details` as optional.
- UX impact: tapping a transaction with `bill_id` shows the existing Coffee loading overlay before opening detail.
- Token/env impact: none.
- Validation: backend route/controller/resource read-only contract check completed. Flutter validation still needs a local run.
- Remaining risk: refund detail UI is not currently present in Flutter; the `/refunds` list endpoint is exposed through service/facade for future UI use.

## 2026-07-07 Laravel UI Replication Pass

- Inspected Laravel UI sources in `C:\laragon\www\Coffee-Plus`: `resources/css/app.css`, app/navigation layouts, dashboard, product list/detail, cart, Tangki, and shared button/card/badge/product-offer components.
- Replaced Flutter's previous purple/blue design tokens with Laravel-aligned Coffee Plus tokens: stone canvas, near-white surface, emerald brand, dark ink, caramel accent, and matching dark-mode equivalents.
- Standardized Material cards, inputs, chips, and AppBar behavior toward the Laravel UI's 8px radius, thin borders, low shadow, and emerald selected state.
- Updated mobile Home dashboard, search, category chips, product section rhythm, product cards, bottom navigation, product detail step labels/bottom action, order status accents, Tangki ledger icons, transaction detail buttons, and Points Mall badge color to follow the Laravel visual language while preserving mobile-specific interaction.
- Extended the Product model with display-only `average_rating`, `reviews_count`, and `oz_redeem_value` fields for Laravel ProductResource compatibility.
- API impact: no endpoint, request body, token, or backend authority behavior changed; product response parsing now tolerates additional display fields.
- UX impact: main browsing and product detail surfaces now use Coffee-Plus Laravel visual style and retain light/dark modes.
- Token/env impact: none.
- Validation: `git diff --check` passed. `dart format`, `flutter analyze`, and `dart analyze lib test` timed out in this shell without diagnostics; manual validation is required.
- Remaining risk: Cart, Profile, Notifications, and some secondary form states inherit the new tokens but still contain local hardcoded semantic colors and should receive a second detailed UI pass for full parity.

## 2026-07-03 Dependency Upgrade

- Upgraded Dio, local notifications, secure storage, shared preferences, intl, and local authentication packages.
- Refreshed all transitive packages resolvable within the final dependency constraints.
- Pinned path_provider_android to 2.2.22 after 2.3.1 repeatedly failed to register its platform channel on Android 14.
- Retained Reverb 0.0.4 after 0.0.8 produced uncaught WebSocket errors and an internal reconnect loop during Android device validation.
- Added `COFFEE_REVERB_ENABLED`, defaulting to false, so environments without a Reverb server perform no realtime profile fetch or WebSocket connection.
- Replaced unconstrained local-auth platform dependencies with explicit compatible versions.
- Migrated biometric authentication and local notification calls to their current named-parameter APIs.
- Updated Android core library desugaring to 2.1.4 as required by flutter_local_notifications 22.
- API impact: none; endpoints, payloads, response handling, and backend authority are unchanged.
- UX impact: no intended change; notification and biometric prompts retain their existing purpose and fallback behavior.
- Token impact: secure-storage package upgraded; storage keys and credential lifecycle are unchanged.
- Env impact: Reverb is now opt-in with `COFFEE_REVERB_ENABLED=true`.
- Validation: flutter analyze passed, all 26 tests passed, Android debug APK built successfully, and Android 14 ARM64 cold startup was exercised without filtered Flutter/native fatal errors.
- Remaining risk: notification delivery, biometric fallback, and authenticated Reverb success require manual device workflow checks.

## 2026-07-03 Product Detail Add-ons

- Added `ProductService` for `GET /products/{id}`.
- Product detail now refreshes the Dashboard product with the full API response.
- Dashboard data remains the fallback when detail loading fails.
- Missing `addons` is shown as a retryable backend-data warning; `addons: []` remains valid.
- Added consumer parsing tests for populated and omitted add-ons.
- Generated `docs/LARAVEL_PRODUCT_ADDONS_FIX_REPORT.md` without modifying Laravel.
- API impact: added product detail consumption; no request or backend behavior changed.
- UX impact: product detail shows a small loading indicator and retryable warning.
- Token/env impact: none.

## 2026-06-29 Performance Optimization

- Main navigation now mounts Tangki, Cart, and Profile only on first access, then retains their state.
- First access relies on each screen's existing `initState` load; revisits keep the existing explicit refresh behavior.
- Reverb reconnect uses a cancelable timer and only runs while the connection is intended to remain active.
- Active reconnect timers are canceled on intentional disconnect, logout, user replacement, and disposal.
- Loading overlays now close when the real request completes instead of waiting for an 1800 ms animation cycle.
- Product cards listen to a per-product favorite boolean instead of scanning and rebuilding from the complete favorites list.
- API impact: none.
- UX impact: hidden tabs load on first access; loading overlays disappear as soon as requests finish.
- Token/env impact: none.
- Remaining risk: logout/reconnect and UI behavior require manual device validation; the focused overlay test was added but could not run in the agent shell.
- User validation: full Flutter suite passed with 24 tests; five analyzer style findings were reported and corrected. A final analyzer rerun is pending.

## 2026-06-28 Device Token Sync

- Login and registration now send a stable `device_name` capped at 100 characters.
- Added on-demand device session listing in Profile.
- Added targeted and all-device token revocation.
- Current/all-device revocation clears local credentials and authentication state.
- Confirmed the backend response shape is `data.tokens[*].device_name/is_current` and targeted revoke returns `data.revoked_current`.
- Reconfirmed Tangki refill session extraction and backend-only payment confirmation remain intact.
- API impact: added `/tokens` and `/tokens/{tokenId}` calls; auth request bodies add optional `device_name`.
- UX impact: Profile adds a Device Sessions section with refresh and revoke confirmations.
- Token impact: local credentials are cleared only after current/all-device revocation succeeds.
- Env impact: none.

## 2026-06-27 Cleanup Result

- Added centralized JSON object parsing for service responses without changing API paths or payloads.
- Made `TimedCache` generic and fixed replacement at capacity so updating an existing key does not evict another entry.
- Limited the shared API response cache to 12 large entries to bound memory retained by dashboard search variants.
- Limited Flutter's decoded image cache to 120 images and 48 MB.
- Disabled animation tickers in hidden main tabs while preserving each tab's state.
- Added focused tests for response parsing and cache replacement behavior.
- API impact: none; endpoints, request bodies, response expectations, and payment authority are unchanged.
- UX impact: none intended; hidden animations pause and resume when their tab becomes visible.
- Token/env impact: none.
- Remaining risk: analyzer and tests must be run manually because both commands stalled without output in the agent shell.

## Pending App Issues

| Priority | Issue | Area | Next Step |
|---|---|---|---|
| High | Confirm backend provider contract alignment | API | Compare with Coffee-Plus docs/AI_API_PROVIDER_CONTRACT.md in backend repo |
| High | Confirm checkout response and payment flow semantics | Orders | Inspect backend contract before changing checkout UI |
| High | Confirm wallet/Tangki refill is backend-authoritative | Wallet | Verify /tangki/refill backend behavior before UI/payment changes |
| Medium | Confirm Reverb private auth endpoint path and payload | Realtime | Compare AppConfig values with backend broadcasting config |
| Medium | Confirm theme direction against product screenshots | UI | Use app-ui-upgrade-designer before UI patches |
| Medium | Confirm Android cleartext policy per environment | Build | Review debug/release network security behavior before release |

## Last Known Validation

Command:
- flutter --version
- flutter pub get
- flutter analyze
- flutter test

Result:
- Timed out after 60 seconds for `flutter --version`.
- Timed out after 120 seconds for `flutter pub get`.
- Timed out after 120 seconds for `flutter analyze`.
- Timed out after 120 seconds for `flutter test`.
- No Flutter source files were changed.

## Required Manual Validation

```powershell
dart format lib test
flutter analyze
flutter test
```
