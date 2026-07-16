import 'dart:collection';

class NotificationDeduplicator {
  final int maxSize;
  final Set<String> _seen = <String>{};
  final ListQueue<String> _order = ListQueue<String>();

  NotificationDeduplicator({this.maxSize = 100});

  bool markIfNew(String? id) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) return true;
    if (_seen.contains(normalized)) return false;

    _seen.add(normalized);
    _order.addLast(normalized);

    while (_order.length > maxSize) {
      final removed = _order.removeFirst();
      _seen.remove(removed);
    }

    return true;
  }

  void clear() {
    _seen.clear();
    _order.clear();
  }
}
