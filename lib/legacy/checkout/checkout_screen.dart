import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../utils/cart_service.dart';

/// TODO: Riverpod - `_selectedAddressIndex`/`_selectedPaymentIndex`/
/// `_isPlacingOrder` become fields on a `CheckoutState`, driven by a
/// `CheckoutNotifier`. `_placeOrder`'s try/simulate-delay/catch shape is
/// exactly what an AsyncNotifier's `build()` + a manual `state =
/// AsyncLoading()` pattern looks like once wired to a real order-placement
/// repository call.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedAddressIndex = 0;
  int _selectedPaymentIndex = 0;
  bool _isPlacingOrder = false;

  final _addresses = const [
    ('Home', 'House 22, Road 5, Dhanmondi, Dhaka'),
    ('Office', 'Level 6, Bashundhara City, Panthapath'),
  ];

  final _paymentMethods = const [
    ('Cash on Delivery', Icons.money_rounded),
    ('Card (•••• 4242)', Icons.credit_card_rounded),
    ('bKash', Icons.account_balance_wallet_rounded),
  ];

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);
    // Simulates the round trip to a payment/order API.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    CartService.instance.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 56),
            SizedBox(height: AppSpacing.md),
            Text('Order Placed!',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Your order has been confirmed and is being prepared.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = CartService.instance.subtotal + 1.99 + 0.5;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Delivery Address',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < _addresses.length; i++)
            _SelectableTile(
              icon: Icons.location_on_outlined,
              title: _addresses[i].$1,
              subtitle: _addresses[i].$2,
              isSelected: _selectedAddressIndex == i,
              onTap: () => setState(() => _selectedAddressIndex = i),
            ),
          SizedBox(height: AppSpacing.lg),
          Text('Payment Method',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < _paymentMethods.length; i++)
            _SelectableTile(
              icon: _paymentMethods[i].$2,
              title: _paymentMethods[i].$1,
              isSelected: _selectedPaymentIndex == i,
              onTap: () => setState(() => _selectedPaymentIndex = i),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            child: _isPlacingOrder
                ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text('Place Order • \$${total.toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
