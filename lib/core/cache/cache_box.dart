class CacheEntry<T> {
  final T value;
  final DateTime storedAt;

  CacheEntry(this.value, {DateTime? storedAt}) : storedAt = storedAt ?? DateTime.now();

  bool isExpired(Duration ttl) => DateTime.now().difference(storedAt) > ttl;
}

/// A tiny in-memory TTL cache keyed by string. Never throws — a miss or
/// an expired entry both just come back as `null`, and it's up to the
/// caller to decide whether to refetch.
class CacheBox<T> {
  final Map<String, CacheEntry<T>> _entries = {};

  T? read(String key, Duration ttl) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.isExpired(ttl)) return null;
    return entry.value;
  }

  void write(String key, T value) {
    _entries[key] = CacheEntry<T>(value);
  }

  void invalidate(String key) {
    _entries.remove(key);
  }
}
