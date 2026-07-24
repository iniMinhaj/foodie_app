import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_theme.dart';

/// Generic "nothing here" view - reused for empty cart, no search results,
/// no orders, etc. Kept as one widget instead of a bespoke layout per
/// screen, which is what a golden test would target.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: Icon(icon, size: 40.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              SizedBox(height: AppSpacing.md),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Distinct from EmptyStateView on purpose: an error is retry-able and
/// actionable, an empty state usually isn't. Centralizing this here means
/// every repository failure across the app renders identically -
/// TODO: Riverpod - this is what you'd show on AsyncValue.error.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40.sp, color: AppColors.error),
            SizedBox(height: AppSpacing.md),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: AppSpacing.xs),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
