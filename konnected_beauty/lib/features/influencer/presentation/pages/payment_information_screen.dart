import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class PaymentInformationScreen extends StatefulWidget {
  const PaymentInformationScreen({super.key});

  @override
  State<PaymentInformationScreen> createState() =>
      _PaymentInformationScreenState();
}

class _PaymentInformationScreenState extends State<PaymentInformationScreen> {
  bool _isLoading = false;


  Future<void> _openStripeDashboard() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('💳 Opening Stripe dashboard...');
      final result = await StripeService.getLoginLink();

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final loginUrl = data?['loginUrl'] as String?;

        if (loginUrl != null && loginUrl.isNotEmpty) {
          print('🌐 Opening Stripe dashboard URL: $loginUrl');
          final uri = Uri.parse(loginUrl);
          
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            print('❌ Cannot launch URL: $loginUrl');
            TopNotificationService.showError(
              context: context,
              message: 'Cannot open Stripe dashboard',
            );
          }
        } else {
          print('❌ No login URL in response');
          TopNotificationService.showError(
            context: context,
            message: 'Stripe dashboard link not available',
          );
        }
      } else {
        print('❌ Failed to get Stripe login link: ${result['message']}');
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to open Stripe dashboard',
        );
      }
    } catch (e) {
      print('❌ Error opening Stripe dashboard: $e');
      TopNotificationService.showError(
        context: context,
        message: 'Error opening Stripe dashboard: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          const SizedBox(height: 16),
          // Open Stripe dashboard button
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
        onPressed: _isLoading ? null : _openStripeDashboard,
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
            // Button text
            Text(
              _isLoading ? 'Loading...' : 'Open Stripe dashboard',
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
