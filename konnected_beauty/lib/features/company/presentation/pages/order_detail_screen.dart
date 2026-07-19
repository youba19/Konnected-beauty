import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/qr_scan_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'qr_scanner_screen.dart';

abstract final class _OrderDetailUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
  static const double horizontalPadding = 16;
}

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Map<String, dynamic> get _data => _orderDetails ?? widget.order;

  Map<String, dynamic> get _clientInfo {
    final info = _data['clientInfo'];
    if (info is Map<String, dynamic>) return info;
    if (info is Map) return Map<String, dynamic>.from(info);
    return {};
  }

  Map<String, dynamic> get _influencerProfile {
    final campaign = _data['campaign'];
    final influencer = campaign is Map ? campaign['influencer'] : null;
    final profile = influencer is Map ? influencer['profile'] : null;
    if (profile is Map<String, dynamic>) return profile;
    if (profile is Map) return Map<String, dynamic>.from(profile);

    final fallback = widget.order['influencer'];
    final fallbackProfile = fallback is Map ? fallback['profile'] : null;
    if (fallbackProfile is Map<String, dynamic>) return fallbackProfile;
    if (fallbackProfile is Map) return Map<String, dynamic>.from(fallbackProfile);
    return {};
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final orderId = widget.order['id'] ?? widget.order['_id'];
      if (orderId == null || orderId.toString().isEmpty) {
        throw Exception('Order ID not found');
      }

      final result = await QRScanService.getOrderDetails(orderId.toString());

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _orderDetails = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to fetch order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading order details: $e';
        _isLoading = false;
      });
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
          child: ColoredBox(
            color: ui.bg,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton(
                onPressed: _openQrScanner,
                backgroundColor: ui.fabBg,
                elevation: 4,
                shape: CircleBorder(
                  side: BorderSide(color: ui.fabBorder, width: 1),
                ),
                child: Icon(
                  LucideIcons.scanLine,
                  color: ui.isDark ? Colors.white : Colors.black,
                  size: 24,
                ),
              ),
              body: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: topInset + 180,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: ui.headerGradient,
                          stops: ui.headerStops,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: _isLoading
                        ? Padding(
                            padding: EdgeInsets.only(top: topInset),
                            child: _buildLoadingContent(ui),
                          )
                        : _hasError
                            ? Padding(
                                padding: EdgeInsets.only(top: topInset),
                                child: _buildErrorContent(ui),
                              )
                            : SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  _OrderDetailUi.horizontalPadding,
                                  topInset + 8,
                                  _OrderDetailUi.horizontalPadding,
                                  110,
                                ),
                                child: _buildContent(ui),
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openQrScanner() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
      );
      return;
    }

    final result = await Permission.camera.request();
    if (!mounted) return;
    if (result.isGranted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
      );
    } else {
      TopNotificationService.showError(
        context: context,
        message: 'Camera permission is required to scan QR codes',
      );
    }
  }

  Widget _buildLoadingContent(SalonUiTheme ui) {
    return Shimmer.fromColors(
      baseColor: ui.isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: ui.isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 28,
              width: 220,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(SalonUiTheme ui) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: ui.isDark ? Colors.white54 : Colors.black, size: 56),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(color: ui.isDark ? Colors.white70 : Colors.black, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: ui.primaryButtonBg,
                foregroundColor: ui.primaryButtonFg,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SalonUiTheme ui) {
    final clientName = _clientInfo['name']?.toString() ?? 'Unknown Client';
    final email = _clientInfo['email']?.toString() ?? '';
    final phone = _clientInfo['phoneNumber']?.toString() ??
        _clientInfo['phone']?.toString() ??
        '';
    final dateRaw = _data['updatedAt'] ??
        _data['createdAt'] ??
        widget.order['updatedAt'] ??
        widget.order['createdAt'] ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(ui),
        const SizedBox(height: 18),
        Text(
          '${AppTranslations.getString(context, 'order')} ${_getTruncatedOrderId()}',
          style: TextStyle(
            color: ui.isDark ? Colors.white : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildCampaignWithRow(ui),
        const SizedBox(height: 22),
        Text(
          AppTranslations.getString(context, 'client_name'),
          style: TextStyle(
            color: ui.isDark ? Colors.white54 : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          clientName,
          style: TextStyle(
            color: ui.isDark ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatDate(dateRaw.toString()),
          style: TextStyle(
            color: ui.isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        _buildContactCard(ui: ui, email: email, phone: phone),
        const SizedBox(height: 12),
        _buildServicesCard(ui),
      ],
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _OrderDetailUi.buttonSize,
        height: _OrderDetailUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ui.buttonFillTop, ui.buttonFillBottom],
          ),
          borderRadius: BorderRadius.circular(_OrderDetailUi.buttonRadius),
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
    );
  }

  Widget _buildCampaignWithRow(SalonUiTheme ui) {
    final pseudo = _influencerProfile['pseudo']?.toString() ?? 'Unknown';

    return Row(
      children: [
        Text(
          AppTranslations.getString(context, 'campaign_with'),
          style: TextStyle(
            color: ui.isDark ? Colors.white70 : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        _buildInfluencerAvatar(ui),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '@$pseudo',
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfluencerAvatar(SalonUiTheme ui) {
    final profilePicture = _influencerProfile['profilePicture'];

    return ClipOval(
      child: SizedBox(
        width: 22,
        height: 22,
        child: profilePicture != null && profilePicture.toString().isNotEmpty
            ? Image.network(
                profilePicture.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar(ui);
                },
              )
            : _buildDefaultAvatar(ui),
      ),
    );
  }

  Widget _buildDefaultAvatar(SalonUiTheme ui) {
    return ColoredBox(
      color: ui.bannerFill,
      child: Center(
        child: Icon(Icons.person, color: ui.isDark ? Colors.white54 : Colors.black, size: 14),
      ),
    );
  }

  Widget _buildContactCard({
    required SalonUiTheme ui,
    required String email,
    required String phone,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_OrderDetailUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'contact'),
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          _buildContactRow(
            ui: ui,
            label: AppTranslations.getString(context, 'client_email'),
            value: email.isEmpty ? '—' : email,
            icon: LucideIcons.copy,
            onTap: email.isEmpty ? null : () => _copyEmail(email),
          ),
          const SizedBox(height: 16),
          _buildContactRow(
            ui: ui,
            label: AppTranslations.getString(context, 'client_phone_number'),
            value: phone.isEmpty ? '—' : phone,
            icon: LucideIcons.phone,
            onTap: phone.isEmpty ? null : () => _callPhone(phone),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required SalonUiTheme ui,
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ui.isDark ? Colors.white54 : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: ui.isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onTap,
          child: Icon(
            icon,
            color: ui.isDark ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
      ],
    );
  }

  Future<void> _copyEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!mounted) return;
    TopNotificationService.showSuccess(
      context: context,
      message: AppTranslations.getString(context, 'email_copied'),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      TopNotificationService.showError(
        context: context,
        message: 'Unable to open phone dialer',
      );
    }
  }

  Widget _buildServicesCard(SalonUiTheme ui) {
    final services = _data['services'] as List<dynamic>? ??
        widget.order['services'] as List<dynamic>? ??
        [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_OrderDetailUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'services'),
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          if (services.isEmpty)
            Text(
              'No services',
              style: TextStyle(
                color: ui.isDark ? Colors.white54 : Colors.black,
                fontSize: 15,
              ),
            )
          else
            ...services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              final serviceName =
                  service['serviceName']?.toString() ?? 'Unknown Service';
              final quantity = service['quantity'] ?? 1;
              final unitPrice = service['priceAfterDiscount'] ??
                  service['priceAtTimeOfOrder'] ??
                  0;
              final lineTotal = (unitPrice is num ? unitPrice.toDouble() : 0) *
                  (quantity is num ? quantity.toDouble() : 1);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < services.length - 1 ? 12 : 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        'x$quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Text(
                        'EUR ${lineTotal.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.getString(context, 'total'),
                style: TextStyle(
                  color: ui.isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'EUR ${_calculateTotal().toStringAsFixed(0)}',
                style: TextStyle(
                  color: ui.isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    if (_orderDetails != null) {
      final services = _orderDetails?['services'] as List<dynamic>? ?? [];
      double totalAmount = 0;
      for (final service in services) {
        final priceAfterDiscount =
            service['priceAfterDiscount'] ?? service['priceAtTimeOfOrder'] ?? 0;
        final quantity = service['quantity'] ?? 1;
        totalAmount += (priceAfterDiscount is num
                ? priceAfterDiscount.toDouble()
                : 0) *
            (quantity is num ? quantity.toDouble() : 1);
      }
      return totalAmount;
    }

    return double.tryParse(
          widget.order['discountedAmount']?.toString() ?? '0',
        ) ??
        0;
  }

  String _getTruncatedOrderId() {
    final fullOrderId =
        _data['id']?.toString() ?? widget.order['id']?.toString() ?? 'N/A';
    return fullOrderId.length > 9 ? fullOrderId.substring(0, 9) : fullOrderId;
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      return '$day/$month/${date.year} $hour:$minute:$second';
    } catch (e) {
      return 'Unknown Date';
    }
  }
}
