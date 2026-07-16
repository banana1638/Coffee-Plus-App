import 'package:coffee_plus_app/services/notification_deduplicator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDeduplicator', () {
    test('rejects duplicate ids', () {
      final deduplicator = NotificationDeduplicator(maxSize: 2);

      expect(deduplicator.markIfNew('a'), isTrue);
      expect(deduplicator.markIfNew('a'), isFalse);
    });

    test('evicts old ids after capacity', () {
      final deduplicator = NotificationDeduplicator(maxSize: 2);

      expect(deduplicator.markIfNew('a'), isTrue);
      expect(deduplicator.markIfNew('b'), isTrue);
      expect(deduplicator.markIfNew('c'), isTrue);
      expect(deduplicator.markIfNew('a'), isTrue);
    });

    test('allows missing ids because they cannot be safely deduped', () {
      final deduplicator = NotificationDeduplicator();

      expect(deduplicator.markIfNew(null), isTrue);
      expect(deduplicator.markIfNew(''), isTrue);
    });
  });
}
