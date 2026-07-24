import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

/// UI-only auth screen. Deliberately NOT wired to Firebase here - per the
/// project plan, auth is handled separately. This screen just needs to
/// demonstrate form validation + loading state, matching the shape any
/// real auth call (Firebase or REST) will plug into.
///
/// TODO: Riverpod - `_isSubmitting` + the `Future.delayed` below becomes
/// an `AuthNotifier.signIn()` call wrapped in AsyncValue.guard, with the
/// button's onPressed calling `ref.read(authProvider.notifier).signIn(...)`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    // Placeholder for a real auth call (Firebase Auth / REST).
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.lg)),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 32),
                ),
                SizedBox(height: AppSpacing.lg),
                Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 4.h),
                Text('Sign in to continue ordering', style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: AppSpacing.xl),
                Text('Email', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                ),
                SizedBox(height: AppSpacing.md),
                Text('Password', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?'),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onLoginPressed,
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Sign In'),
                ),
                SizedBox(height: AppSpacing.lg),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(text: 'Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
