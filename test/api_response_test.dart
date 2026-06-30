import 'package:coffee_plus_app/services/api_response.dart';
import 'package:coffee_plus_app/services/timed_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API response parsing', () {
    test('returns a typed JSON map', () {
      expect(requireJsonMap({'status': 'success'}), {'status': 'success'});
    });

    test('unwraps nested data objects and preserves flat objects', () {
      expect(
        unwrapDataMap({
          'data': {'id': 7},
        }),
        {'id': 7},
      );
      expect(unwrapDataMap({'id': 8}), {'id': 8});
    });

    test('rejects non-object responses', () {
      expect(() => requireJsonMap([]), throwsFormatException);
    });
  });

  test('TimedCache preserves its value type', () {
    final cache = TimedCache<Map<String, dynamic>>();
    cache.set('dashboard', {'menus': []});

    expect(cache.get('dashboard'), {'menus': []});
  });

  test('TimedCache updates an existing key without evicting another value', () {
    final cache = TimedCache<int>(maxSize: 2);
    cache.set('first', 1);
    cache.set('second', 2);
    cache.set('first', 3);

    expect(cache.get('first'), 3);
    expect(cache.get('second'), 2);
  });
}
