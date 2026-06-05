import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_plus_app/services/notification_utils.dart';

void main() {
  group('NotificationUtils.filterRecentAndPrioritized', () {
    test('removes notifications older than the retention window', () {
      final result = NotificationUtils.filterRecentAndPrioritized([
        {'id': 'old', 'created_at': '2025-12-01T00:00:00Z'},
        {'id': 'fresh', 'created_at': '2026-01-20T00:00:00Z'},
      ], now: DateTime.utc(2026, 1, 31));

      expect(result.map((n) => n['id']), ['fresh']);
    });

    test('keeps unread notifications before read ones when trimming', () {
      final notifications = <Map<String, dynamic>>[
        for (var i = 0; i < 35; i++)
          {
            'id': 'read-$i',
            'created_at': DateTime.utc(2026, 1, i + 1).toIso8601String(),
            'read_at': '2026-01-31T00:00:00Z',
          },
        for (var i = 0; i < 3; i++)
          {
            'id': 'unread-$i',
            'created_at': DateTime.utc(2026, 1, i + 1).toIso8601String(),
            'read_at': null,
          },
      ];

      final result = NotificationUtils.filterRecentAndPrioritized(
        notifications,
        now: DateTime.utc(2026, 1, 30),
      );

      expect(result, hasLength(30));
      expect(result.where((n) => n['read_at'] == null), hasLength(3));
      expect(result.map((n) => n['id']), contains('unread-0'));
    });

    test('returns newest-first order after trimming', () {
      final notifications = [
        for (var i = 0; i < 31; i++)
          {
            'id': '$i',
            'created_at': DateTime.utc(2026, 1, i + 1).toIso8601String(),
            'read_at': null,
          },
      ];

      final result = NotificationUtils.filterRecentAndPrioritized(
        notifications,
        now: DateTime.utc(2026, 1, 31),
      );

      expect(result.first['id'], '30');
      expect(result.last['id'], '1');
    });
  });
}
