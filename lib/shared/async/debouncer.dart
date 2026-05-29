import 'dart:async';

/// Coalesces a burst of rapid calls into a single trailing invocation.
///
/// Each [call] resets an internal timer; the supplied action runs once,
/// [duration] after the most recent call. Used to collapse Realtime
/// row-change bursts (e.g. twenty `messages` rows arriving at once) into a
/// single refetch instead of twenty `forceRefresh` round-trips.
///
/// Pure Dart with no Flutter dependency so it can be unit-tested directly.
class Debouncer {
  Debouncer(this.duration);

  /// The quiet window that must elapse after the last [call] before the
  /// pending action fires.
  final Duration duration;

  Timer? _timer;

  /// Schedules [action] to run after [duration]. A subsequent call before the
  /// timer fires cancels the previous schedule, so only the last action runs.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// True while an action is scheduled but has not fired yet.
  bool get isScheduled => _timer?.isActive ?? false;

  /// Cancels any pending invocation without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Alias for [cancel]; lets owners treat this like any disposable.
  void dispose() => cancel();
}
