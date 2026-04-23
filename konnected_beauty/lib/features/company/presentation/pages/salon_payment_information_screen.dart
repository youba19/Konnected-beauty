import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../auth/presentation/pages/stripe_onboarding_webview_screen.dart';

class SalonPaymentInformationScreen extends StatefulWidget {
  const SalonPaymentInformationScreen({super.key});

  @override
  State<SalonPaymentInformationScreen> createState() =>
      _SalonPaymentInformationScreenState();
}

class _SalonPaymentInformationScreenState
    extends State<SalonPaymentInformationScreen> {
  bool _isLoading = false;

  /// Same flow as influencer payment info: POST /stripe/express/onboard + in-app WebView.
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF1F1E1E),
            Color(0xFF3B3B3B),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stripe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'stripe_onboarding_description'),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildStripeButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                LucideIcons.wallet,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.getString(context, 'payment_information'),
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStripeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startStripeExpressOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            if (_isLoading) ...[
              const Spacer(),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.black,
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
