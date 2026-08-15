import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/entities/address.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_notifier.dart';

const _uuid = Uuid();

/// Pass [existing] to edit an address in place; omit it to add a new one.
Future<void> showAddressFormSheet(BuildContext context, {Address? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddressFormSheet(existing: existing),
  );
}

class AddressFormSheet extends ConsumerStatefulWidget {
  final Address? existing;
  const AddressFormSheet({super.key, this.existing});

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController = TextEditingController(text: widget.existing?.label);
  late final _line1Controller = TextEditingController(text: widget.existing?.line1);
  late final _cityController = TextEditingController(text: widget.existing?.city);
  late bool _isDefault = widget.existing?.isDefault ?? false;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final address = Address(
      id: widget.existing?.id ?? _uuid.v4(),
      label: _labelController.text.trim(),
      line1: _line1Controller.text.trim(),
      city: _cityController.text.trim(),
      isDefault: _isDefault,
    );

    final notifier = ref.read(profileNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updateAddress(address);
    } else {
      await notifier.addAddress(address);
    }

    if (!mounted) return;

    // addAddress/updateAddress persist via the same optimistic-update +
    // rollback-with-errorMessage shape as every other ProfileNotifier
    // mutation — a failed save rolls the state back and sets errorMessage
    // instead of throwing, so it has to be checked here rather than caught.
    final errorMessage = ref.read(profileNotifierProvider).value?.errorMessage;
    if (errorMessage != null) {
      setState(() {
        _isSaving = false;
        _errorMessage = errorMessage;
      });
      return;
    }

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
              Text(_isEditing ? 'Edit Address' : 'Add Address', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: AppSpacing.md),
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                SizedBox(height: AppSpacing.md),
              ],
              Text('Label', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _labelController,
                validator: _required,
                decoration: const InputDecoration(hintText: 'Home, Office, ...'),
              ),
              SizedBox(height: AppSpacing.md),
              Text('Address', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(controller: _line1Controller, validator: _required),
              SizedBox(height: AppSpacing.md),
              Text('City', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppSpacing.sm),
              TextFormField(controller: _cityController, validator: _required),
              SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as default address'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeTrackColor: AppColors.primary,
              ),
              SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                child: _isSaving
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Save Changes' : 'Add Address'),
              ),
            ],
          ),
        ),
      ),
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
