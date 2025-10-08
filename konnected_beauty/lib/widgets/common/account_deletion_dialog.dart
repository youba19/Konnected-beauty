import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/translations/app_translations.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_bloc.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_event.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_state.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_bloc.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_event.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_state.dart';
import '../../core/theme/app_theme.dart';
import 'top_notification_banner.dart';

class AccountDeletionDialog extends StatefulWidget {
  final String userType; // 'salon' or 'influencer'

  const AccountDeletionDialog({
    super.key,
    required this.userType,
  });

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitDeletionRequest() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message:
            AppTranslations.getString(context, 'account_deletion_required'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    if (widget.userType == 'salon') {
      context.read<SalonAccountDeletionBloc>().add(
            RequestSalonAccountDeletion(reason: reason),
          );
    } else {
      context.read<InfluencerAccountDeletionBloc>().add(
            RequestInfluencerAccountDeletion(reason: reason),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppTranslations.getString(context, 'account_deletion'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppTranslations.getString(
                          context, 'account_deletion_warning'),
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reason input
            Text(
              AppTranslations.getString(context, 'account_deletion_reason'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppTranslations.getString(
                    context, 'account_deletion_placeholder'),
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppTranslations.getString(
                          context, 'account_deletion_cancel'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSubmitButton(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    if (widget.userType == 'salon') {
      return BlocListener<SalonAccountDeletionBloc, SalonAccountDeletionState>(
        listener: (context, state) {
          if (state is SalonAccountDeletionSuccess) {
            setState(() {
              _isSubmitting = false;
            });
            Navigator.of(context).pop();
            TopNotificationService.showSuccess(
              context: context,
              message: state.message,
            );
          } else if (state is SalonAccountDeletionError) {
            setState(() {
              _isSubmitting = false;
            });
            TopNotificationService.showError(
              context: context,
              message: state.message,
            );
          }
        },
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitDeletionRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  AppTranslations.getString(
                      context, 'account_deletion_confirm'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      );
    } else {
      return BlocListener<InfluencerAccountDeletionBloc,
          InfluencerAccountDeletionState>(
        listener: (context, state) {
          if (state is InfluencerAccountDeletionSuccess) {
            setState(() {
              _isSubmitting = false;
            });
            Navigator.of(context).pop();
            TopNotificationService.showSuccess(
              context: context,
              message: state.message,
            );
          } else if (state is InfluencerAccountDeletionError) {
            setState(() {
              _isSubmitting = false;
            });
            TopNotificationService.showError(
              context: context,
              message: state.message,
            );
          }
        },
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitDeletionRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  AppTranslations.getString(
                      context, 'account_deletion_confirm'),
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      );
    }
  }
}
