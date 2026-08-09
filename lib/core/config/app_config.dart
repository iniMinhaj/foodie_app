/// App-wide tunables that would otherwise be magic numbers scattered
/// across modules.
abstract final class AppConfig {
  static const int pageSize = 10;
  static const Duration debounceDuration = Duration(milliseconds: 400);
  static const Duration cacheTtl = Duration(minutes: 5);
}
