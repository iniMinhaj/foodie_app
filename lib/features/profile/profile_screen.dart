import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/state_views.dart';
import '../../legacy/models/user_profile_model.dart';
import '../../legacy/utils/mock_data_loader.dart';
import '../auth/presentation/screens/login_screen.dart';

/// TODO: Riverpod - `profileAsync` becomes `ref.watch(userProfileProvider)`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final json = await MockDataLoader.instance.getUserProfile();
      final profile =
          UserProfileModel.fromJson(json['data'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _hasError
          ? ErrorStateView(
              message: 'Could not load your profile.', onRetry: _loadProfile)
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(_profile!),
    );
  }

  Widget _buildContent(UserProfileModel profile) {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            ClipOval(
                child: AppImage(
                    url: profile.avatarUrl, width: 64.w, height: 64.w)),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(profile.email,
                      style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 2.w),
                      Text('${profile.loyaltyPoints} loyalty points',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Text('Saved Addresses', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppSpacing.sm),
        for (final address in profile.addresses)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
                address.isDefault
                    ? Icons.home_rounded
                    : Icons.location_on_outlined,
                color: AppColors.primary),
            title: Text(address.label),
            subtitle: Text(address.line1),
          ),
        SizedBox(height: AppSpacing.lg),
        Text('Settings', style: Theme.of(context).textTheme.titleMedium),
        _SettingsTile(
            icon: Icons.notifications_outlined, label: 'Notifications'),
        _SettingsTile(icon: Icons.payment_outlined, label: 'Payment Methods'),
        _SettingsTile(
            icon: Icons.help_outline_rounded, label: 'Help & Support'),
        SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          child: const Text('Log Out'),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SettingsTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () {},
    );
  }
}
