import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../auth/presentation/pages/stripe_onboarding_webview_screen.dart';

class PaymentInformationScreen extends StatefulWidget {
  const PaymentInformationScreen({super.key});

  @override
  State<PaymentInformationScreen> createState() =>
      _PaymentInformationScreenState();
}

class _PaymentInformationScreenState extends State<PaymentInformationScreen> {
  bool _isLoading = false;

  /// Same flow as influencer registration Stripe step: POST /stripe/express/onboard + in-app WebView.
  Future<void> _startStripeExpressOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('💳 Payment info: creating Stripe Express onboarding link...');
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
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      AppTheme.greenPrimary.withOpacity(0.35),
                      brightness == Brightness.dark
                          ? AppTheme.transparentBackground
                          : AppTheme.textWhite54,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // CONTENT
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stripe label
          Text(
            'Stripe',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextPrimaryColor
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'stripe_onboarding_description'),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextSecondaryColor
                  : AppTheme.textSecondaryColor,
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
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextPrimaryColor
                  : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 20,
            ),
          ),

          const SizedBox(height: 16),

          // Title with Icon
          Row(
            children: [
              Icon(
                LucideIcons.wallet,
                color: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.lightTextPrimaryColor
                    : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.getString(context, 'payment_information'),
                style: AppTheme.headingStyle.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
    final brightness = Theme.of(context).brightness;
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
            side: BorderSide(
              color: brightness == Brightness.light
                  ? AppTheme.lightTextPrimaryColor
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Stripe "S" logo
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
