import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/entities/address.dart';
import '../../../../core/entities/payment_method.dart';
import '../../../../core/network/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/profile_notifier.dart';
import '../widgets/address_form_sheet.dart';
import '../widgets/edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        error: (error, stackTrace) => ErrorStateView(
          message: error is Failure ? error.userMessage : 'Could not load your profile.',
          onRetry: () => ref.invalidate(profileNotifierProvider),
        ),
        data: (state) => _ProfileBody(state: state),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final ProfileState state;
  const _ProfileBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(profileNotifierProvider),
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          if (state.errorMessage != null) ...[
            _ErrorBanner(message: state.errorMessage!),
            SizedBox(height: AppSpacing.md),
          ],
          _ProfileHeader(profile: profile),
          SizedBox(height: AppSpacing.lg),
          _SectionTitle(
            title: 'Saved Addresses',
            actionLabel: 'Add',
            onActionTap: () => showAddressFormSheet(context),
          ),
          if (profile.addresses.isEmpty)
            const _EmptyRow(message: 'No saved addresses yet.')
          else
            for (final address in profile.addresses) _AddressTile(address: address),
          SizedBox(height: AppSpacing.lg),
          const _SectionTitle(title: 'Payment Methods'),
          if (profile.paymentMethods.isEmpty)
            const _EmptyRow(message: 'No payment methods on file.')
          else
            for (final method in profile.paymentMethods) _PaymentMethodTile(method: method),
          SizedBox(height: AppSpacing.lg),
          const _SectionTitle(title: 'Settings'),
          _SettingsTile(
            icon: Icons.restart_alt_rounded,
            label: 'Reset Demo Data',
            onTap: () => _confirmResetDemoData(context, ref),
          ),
          SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetDemoData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Reset demo data?'),
        content: const Text(
          'This restores every mock file to its original state and signs you out. '
          'Any changes you made — including any account you registered — will be lost.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref.read(profileNotifierProvider.notifier).resetDemoData();
    if (!success) return;

    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(child: AppImage(url: profile.avatarUrl, width: 64.w, height: 64.w)),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
              if (profile.phone.isNotEmpty) Text(profile.phone, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 4.h),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                  SizedBox(width: 2.w),
                  Text('${profile.loyaltyPoints} loyalty points', style: Theme.of(context).textTheme.bodySmall),
                  if (profile.memberSince != null) ...[
                    Text(' • ', style: Theme.of(context).textTheme.bodySmall),
                    Flexible(
                      child: Text(
                        'Member since ${DateFormat('MMM yyyy').format(profile.memberSince!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          tooltip: 'Edit profile',
          onPressed: () => showEditProfileSheet(context, profile),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  const _SectionTitle({required this.title, this.actionLabel, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  final Address address;
  const _AddressTile({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            address.isDefault ? Icons.home_rounded : Icons.location_on_outlined,
            color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label, style: Theme.of(context).textTheme.titleMedium),
                    if (address.isDefault) ...[
                      SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('${address.line1}, ${address.city}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            onSelected: (value) => _onSelected(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (!address.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as default')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSelected(BuildContext context, WidgetRef ref, String value) async {
    final notifier = ref.read(profileNotifierProvider.notifier);
    switch (value) {
      case 'edit':
        await showAddressFormSheet(context, existing: address);
      case 'default':
        await notifier.setDefaultAddress(address.id);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: const Text('Delete this address?'),
            content: Text('"${address.label}" will be removed from your saved addresses.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirmed == true) await notifier.removeAddress(address.id);
    }
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  const _PaymentMethodTile({required this.method});

  IconData get _icon => switch (method.type) {
        PaymentMethodType.card => Icons.credit_card_rounded,
        PaymentMethodType.wallet => Icons.account_balance_wallet_rounded,
        PaymentMethodType.cod => Icons.money_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon, color: AppColors.textSecondary),
      title: Text(method.label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: method.isDefault
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Default',
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            )
          : null,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
