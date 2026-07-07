# AI API Consumer Contract

This file documents how Coffee-Plus-App consumes the Coffee-Plus backend API.

## Rule

When the Flutter app adds or changes API calls, update this file.

The backend provider contract lives in Coffee-Plus:
- docs/AI_API_PROVIDER_CONTRACT.md

This app contract should match the backend provider contract, but this app does not define the backend truth.

## API Consumer Table

| Feature | App File | Method | HTTP Method | Path | Auth | Request Body | Expected Response | Status |
|---|---|---|---|---|---|---|---|---|
| Login | lib/services/auth_service.dart | login | POST | /login | No | email, password, device_name | status=success, access_token | Verified 2026-06-28 |
| Register | lib/services/auth_service.dart | register | POST | /register | No | name, email, password, password_confirmation, device_name | access_token | Verified 2026-06-28 |
| Logout | lib/services/auth_service.dart | logout | POST | /logout | Yes | none | success/any response; app clears local state | Detected |
| Profile session | lib/services/auth_service.dart | validateSession | GET | /profile | Yes | none | profile data, 200 | Detected |
| Dashboard/products | lib/services/api_service.dart | fetchDashboard | GET | /dashboard | Optional | query: search, category | menus, allCategoryNames, user | Detected |
| Product detail | lib/services/product_service.dart | fetchProductDetail | GET | /products/{id} | No | none | product, options; product.addons must be present as an array; average_rating/reviews_count/oz_redeem_value are display-only when present | Flutter implemented; backend fix required |
| Cart fetch | lib/services/cart_service.dart | fetchCart | GET | /cart | Yes | none | cartItems/data | Detected |
| Add to cart | lib/services/cart_service.dart | addToCart | POST | /cart/add | Yes | product_id, quantity, size, temp, addons | success response | Detected |
| Update cart | lib/services/cart_service.dart | updateCartItem | POST | /cart/update | Yes | cart_item_id, quantity | cart response | Detected |
| Remove cart | lib/services/cart_service.dart | removeFromCart | POST | /cart/remove | Yes | cart_item_id | cart response | Detected |
| Checkout | lib/services/cart_service.dart | checkoutWithOz | POST | /checkout | Yes | use_oz, optional coupon_code; Idempotency-Key header | checkout/order response | Critical backend verification required |
| Coupon apply | lib/services/coupon_service.dart | validateCoupon | GET | /coupons/validate | Yes | query: code, subtotal | data or response map | Backend must validate |
| Order history | lib/services/order_service.dart | fetchOrders | GET | /orders | Yes | query: page | paginated order response | Detected |
| Order detail | lib/services/order_service.dart | fetchOrder | GET | /orders/{orderId} | Yes | none | order response | Detected |
| Cancel order | lib/services/order_service.dart | cancelOrder | POST | /orders/{orderId}/cancel | Yes | none | cancel response | Detected |
| Wallet balance | lib/services/profile_service.dart | fetchTangki | GET | /tangki | Yes | none | user and summary transactions; transaction order_details may be absent | Verified 2026-07-07 |
| Wallet refill | lib/services/profile_service.dart | refillTangki | POST | /tangki/refill | Yes | amount | redirect_url, session_id | Verified 2026-06-28 |
| Payment status | lib/services/payment_service.dart | fetchPaymentStatus | GET | /payments/{sessionId}/status | Yes | none | data.status; only processed confirms payment | Verified 2026-06-28 |
| Transactions | lib/services/profile_service.dart | fetchTransactions | GET | /transactions | Yes | optional query: type | summary transaction list; order_details may be absent | Verified 2026-07-07 |
| Transaction order detail | lib/services/profile_service.dart | fetchTransactionDetail | GET | /transactions/{bill_id} | Yes | none | order detail object from response.order | Verified 2026-07-07 |
| Refunds | lib/services/profile_service.dart | fetchRefunds | GET | /refunds | Yes | none | summary refund list; order_details may be absent | Verified 2026-07-07 |
| Profile fetch | lib/services/profile_service.dart | fetchProfile | GET | /profile | Yes | none | profile response | Detected |
| Profile update | lib/services/profile_service.dart | updateProfile | POST | /profile/update | Yes | name, email | updated profile response | Detected |
| Password update | lib/services/profile_service.dart | updatePassword | POST | /profile/password | Yes | current_password, password, password_confirmation | response, optional access_token | Detected |
| Delete account | lib/services/profile_service.dart | deleteAccount | POST | /profile/delete | Yes | password | success response | Detected |
| Device token list | lib/services/token_service.dart | fetchTokens | GET | /tokens | Yes | none | data.tokens metadata, including is_current; no secrets | Verified 2026-06-28 |
| Device token revoke | lib/services/token_service.dart | revokeToken | DELETE | /tokens/{tokenId} | Yes | none | data.revoked_current | Verified 2026-06-28 |
| Revoke all device tokens | lib/services/token_service.dart | revokeAllTokens | DELETE | /tokens | Yes | none | data.revoked_count | Verified 2026-06-28 |
| Notifications | lib/services/api_service.dart | fetchNotifications | GET | /profile/notifications | Yes | none | notifications list | Detected |
| Mark notification read | lib/services/api_service.dart | markNotificationAsRead | POST | /profile/notifications/{id}/read | Yes | none | success response | Detected |
| Delete read notifications | lib/services/api_service.dart | deleteReadNotifications | POST | /profile/notifications/delete-read | Yes | none | success response | Detected |
| Batch delete notifications | lib/services/api_service.dart | deleteNotifications | POST | /profile/notifications/batch-delete | Yes | ids | success response | Detected |
| Favorites fetch | lib/services/api_service.dart | fetchFavorites | GET | /favorites | Yes | none | data/list | Detected |
| Favorite add | lib/services/api_service.dart | addFavorite | POST | /favorites | Yes | product_id, size, temp, addons, remark | data/map | Detected |
| Favorite remove | lib/services/api_service.dart | removeFavorite | DELETE | /favorites/{favoriteId} | Yes | none | success response | Detected |
| Broadcasting auth | lib/services/notification_service.dart | Reverb authorizer | Reverb plugin | AppConfig.reverbAuthEndpoint | Yes | Authorization header, socket/channel handled by plugin | private channel auth response | Needs backend verification |

## App Must Treat These As Display Values Only

- product price
- discount
- final amount
- wallet balance
- payment success
- order status
- user role

## Device Token Rules

- Login and registration send a stable human-readable `device_name` no longer than 100 characters.
- Token list responses are metadata only; the app must never expect or log token secrets.
- Revoking the current token or all tokens clears local credentials immediately.
- Revoking another owned device token keeps the current session active.
