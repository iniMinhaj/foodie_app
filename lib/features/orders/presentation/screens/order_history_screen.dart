import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/shimmer_placeholders.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status_x.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: List.generate(4, (_) => const ProductCardSkeleton()),
        ),
        error: (error, stackTrace) => ErrorStateView(
          message: error is Failure ? error.userMessage : 'Could not load your orders.',
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your order history will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(ordersProvider.future),
                child: ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => _OrderCard(order: orders[index]),
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order))),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            AppImage(url: order.restaurantLogoUrl, width: 48.w, height: 48.w),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.restaurantName, style: Theme.of(context).textTheme.titleMedium),
                  Text(order.orderNumber, style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: 4.h),
                  Text(
                    '${order.items.length} item(s) • \$${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: order.status.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                order.status.label,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: order.status.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
