import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../providers/profile_notifier.dart';

Future<void> showEditProfileSheet(BuildContext context, UserProfile profile) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditProfileSheet(profile: profile),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const EditProfileSheet({super.key, required this.profile});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _phoneController = TextEditingController(text: widget.profile.phone);
  late final _avatarController = TextEditingController(text: widget.profile.avatarUrl);
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    return null;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(profileNotifierProvider.notifier).updateDetails(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          avatarUrl: _avatarController.text.trim(),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: AppSpacing.md),
              Text('Full name', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(controller: _nameController, validator: _validateName),
              SizedBox(height: AppSpacing.md),
              Text('Phone', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone),
              SizedBox(height: AppSpacing.md),
              Text('Avatar URL', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(controller: _avatarController, keyboardType: TextInputType.url),
              SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                child: _isSaving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
