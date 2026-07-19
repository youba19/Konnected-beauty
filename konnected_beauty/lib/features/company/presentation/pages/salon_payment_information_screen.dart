import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../auth/presentation/pages/stripe_onboarding_webview_screen.dart';

abstract final class _SalonPaymentUi {
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class SalonPaymentInformationScreen extends StatefulWidget {
  const SalonPaymentInformationScreen({super.key});

  @override
  State<SalonPaymentInformationScreen> createState() =>
      _SalonPaymentInformationScreenState();
}

class _SalonPaymentInformationScreenState
    extends State<SalonPaymentInformationScreen> {
  bool _isLoading = false;

  Future<void> _startStripeExpressOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('💳 Salon payment info: creating Stripe Express onboarding link...');
      final result = await StripeService.createOnboardingLink();

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final onboardingUrl = data?['onboardingUrl'] as String?;
        final accountId = data?['accountId'] as String?;

        if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
          final parentContext = context;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (ctx) => StripeOnboardingWebViewScreen(
                onboardingUrl: onboardingUrl,
                accountId: accountId,
                onSuccess: () {
                  if (!parentContext.mounted) return;
                  TopNotificationService.showSuccess(
                    context: parentContext,
                    message: AppTranslations.getString(
                      parentContext,
                      'stripe_setup_complete_success',
                    ),
                  );
                },
                onFailure: () {
                  if (!parentContext.mounted) return;
                  TopNotificationService.showError(
                    context: parentContext,
                    message: AppTranslations.getString(
                      parentContext,
                      'stripe_onboarding_incomplete',
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          TopNotificationService.showError(
            context: context,
            message: AppTranslations.getString(
              context,
              'stripe_onboarding_link_missing',
            ),
          );
        }
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message']?.toString() ??
              AppTranslations.getString(
                context,
                'stripe_onboarding_link_missing',
              ),
        );
      }
    } catch (e) {
      print('❌ Error starting Stripe onboarding: $e');
      if (mounted) {
        TopNotificationService.showError(
          context: context,
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: Scaffold(
            backgroundColor: ui.bg,
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.fullSheetGradient,
                        stops: ui.fullSheetStops,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(ui),
                        const SizedBox(height: 22),
                        _buildContent(ui),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stripe',
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'stripe_onboarding_description'),
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildStripeButton(ui),
        ],
      ),
    );
  }

  Widget _buildHeader(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: _SalonPaymentUi.buttonSize,
            height: _SalonPaymentUi.buttonSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ui.buttonFillTop,
                  ui.buttonFillBottom,
                ],
              ),
              borderRadius: BorderRadius.circular(_SalonPaymentUi.buttonRadius),
              border: ui.isDark
                  ? null
                  : Border.all(color: ui.cardBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.arrowLeft,
              color: ui.buttonIcon,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Icon(
              LucideIcons.wallet,
              color: ui.textPrimary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              AppTranslations.getString(context, 'payment_information'),
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStripeButton(SalonUiTheme ui) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startStripeExpressOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.primaryButtonBg,
          foregroundColor: ui.primaryButtonFg,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ui.primaryButtonFg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: ui.primaryButtonBg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isLoading
                  ? AppTranslations.getString(context, 'loading')
                  : AppTranslations.getString(context, 'connect_with_stripe'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isLoading) ...[
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: ui.primaryButtonFg,
                  strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
