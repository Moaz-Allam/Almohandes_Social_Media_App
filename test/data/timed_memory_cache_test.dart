import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow/data/cache/timed_memory_cache.dart';

void main() {
  test('reuses fresh values inside the ttl', () async {
    var now = DateTime(2026, 5, 6, 10);
    var calls = 0;
    final cache = TimedMemoryCache<int>(
      ttl: const Duration(minutes: 1),
      now: () => now,
    );

    final first = await cache.read(() async => ++calls);
    now = now.add(const Duration(seconds: 30));
    final second = await cache.read(() async => ++calls);

    expect(first, 1);
    expect(second, 1);
    expect(calls, 1);
  });

  test('refetches expired values', () async {
    var now = DateTime(2026, 5, 6, 10);
    var calls = 0;
    final cache = TimedMemoryCache<int>(
      ttl: const Duration(minutes: 1),
      now: () => now,
    );

    expect(await cache.read(() async => ++calls), 1);
    now = now.add(const Duration(minutes: 2));

    expect(await cache.read(() async => ++calls), 2);
    expect(calls, 2);
  });

  test('shares concurrent in-flight requests', () async {
    var calls = 0;
    final completer = Completer<int>();
    final cache = TimedMemoryCache<int>(ttl: const Duration(minutes: 1));

    final first = cache.read(() {
      calls += 1;
      return completer.future;
    });
    final second = cache.read(() {
      calls += 1;
      return Future.value(2);
    });

    completer.complete(7);

    expect(await first, 7);
    expect(await second, 7);
    expect(calls, 1);
  });

  test('force refresh bypasses fresh cached data', () async {
    var calls = 0;
    final cache = TimedMemoryCache<int>(ttl: const Duration(minutes: 5));

    expect(await cache.read(() async => ++calls), 1);
    expect(await cache.read(() async => ++calls, forceRefresh: true), 2);
    expect(calls, 2);
  });
}
