# Coffee Plus App Security Remediation Report

Audit date: 2026-06-11
Scope: Flutter mobile client, Android/iOS platform config, local storage, API client, authentication flow, notification/WebSocket setup, dependency posture.

## Executive Summary

The project is not production-safe yet. The client has a solid baseline in several places: API endpoint values are injected with `--dart-define`, bearer tokens are stored with `flutter_secure_storage`, checkout requests use an idempotency key, and release Android builds disable cleartext traffic.

However, there are release-blocking issues:

- iOS allows arbitrary network loads, weakening HTTPS enforcement.
- Android release is signed with the debug signing key.
- The app still uses the placeholder Android package id `com.example.coffee_plus_app`.
- Security-sensitive packages are locked behind current major releases.
- Documentation uses environment variable names that do not match the code, which can cause teams to accidentally ship insecure fallback/dev builds.

Overall risk rating: High for production release, Medium for development/internal testing.

## Findings and Fixes

### 1. iOS ATS Allows Arbitrary Loads

Severity: High
Evidence: `ios/Runner/Info.plist` sets `NSAllowsArbitraryLoads` to `true`.

Impact:
This allows the app to load resources over insecure transport on iOS. If a production build connects to HTTP endpoints or a downgraded network path, tokens, profile data, order data, and payment-related checkout requests can be exposed to interception.

Fix:

- Remove `NSAllowsArbitraryLoads=true`.
- Use HTTPS-only API, storage, and Reverb endpoints.
- If a local development exception is needed, use narrow domain-specific ATS exceptions in debug-only build configuration, not global arbitrary loads.

Recommended target state:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

Validation:

- Build iOS release and verify API/image/WebSocket traffic works only over HTTPS/WSS.
- Confirm there are no `http://` production endpoints in build arguments.

### 2. Android Release Uses Debug Signing Key

Severity: Critical
Evidence: `android/app/build.gradle.kts` release block uses `signingConfig = signingConfigs.getByName("debug")`.

Impact:
A production APK/AAB signed with the debug key cannot be trusted as a real production artifact. It complicates app store release, makes update chains unsafe, and signals that release hardening has not been completed.

Fix:

- Create a real release keystore outside source control.
- Load signing values from `key.properties`, environment variables, or CI secrets.
- Fail release builds when signing secrets are missing.
- Never commit keystore files or signing passwords.

Validation:

- Run `flutter build appbundle --release`.
- Verify the artifact is signed by the release certificate, not the debug certificate.

### 3. Android Application ID Is Still Placeholder

Severity: High
Evidence: `android/app/build.gradle.kts` uses `applicationId = "com.example.coffee_plus_app"`.

Impact:
The app identity is not production-ready. Package id collisions, store publishing issues, and poor trust posture are likely.

Fix:

- Replace with the final reverse-domain id, for example `com.company.coffeeplus`.
- Update Firebase, deep links, OAuth callbacks, app store metadata, and backend allowlists if applicable.

Validation:

- Build Android release and confirm the package id with `apkanalyzer` or Android Studio.

### 4. Cleartext Traffic Is Open by Default on Android

Severity: Medium
Evidence:

- `android/app/src/main/AndroidManifest.xml` reads `android:usesCleartextTraffic="${usesCleartextTraffic}"`.
- `android/app/build.gradle.kts` sets the default placeholder to `true`, then overrides release to `false`.

Impact:
Release builds are protected, but debug/profile variants can silently use HTTP. That is acceptable for local testing only if the team treats debug artifacts as untrusted and never distributes them.

Fix:

- Keep release `usesCleartextTraffic=false`.
- Prefer a debug-only `network_security_config.xml` that allows only local dev hosts.
- Document that debug builds must not be distributed to testers handling real accounts.

Validation:

- Inspect merged manifests for debug, profile, and release.
- Confirm release rejects HTTP API URLs.

### 5. Runtime Config Documentation Does Not Match Code

Severity: High
Evidence:

- Code expects `COFFEE_API_BASE_URL`, `COFFEE_REVERB_HOST`, `COFFEE_REVERB_APP_KEY`, `COFFEE_REVERB_TLS`, `COFFEE_REVERB_AUTH_ENDPOINT`, and optional origin/port values in `lib/services/app_config.dart`.
- README examples use `API_BASE_URL`, `REVERB_HOST`, and `REVERB_KEY`.

Impact:
Developers following README commands will not pass the values the app requires. This can cause broken builds, rushed workarounds, or unsafe hardcoding before release.

Fix:

- Update README examples to use the exact `COFFEE_*` names.
- Include `COFFEE_REVERB_TLS=true` and a HTTPS/WSS production example.
- Add CI checks that run a release build with required `--dart-define` values.

Validation:

- Run app with README command exactly as documented.
- Confirm `AppConfig` does not throw missing-value errors.

### 6. Token Storage Is Good, but Token Lifecycle Needs Hardening

Severity: Medium
Evidence:

- `lib/services/api_client.dart` stores `auth_token` using `FlutterSecureStorage`.
- `lib/services/auth_service.dart` persists tokens when `rememberMe=true`, otherwise keeps them in memory.
- 401 responses clear auth state.

Impact:
Encrypted local storage is appropriate, but long-lived bearer tokens still become high-value secrets if the device is compromised. There is no visible refresh-token rotation, explicit expiry handling, or device/session revocation strategy in the client.

Fix:

- Prefer short-lived access tokens plus refresh tokens with server-side rotation and revocation.
- Clear stored token on password change and account deletion.
- Consider binding refresh tokens to device/session records on the backend.
- Ensure secure storage backups are disabled or configured appropriately per platform.

Validation:

- Expire a token server-side and confirm the client clears session on 401.
- Change password on one device and verify other sessions are revoked if policy requires it.

### 7. WebSocket/Reverb Security Depends on Build-Time Values

Severity: Medium
Evidence:

- `lib/services/notification_service.dart` passes `useTLS: AppConfig.reverbUseTls`.
- Auth headers include bearer token for private-channel authorization.
- `COFFEE_REVERB_TLS` is required by `AppConfig`.

Impact:
This is structurally sound, but production security depends on passing `COFFEE_REVERB_TLS=true`, using WSS-compatible host/port, and ensuring the backend authorizes private channels by authenticated user id.

Fix:

- Enforce `COFFEE_REVERB_TLS=true` in release builds.
- Reject non-HTTPS `COFFEE_REVERB_AUTH_ENDPOINT` in release builds.
- On the Laravel backend, verify `private-App.Models.User.{id}` authorization compares `{id}` to the authenticated user id.

Validation:

- Attempt to subscribe to another user's private channel and confirm denial.
- Inspect release build args in CI.

### 8. Logging Still Uses Raw debugPrint in Some Screens/Services

Severity: Medium
Evidence:

- `lib/screens/user/notification_screen.dart` uses `debugPrint`.
- `lib/services/favorite_service.dart` uses `debugPrint`.
- `AppLogger.error` suppresses error details in non-debug builds, which is good.

Impact:
`debugPrint` can leak exception contents during non-release builds. If QA/internal builds use real accounts, this can expose IDs, payload snippets, or backend messages in device logs.

Fix:

- Replace remaining `debugPrint` calls with `AppLogger`.
- Do not log bearer tokens, passwords, full notification payloads, or full server exception bodies.
- Treat profile builds like release for sensitive log content.

Validation:

- Run `rg -n "debugPrint|print\\(" lib` and confirm only `AppLogger` wraps logging.

### 9. Local Favorites Use SharedPreferences

Severity: Low to Medium
Evidence: `lib/services/favorite_service.dart` stores `favorite_items` in `SharedPreferences`.

Impact:
Favorites are not as sensitive as credentials, but they may reveal user behavior/preferences. SharedPreferences is not encrypted and can persist after logout unless cleared.

Fix:

- Clear local favorites on logout if favorites are account-specific.
- If product preferences are considered personal data, move them to secure storage or server-only state.
- Avoid caching server-owned favorite ids for logged-out users.

Validation:

- Log out and confirm account-specific favorites are removed or isolated per user.

### 10. Client-Side Amount and Order Inputs Must Be Server-Validated

Severity: Medium
Evidence:

- `lib/services/profile_service.dart` sends refill `amount` directly to `/tangki/refill`.
- `lib/services/cart_service.dart` sends cart quantities, selected OZ ids, and coupon code to checkout.

Impact:
Mobile clients are fully attacker-controlled. Any user can modify requests outside the app UI. The server must never trust client-calculated totals, quantities, discounts, OZ balances, or order ownership.

Fix:

- Server must recalculate all prices, discounts, taxes, inventory, OZ balance, and ownership.
- Server must validate min/max amount and quantity.
- Server must enforce idempotency keys per user and endpoint.
- Server must authorize order cancellation/detail access by owner.

Validation:

- Replay modified requests with changed amount, cart item ids, order ids, and OZ ids.
- Confirm server rejects unauthorized or invalid values.

### 11. Dependencies Need Security Maintenance

Severity: Medium
Evidence: `flutter pub outdated --no-dev-dependencies` completed and showed several security-sensitive packages behind latest major versions:

- `flutter_local_notifications`: current 17.2.4, latest 22.0.0
- `flutter_secure_storage`: current 9.2.4, latest 10.3.1
- `local_auth`: current 2.3.0, latest 3.0.1
- `local_auth_android`: current 1.0.56, latest 2.0.9
- `local_auth_darwin`: current 1.6.1, latest 2.0.3
- `pusher_reverb_flutter`: current 0.0.4, latest 0.0.8
- `shared_preferences`: current 2.5.4, latest 2.5.5
- Transitive `js` package is discontinued.

Impact:
Outdated security, auth, notification, and WebSocket packages increase maintenance risk. This audit did not confirm specific exploitable CVEs, but the dependency posture should be improved before release.

Fix:

- Run `flutter pub upgrade --major-versions` on a branch.
- Read migration guides for `flutter_secure_storage`, `local_auth`, and notification APIs.
- Run full Android/iOS regression tests after upgrades.
- Add scheduled dependency checks in CI.

Validation:

- `flutter pub outdated`
- `flutter test`
- Manual biometric checkout and notification tests on Android/iOS devices.

## Positive Security Controls Observed

- No hardcoded production API URL or bearer token was found in source.
- `AppConfig` requires critical runtime values instead of silently defaulting.
- API bearer token injection is centralized in `ApiClient`.
- 401 responses clear local auth state.
- Checkout uses a cryptographically random idempotency key.
- Private notification channel authorization sends a bearer token.
- Release Android build sets `usesCleartextTraffic=false`.
- Password update and account deletion require the current password.

## Verification Notes

Commands run:

- `rg --files`
- `rg -n "(http://|https://|token|secret|password|api[_-]?key|Authorization|debugPrint|print\\(|SharedPreferences|FlutterSecureStorage|allowBackup|usesCleartextTraffic|NSAllowsArbitraryLoads|Reverb|pusher|biometric|local_auth)" lib android ios pubspec.yaml README.md`
- `flutter pub outdated --no-dev-dependencies`
- `flutter analyze --no-pub`
- `flutter test --no-pub`

Current validation result:

- `flutter analyze --no-pub` completed with no issues.
- `flutter test --no-pub` completed with all tests passing.
- First non-escalated `flutter pub outdated --no-dev-dependencies` timed out after 60 seconds; rerun with network access succeeded.

API contract matching completed against `C:\laragon\www\Coffee-Plus\routes\api.php` and the API controllers/resources. Flutter routes, HTTP methods, and request fields match the backend for dashboard, auth, cart, checkout, coupons, orders, profile, notifications, tangki, transactions, and favorites. The client now unwraps Laravel `data` payloads for cart and favorites and accepts both `base_price` and `price` product fields.

## Recommended Remediation Order

1. Replace Android debug signing in release builds with real release signing.
2. Disable iOS `NSAllowsArbitraryLoads` and verify HTTPS/WSS-only production traffic.
3. Replace `com.example.coffee_plus_app` with the final application id.
4. Fix README `--dart-define` names and include complete secure production examples.
5. Enforce HTTPS/WSS config for release builds.
6. Replace raw `debugPrint` calls with `AppLogger`.
7. Upgrade security-sensitive dependencies and retest.
8. Add CI gates for `flutter analyze`, `flutter test`, release build, dependency checks, and secret scanning.
9. Confirm backend authorization/rate-limiting for login, checkout, refill, favorites, orders, notifications, and private broadcast channels.

## Production Go/No-Go

Current recommendation: No-go for public production release.

Minimum go-live criteria:

- Android release uses a real release signing key.
- iOS ATS no longer allows arbitrary loads.
- Production API, storage, auth endpoint, and Reverb traffic use HTTPS/WSS.
- README and CI use the same required `COFFEE_*` build variables as the code.
- Full test and analysis runs complete successfully.
- Backend confirms server-side authorization and recalculation for all order/payment/loyalty actions.
