import 'error.dart';

// ─────────────────────────────────────────────────────────────
// GlobalErrorWidget
// ─────────────────────────────────────────────────────────────

/// Failure অনুযায়ী সঠিক icon + message + retry button দেখায়।
///
/// Usage:
/// ```dart
/// if (state is ErrorState) {
///   return GlobalErrorWidget(
///     failure: state.failure,
///     onRetry: () => ref.refresh(myProvider),
///   );
/// }
/// ```
class GlobalErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const GlobalErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final config = _ErrorConfig.from(failure);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 64, color: config.color),
            const SizedBox(height: 16),
            Text(
              config.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              failure.userMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (failure.isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              RetryWidget(onRetry: onRetry!, label: retryLabel),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RetryWidget — standalone use করা যাবে
// ─────────────────────────────────────────────────────────────

class RetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? label;

  const RetryWidget({super.key, required this.onRetry, this.label});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(label ?? 'Try Again'),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inline snackbar helper — quick toast error
// ─────────────────────────────────────────────────────────────

class ErrorSnackbar {
  ErrorSnackbar._();

  static void show(BuildContext context, Failure failure) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failure.userMessage),
        backgroundColor: _snackbarColor(failure),
        behavior: SnackBarBehavior.floating,
        action: failure.isRetryable
            ? null // caller নিজে handle করবে retry
            : null,
      ),
    );
  }

  static Color _snackbarColor(Failure failure) => switch (failure) {
    NetworkFailure() => Colors.orange[800]!,
    AuthFailure() => Colors.red[700]!,
    ServerFailure() => Colors.red[800]!,
    _ => Colors.grey[800]!,
  };
}

// ─────────────────────────────────────────────────────────────
// Internal config helper
// ─────────────────────────────────────────────────────────────

class _ErrorConfig {
  final IconData icon;
  final Color color;
  final String title;

  const _ErrorConfig({
    required this.icon,
    required this.color,
    required this.title,
  });

  factory _ErrorConfig.from(Failure failure) => switch (failure) {
    NetworkFailure() => const _ErrorConfig(
      icon: Icons.wifi_off_rounded,
      color: Colors.orange,
      title: 'No Internet Connection',
    ),
    AuthFailure() => const _ErrorConfig(
      icon: Icons.lock_outline_rounded,
      color: Colors.red,
      title: 'Session Expired',
    ),
    ServerFailure() => const _ErrorConfig(
      icon: Icons.cloud_off_rounded,
      color: Colors.red,
      title: 'Server Error',
    ),
    CacheFailure() => const _ErrorConfig(
      icon: Icons.storage_rounded,
      color: Colors.blue,
      title: 'Cache Error',
    ),
    _ => const _ErrorConfig(
      icon: Icons.error_outline_rounded,
      color: Colors.grey,
      title: 'Something Went Wrong',
    ),
  };
}
