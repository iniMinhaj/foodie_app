import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/cache/cache_box.dart';

void main() {
  group('CacheBox', () {
    test('returns null on a miss', () {
      final cache = CacheBox<String>();

      expect(cache.read('missing', const Duration(minutes: 5)), isNull);
    });

    test('returns the stored value within the ttl', () {
      final cache = CacheBox<String>();
      cache.write('key', 'value');

      expect(cache.read('key', const Duration(minutes: 5)), 'value');
    });

    test('returns null once the entry is older than the ttl', () async {
      final cache = CacheBox<String>();
      cache.write('key', 'stale');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(cache.read('key', Duration.zero), isNull);
    });

    test('invalidate removes an entry', () {
      final cache = CacheBox<String>();
      cache.write('key', 'value');
      cache.invalidate('key');

      expect(cache.read('key', const Duration(minutes: 5)), isNull);
    });
  });
}
