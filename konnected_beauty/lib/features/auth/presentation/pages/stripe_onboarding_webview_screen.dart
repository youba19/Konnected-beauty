import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/stripe_service.dart';

class StripeOnboardingWebViewScreen extends StatefulWidget {
  final String onboardingUrl;
  final String? accountId;
  final Function()? onSuccess;
  final Function()? onFailure;

  const StripeOnboardingWebViewScreen({
    super.key,
    required this.onboardingUrl,
    this.accountId,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<StripeOnboardingWebViewScreen> createState() =>
      _StripeOnboardingWebViewScreenState();
}

class _StripeOnboardingWebViewScreenState
    extends State<StripeOnboardingWebViewScreen> {
  bool _isLoading = true;
  bool _hasDetectedSuccess = false;
  bool _isHandlingRefresh = false;
  double _progress = 0;
  InAppWebViewController? _webViewController;

  // URL patterns
  static const String successUrlPattern = 'konectedbeauty.com/stripe/success';
  static const String refreshUrlPattern = 'konectedbeauty.com/stripe/refresh';

  @override
  void initState() {
    super.initState();
    print('🌐 Initializing Stripe Onboarding WebView');
    print('🔗 Onboarding URL: ${widget.onboardingUrl}');
    print('🆔 Account ID: ${widget.accountId}');
  }

  Future<void> _handleSuccessUrl(String url) async {
    if (_hasDetectedSuccess) return;
    _hasDetectedSuccess = true;

    print('✅ Success URL detected: $url');
    print('🔄 Verifying Stripe account status with backend...');

    // Verify account status with backend first
    try {
      final result = await StripeService.verifyAccountStatus();

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final isOnboarded = data?['isOnboarded'] as bool? ?? false;

        if (isOnboarded) {
          print('✅ Stripe account verified as onboarded');
          // Close WebView and call success callback
          if (mounted && Navigator.of(context, rootNavigator: false).canPop()) {
            Navigator.of(context).pop();
            // Call success callback after navigation completes
            Future.delayed(const Duration(milliseconds: 300), () {
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              }
            });
          }
        } else {
          print('⚠️ Stripe account not fully onboarded');
          // Close WebView and call failure callback
          if (mounted && Navigator.of(context, rootNavigator: false).canPop()) {
            Navigator.of(context).pop();
            // Call failure callback after navigation completes
            Future.delayed(const Duration(milliseconds: 300), () {
              if (widget.onFailure != null) {
                widget.onFailure!();
              } else {
                _showError(
                    'Stripe onboarding not completed. Please try again.');
              }
            });
          }
        }
      } else {
        print('❌ Failed to verify Stripe account: ${result['message']}');
        // Close WebView and call failure callback
        if (mounted && Navigator.of(context, rootNavigator: false).canPop()) {
          Navigator.of(context).pop();
          // Call failure callback after navigation completes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (widget.onFailure != null) {
              widget.onFailure!();
            } else {
              _showError(
                  result['message'] ?? 'Failed to verify Stripe account');
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error verifying account: $e');
      // Close WebView and call failure callback
      if (mounted && Navigator.of(context, rootNavigator: false).canPop()) {
        Navigator.of(context).pop();
        // Call failure callback after navigation completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (widget.onFailure != null) {
            widget.onFailure!();
          } else {
            _showError('Error verifying account: ${e.toString()}');
          }
        });
      }
    }
  }

  Future<void> _handleRefreshUrl(String url) async {
    if (_isHandlingRefresh) return;
    _isHandlingRefresh = true;

    print('🔄 Refresh URL detected: $url');
    print('🔄 Connection failed, creating new onboarding link from backend...');

    try {
      // Create new onboarding link (not login link) since connection failed
      final result = await StripeService.createOnboardingLink();

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        // Onboarding link uses 'onboardingUrl', login link uses 'loginUrl'
        final onboardingUrl = data?['onboardingUrl'] as String?;

        if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
          print('✅ New onboarding link received: $onboardingUrl');
          // Redirect WebView to the new onboarding link
          if (mounted && _webViewController != null) {
            await _webViewController!.loadUrl(
              urlRequest: URLRequest(url: WebUri(onboardingUrl)),
            );
          }
        } else {
          print('❌ No onboarding URL in response');
          _showError('Failed to get new onboarding link. Please try again.');
        }
      } else {
        print('❌ Failed to create onboarding link: ${result['message']}');
        final errorMessage =
            result['message'] ?? 'Failed to create new onboarding link';
        final statusCode = result['statusCode'] as int?;

        // Handle 409 Conflict - Profile not completed
        if (statusCode == 409) {
          _showError(
              'Please complete your salon profile first before setting up Stripe payment.');
          // Close WebView after showing error - DO NOT call onFailure to avoid skipping onboarding
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted &&
                Navigator.of(context, rootNavigator: false).canPop()) {
              Navigator.of(context).pop();
              // Don't call onFailure() - just close the WebView so user can go back to complete profile
              // The user should return to the previous step to complete their profile
            }
          });
        } else {
          _showError(errorMessage);
          // For other errors, also close WebView but don't call callbacks
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted &&
                Navigator.of(context, rootNavigator: false).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error creating onboarding link: $e');
      _showError('Error creating new onboarding link: ${e.toString()}');
    } finally {
      _isHandlingRefresh = false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(
        Theme.of(context).brightness,
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.getScaffoldBackground(
          Theme.of(context).brightness,
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppTranslations.getString(context, 'stripe_payment_setup'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.onboardingUrl),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (controller) {
              print('✅ WebView created');
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              print('🌐 Loading started: $url');

              final urlString = url.toString();

              // Check if this is the success URL
              if (urlString.contains(successUrlPattern)) {
                // Prevent loading the success URL in the WebView
                controller.stopLoading();
                _handleSuccessUrl(urlString);
                return;
              }

              // Check if this is the refresh URL (connection failed)
              if (urlString.contains(refreshUrlPattern)) {
                // Stop loading and get a new login link
                controller.stopLoading();
                _handleRefreshUrl(urlString);
                return;
              }

              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              print('🌐 Loading finished: $url');

              final urlString = url.toString();

              // Check if this is the success URL
              if (urlString.contains(successUrlPattern)) {
                // Don't show the success page in the WebView
                _handleSuccessUrl(urlString);
                return;
              }

              // Check if this is the refresh URL (connection failed)
              if (urlString.contains(refreshUrlPattern)) {
                // Get a new login link
                _handleRefreshUrl(urlString);
                return;
              }

              setState(() {
                _isLoading = false;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              print('🔗 Navigation request: $url');

              // Intercept the success URL
              if (url.contains(successUrlPattern)) {
                print(
                    '✅ Intercepting success URL, preventing WebView navigation');
                _handleSuccessUrl(url);
                return NavigationActionPolicy.CANCEL;
              }

              // Intercept the refresh URL (connection failed) and get new link
              if (url.contains(refreshUrlPattern)) {
                print('🔄 Intercepting refresh URL, getting new login link');
                _handleRefreshUrl(url);
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              print('❌ WebView error: ${error.description}');
              setState(() {
                _isLoading = false;
              });
            },
            onReceivedHttpError: (controller, request, response) {
              print('❌ HTTP error: ${response.statusCode}');
            },
          ),
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF3B3B3B),
                    const Color(0xFF1F1E1E),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stripe logo or loading indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Shadow/background "S"
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textSecondaryColor.withOpacity(0.1),
                            letterSpacing: -3,
                          ),
                        ),
                        // Main "S" with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: 0.3 + (value * 0.7),
                              child: Text(
                                '',
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w300,
                                  color: AppTheme.textPrimaryColor,
                                  letterSpacing: -3,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Loading indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.greenPrimary,
                        ),
                        backgroundColor: AppTheme.borderColorGray,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Loading text
                    Text(
                      'Loading Stripe onboarding...',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we connect your account',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_progress > 0) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progress,
                              minHeight: 4,
                              backgroundColor: AppTheme.borderColorGray,
                              borderRadius: BorderRadius.circular(2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.greenPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
