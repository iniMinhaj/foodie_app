import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

/// TODO: Riverpod - the 1.5s Future.delayed here is where a real app would
/// instead await an `authStateProvider` (e.g. from Firebase) to decide
/// whether to route to Login or Home directly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 44),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Foodie',
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            SizedBox(height: 4.h),
            Text(
              'Delicious, delivered fast',
              style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
