import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_loader.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/shimmer_placeholders.dart';
import '../../core/widgets/state_views.dart';
import '../../models/order_model.dart';
import 'order_tracking_screen.dart';

/// TODO: Riverpod - `ordersAsync` becomes `ref.watch(ordersProvider)`
/// (a FutureProvider). Delete _isLoading/_hasError/_orders fields.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final json = await MockDataLoader.instance.getOrders();
      final orders = (json['data'] as List<dynamic>)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _hasError
          ? ErrorStateView(message: 'Could not load your orders.', onRetry: _loadOrders)
          : _isLoading
              ? ListView(
                  padding: EdgeInsets.all(AppSpacing.md),
                  children: List.generate(4, (_) => const ProductCardSkeleton()),
                )
              : _orders.isEmpty
                  ? EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message: 'Your order history will show up here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.md),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _OrderCard(order: _orders[index]),
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.outForDelivery:
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

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
                  Text('${order.items.length} item(s) • \$${order.grandTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _statusColor(order.currentStatus).withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                order.currentStatus.label,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: _statusColor(order.currentStatus)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
