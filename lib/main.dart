import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const FoodieApp());
}

class FoodieApp extends StatelessWidget {
  const FoodieApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Design size matches a standard 375x812 (iPhone X-class) frame -
    // flutter_screenutil scales every .w/.h/.sp/.r call in the app
    // relative to this baseline, which is how the "screen util for
    // responsive design" requirement gets satisfied.
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Foodie',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
