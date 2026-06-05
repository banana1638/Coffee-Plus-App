class NotificationUtils {
  static List<dynamic> filterRecentAndPrioritized(
    List<dynamic> notifications, {
    DateTime? now,
    int maxItems = 30,
    int maxAgeDays = 30,
  }) {
    if (notifications.isEmpty) return notifications;

    final currentTime = now ?? DateTime.now();
    final oldestAllowed = currentTime.subtract(Duration(days: maxAgeDays));

    List<dynamic> filtered = notifications.where((notification) {
      final createdAtStr = notification['created_at'];
      if (createdAtStr == null) return true;
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt == null) return true;
      return createdAt.isAfter(oldestAllowed);
    }).toList();

    if (filtered.length > maxItems) {
      filtered.sort((a, b) {
        final aIsRead = a['read_at'] != null;
        final bIsRead = b['read_at'] != null;

        if (aIsRead != bIsRead) {
          return aIsRead ? 1 : -1;
        }

        final aDate = DateTime.tryParse(a['created_at'] ?? "") ?? DateTime(0);
        final bDate = DateTime.tryParse(b['created_at'] ?? "") ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

      filtered = filtered.take(maxItems).toList();
    }

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? "") ?? DateTime(0);
      final bDate = DateTime.tryParse(b['created_at'] ?? "") ?? DateTime(0);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }
}
