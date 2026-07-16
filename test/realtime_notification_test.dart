import 'dart:convert';

import 'package:coffee_plus_app/models/realtime_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealtimeNotification', () {
    test('parses direct broadcast envelope', () {
      final notification = RealtimeNotification.fromPayload({
        'notification_id': 'notif-1',
        'event': 'order.ready_for_pickup',
        'title': 'Order ready',
        'message': 'Your coffee is ready.',
        'occurred_at': '2026-07-15T10:00:00Z',
        'action': {'route': 'order_detail', 'order_id': 9},
        'data': {'bill_id': 'CP-9'},
      });

      expect(notification.id, 'notif-1');
      expect(notification.event, RealtimeNotificationEvent.orderReadyForPickup);
      expect(notification.orderId, 9);
      expect(notification.billId, 'CP-9');
      expect(notification.affectsOrders, isTrue);
      expect(notification.affectsWallet, isFalse);
    });

    test('parses database notification style payload with nested data', () {
      final notification = RealtimeNotification.fromPayload({
        'id': 'db-notif-1',
        'created_at': '2026-07-15T11:00:00Z',
        'data': {
          'event': 'wallet.refill.succeeded',
          'title': 'Refill confirmed',
          'message': 'Your Tangki balance was updated.',
          'data': {'session_id': 'cs_test_123', 'amount_cents': '5000'},
        },
      });

      expect(notification.id, 'db-notif-1');
      expect(
        notification.event,
        RealtimeNotificationEvent.walletRefillSucceeded,
      );
      expect(notification.sessionId, 'cs_test_123');
      expect(notification.amountCents, 5000);
      expect(notification.affectsWallet, isTrue);
    });

    test('parses JSON string payload and falls back for unknown events', () {
      final notification = RealtimeNotification.fromPayload(
        jsonEncode({
          'event': 'custom.future_event',
          'message': 'Something changed.',
        }),
      );

      expect(notification.event, RealtimeNotificationEvent.unknown);
      expect(notification.title, 'Coffee Plus');
      expect(notification.message, 'Something changed.');
    });
  });
}
