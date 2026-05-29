import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow/shared/async/debouncer.dart';

void main() {
  group('Debouncer', () {
    const window = Duration(milliseconds: 30);
    // Comfortably longer than the window so the trailing timer has fired.
    const settle = Duration(milliseconds: 80);

    test('collapses a burst of rapid calls into a single invocation', () async {
      var runs = 0;
      final debouncer = Debouncer(window);

      for (var i = 0; i < 20; i++) {
        debouncer(() => runs++);
      }
      // Nothing fires synchronously — the action is purely trailing.
      expect(runs, 0);
      expect(debouncer.isScheduled, isTrue);

      await Future<void>.delayed(settle);

      expect(runs, 1, reason: '20 rapid calls should collapse to one run');
      expect(debouncer.isScheduled, isFalse);
      debouncer.dispose();
    });

    test('runs the most recently scheduled action', () async {
      String? lastRun;
      final debouncer = Debouncer(window);

      debouncer(() => lastRun = 'first');
      debouncer(() => lastRun = 'second');
      debouncer(() => lastRun = 'third');

      await Future<void>.delayed(settle);

      expect(lastRun, 'third');
      debouncer.dispose();
    });

    test('separate bursts each produce their own invocation', () async {
      var runs = 0;
      final debouncer = Debouncer(window);

      debouncer(() => runs++);
      await Future<void>.delayed(settle);
      expect(runs, 1);

      debouncer(() => runs++);
      await Future<void>.delayed(settle);
      expect(runs, 2);

      debouncer.dispose();
    });

    test('cancel() drops the pending invocation', () async {
      var runs = 0;
      final debouncer = Debouncer(window);

      debouncer(() => runs++);
      expect(debouncer.isScheduled, isTrue);
      debouncer.cancel();
      expect(debouncer.isScheduled, isFalse);

      await Future<void>.delayed(settle);
      expect(runs, 0, reason: 'cancelled action must never run');
      debouncer.dispose();
    });

    test('dispose() drops the pending invocation', () async {
      var runs = 0;
      final debouncer = Debouncer(window);

      debouncer(() => runs++);
      debouncer.dispose();

      await Future<void>.delayed(settle);
      expect(runs, 0);
    });
  });
}
