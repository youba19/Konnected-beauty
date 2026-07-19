import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/translations/app_translations.dart';
import '../../core/theme/salon_ui_theme.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_bloc.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_event.dart';
import '../../core/bloc/salon_account_deletion/salon_account_deletion_state.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_bloc.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_event.dart';
import '../../core/bloc/influencer_account_deletion/influencer_account_deletion_state.dart';
import 'top_notification_banner.dart';

abstract final class _AccountDeletionUi {
  static const double radius = 16;
}

class AccountDeletionDialog extends StatefulWidget {
  final String userType; // 'salon' or 'influencer'

  const AccountDeletionDialog({
    super.key,
    required this.userType,
  });

  static Future<void> show(
    BuildContext context, {
    required String userType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (userType == 'salon') {
          return BlocProvider(
            create: (_) => SalonAccountDeletionBloc(),
            child: const AccountDeletionDialog(userType: 'salon'),
          );
        }
        return BlocProvider(
          create: (_) => InfluencerAccountDeletionBloc(),
          child: const AccountDeletionDialog(userType: 'influencer'),
        );
      },
    );
  }

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
    // Light sheet + black text keeps labels readable on the blue header.
    final ui = SalonUiTheme.from(Brightness.light);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: ui.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ui.sheetHeaderGradient,
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.getString(context, 'account_deletion'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.getString(
                              context,
                              'account_deletion_warning',
                            ),
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            AppTranslations.getString(
                              context,
                              'account_deletion_reason',
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _reasonController,
                            maxLines: 4,
                            maxLength: 500,
                            enabled: !_isSubmitting,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              hintText: AppTranslations.getString(
                                context,
                                'account_deletion_placeholder',
                              ),
                              hintStyle: TextStyle(
                                color: Colors.black.withValues(alpha: 0.4),
                                fontSize: 15,
                              ),
                              counterStyle: TextStyle(
                                color: Colors.black.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.all(14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _AccountDeletionUi.radius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _AccountDeletionUi.radius,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1.2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  _AccountDeletionUi.radius,
                                ),
                                borderSide: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: _buildSubmitButton(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            _AccountDeletionUi.radius,
                          ),
                        ),
                      ),
                      child: Text(
                        AppTranslations.getString(
                          context,
                          'account_deletion_cancel',
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final label = Text(
      AppTranslations.getString(context, 'account_deletion_confirm'),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );

    final button = ElevatedButton(
      onPressed: _isSubmitting ? null : _submitDeletionRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        disabledBackgroundColor: Colors.white70,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_AccountDeletionUi.radius),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : label,
    );

    if (widget.userType == 'salon') {
      return BlocListener<SalonAccountDeletionBloc, SalonAccountDeletionState>(
        listener: (context, state) {
          if (state is SalonAccountDeletionSuccess) {
            setState(() => _isSubmitting = false);
            TopNotificationService.showSuccess(
              context: context,
              message: state.message,
            );
            Navigator.of(context).pop();
          } else if (state is SalonAccountDeletionError) {
            setState(() => _isSubmitting = false);
            TopNotificationService.showError(
              context: context,
              message: state.message,
            );
          }
        },
        child: button,
      );
    }

    return BlocListener<InfluencerAccountDeletionBloc,
        InfluencerAccountDeletionState>(
      listener: (context, state) {
        if (state is InfluencerAccountDeletionSuccess) {
          setState(() => _isSubmitting = false);
          TopNotificationService.showSuccess(
            context: context,
            message: state.message,
          );
          Navigator.of(context).pop();
        } else if (state is InfluencerAccountDeletionError) {
          setState(() => _isSubmitting = false);
          TopNotificationService.showError(
            context: context,
            message: state.message,
          );
        }
      },
      child: button,
    );
  }
}
