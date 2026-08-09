import 'dart:math';

final _random = Random();

/// Awaits a random delay so loading/shimmer states are actually visible,
/// standing in for the latency a real backend call would have.
Future<void> simulateDelay({int minMs = 300, int maxMs = 900}) {
  final delay = minMs + _random.nextInt(maxMs - minMs + 1);
  return Future.delayed(Duration(milliseconds: delay));
}
