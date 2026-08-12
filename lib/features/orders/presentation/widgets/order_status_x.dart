import 'package:flutter/material.dart';

import '../../../../core/entities/order.dart';
import '../../../../core/theme/app_theme.dart';

/// UI label/color for [OrderStatus] — kept off the entity itself, same
/// reasoning `PaymentMethodType`'s icon mapping lives in `profile_screen.dart`
/// rather than on the entity. Shared by the history card's status chip and
/// the tracking screen's timeline steps.
extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.placed => 'Order Placed',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  Color get color => switch (this) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.outForDelivery => AppColors.primary,
        _ => AppColors.warning,
      };
}
