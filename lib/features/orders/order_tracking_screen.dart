import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  static const _fullFlow = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.currentStatus == OrderStatus.cancelled;
    final completedStatuses = order.statusTimeline.map((e) => e.status).toSet();

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.restaurantName, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: AppSpacing.sm),
                for (final item in order.items)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      children: [
                        Text('${item.quantity}x ', style: Theme.of(context).textTheme.bodyLarge),
                        Expanded(child: Text(item.productName, style: Theme.of(context).textTheme.bodyLarge)),
                        Text('\$${item.lineTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleMedium),
                    Text('\$${order.grandTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text('Order Status', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: AppSpacing.sm),
          if (isCancelled)
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  const Expanded(child: Text('This order was cancelled.', style: TextStyle(color: AppColors.error))),
                ],
              ),
            )
          else
            for (int i = 0; i < _fullFlow.length; i++)
              _TimelineStep(
                status: _fullFlow[i],
                timestamp: order.statusTimeline
                    .where((e) => e.status == _fullFlow[i])
                    .map((e) => e.timestamp)
                    .cast<DateTime?>()
                    .firstWhere((_) => true, orElse: () => null),
                isCompleted: completedStatuses.contains(_fullFlow[i]),
                isLast: i == _fullFlow.length - 1,
              ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isLast;

  const _TimelineStep({
    required this.status,
    required this.timestamp,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.success : AppColors.textMuted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: color,
                size: 22,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: isCompleted ? AppColors.success : AppColors.border)),
            ],
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                  if (timestamp != null)
                    Text(DateFormat('MMM d, h:mm a').format(timestamp!), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
