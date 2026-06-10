class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  _CacheEntry(this.data, Duration ttl) : expiresAt = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class TimedCache {
  final int maxSize;
  final Duration defaultTtl;
  final _store = <String, _CacheEntry>{};

  TimedCache({
    this.maxSize = 50,
    this.defaultTtl = const Duration(minutes: 5),
  });

  void set(String key, dynamic value, {Duration? ttl}) {
    _evictExpired(); // 先清理过期的
    
    if (_store.length >= maxSize) {
      // 超出大小限制，移除最旧的一条
      _store.remove(_store.keys.first);
    }
    _store[key] = _CacheEntry(value, ttl ?? defaultTtl);
  }

  dynamic get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  void remove(String key) => _store.remove(key);

  void removeWhere(bool Function(String key, dynamic value) test) {
    _store.removeWhere((k, v) => test(k, v.data));
  }

  void clear() => _store.clear();

  void _evictExpired() {
    _store.removeWhere((_, entry) => entry.isExpired);
  }

  int get size => _store.length;
}