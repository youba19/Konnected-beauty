import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

class SalonPaymentInformationScreen extends StatefulWidget {
  const SalonPaymentInformationScreen({super.key});

  @override
  State<SalonPaymentInformationScreen> createState() =>
      _SalonPaymentInformationScreenState();
}

class _SalonPaymentInformationScreenState
    extends State<SalonPaymentInformationScreen> {
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
          // Stripe label
          Text(
            'Stripe',
            style: TextStyle(
              color: Colors.white,
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
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(height: 16),

          // Title with Icon
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
        onPressed: _isLoading ? null : _openStripeDashboard,
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
