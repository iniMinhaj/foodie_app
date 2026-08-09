import 'dart:async';

/// Runs [action] after [delay] has elapsed with no further calls to
/// [run] — cancels any pending timer first, so only the most recent
/// call actually fires.
///
/// Note: this only reduces call *frequency*. It does not by itself
/// protect against an earlier, slower async call resolving after a
/// later, faster one — callers with that race (e.g. search) still need
/// their own request-id guard.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer(this.delay);

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
