import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api/qr_scan_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

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

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Extract order ID from the passed order data
      final orderId = widget.order['id'] ?? widget.order['_id'];

      if (orderId == null || orderId.toString().isEmpty) {
        throw Exception('Order ID not found');
      }

      print('🔍 === FETCHING ORDER DETAILS ===');
      print('🆔 Order ID: $orderId');

      // Fetch complete order details from API
      final result = await QRScanService.getOrderDetails(orderId.toString());

      if (result['success'] == true && result['data'] != null) {
        print('✅ Order details fetched successfully');
        setState(() {
          _orderDetails = result['data'];
          _isLoading = false;
        });
      } else {
        print('❌ Failed to fetch order details: ${result['message']}');
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Failed to fetch order details';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching order details: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error loading order details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF1F1E1E), // Bottom color (darker)
                  Color(0xFF3B3B3B), // Top color (lighter)
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingContent()
                        : _hasError
                            ? _buildErrorContent()
                            : _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            _buildShimmerHeader(),
            const SizedBox(height: 24),

            // Client info shimmer
            _buildShimmerClientInfo(),
            const SizedBox(height: 24),

            // Services shimmer
            _buildShimmerServices(),
            const SizedBox(height: 24),

            // Total shimmer
            _buildShimmerTotal(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button shimmer
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),

        // Order ID shimmer
        Container(
          width: 200,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),

        // Campaign info shimmer
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),

        // Date shimmer
        Container(
          width: 180,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 100,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
            2,
            (index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
      ],
    );
  }

  Widget _buildShimmerTotal() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Order',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchOrderDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.greenColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Client Information
          _buildClientInfo(),
          const SizedBox(height: 24),

          // Services
          _buildServices(),
          const SizedBox(height: 24),

          // Total
          _buildTotal(),
          const SizedBox(height: 40), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimaryColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),

        // Order ID
        Text(
          '${AppTranslations.getString(context, 'order')} ${_getTruncatedOrderId()}',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Campaign with section
        Row(
          children: [
            Text(
              AppTranslations.getString(context, 'campaign_with'),
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w200,
              ),
            ),
            const SizedBox(width: 8),
            _buildInfluencerAvatar(),
            const SizedBox(width: 8),
            Text(
              '@${_orderDetails?['campaign']?['influencer']?['profile']?['pseudo'] ?? widget.order['influencer']?['profile']?['pseudo'] ?? 'Unknown'}',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Date and time
        Text(
          _formatDate(_orderDetails?['updatedAt'] ??
              _orderDetails?['createdAt'] ??
              widget.order['updatedAt'] ??
              widget.order['createdAt'] ??
              ''),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w200,
          ),
        ),
      ],
    );
  }

  Widget _buildInfluencerAvatar() {
    final profilePicture = _orderDetails?['campaign']?['influencer']?['profile']
            ?['profilePicture'] ??
        widget.order['influencer']?['profile']?['profilePicture'];

    if (profilePicture != null && profilePicture.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profilePicture.toString(),
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 12,
      ),
    );
  }

  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client name
        Text(
          AppTranslations.getString(context, 'client_name'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w200,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _orderDetails?['clientInfo']?['name'] ??
              widget.order['clientInfo']?['name'] ??
              'Unknown Client',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Client phone number
        Text(
          AppTranslations.getString(context, 'phone_number'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w200,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _orderDetails?['clientInfo']?['phoneNumber'] ??
              widget.order['clientInfo']?['phoneNumber'] ??
              'Unknown Phone',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'services'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w200,
          ),
        ),
        const SizedBox(height: 12),

        // Service items
        _buildServiceItems(),
      ],
    );
  }

  Widget _buildServiceItem(String serviceName, int quantity, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          serviceName,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              'x$quantity',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 50),
            Text(
              '$price',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotal() {
    // Calculate total from services if we have detailed order data
    double totalAmount = 0;
    if (_orderDetails != null) {
      final services = _orderDetails?['services'] as List<dynamic>? ?? [];
      for (final service in services) {
        final priceAfterDiscount =
            service['priceAfterDiscount'] ?? service['priceAtTimeOfOrder'] ?? 0;
        final quantity = service['quantity'] ?? 1;
        totalAmount += (priceAfterDiscount * quantity);
      }
    } else {
      // Fallback to the old format
      totalAmount =
          double.parse(widget.order['discountedAmount']?.toString() ?? '0');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppTranslations.getString(context, 'total'),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${totalAmount.toStringAsFixed(0)} EUR',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItems() {
    final services = _orderDetails?['services'] as List<dynamic>? ??
        widget.order['services'] as List<dynamic>? ??
        [];

    if (services.isEmpty) {
      return Text(
        'No services',
        style: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      children: services.asMap().entries.map((entry) {
        final index = entry.key;
        final service = entry.value;
        final serviceName =
            service['serviceName']?.toString() ?? 'Unknown Service';
        final quantity = service['quantity'] ?? 1;

        // Use the new API response format for pricing
        String servicePrice;
        if (_orderDetails != null) {
          // Use the detailed pricing from the API response
          final priceAfterDiscount = service['priceAfterDiscount'] ??
              service['priceAtTimeOfOrder'] ??
              0;
          servicePrice = '${priceAfterDiscount.toStringAsFixed(0)} EUR';
        } else {
          // Fallback to the old format
          final discountedAmount =
              widget.order['discountedAmount']?.toString() ?? '0';
          servicePrice =
              '${(int.parse(discountedAmount)).toStringAsFixed(0)} EUR';
        }

        return Column(
          children: [
            _buildServiceItem(serviceName, quantity, servicePrice),
            if (index < services.length - 1) const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  String _getTruncatedOrderId() {
    final fullOrderId = _orderDetails?['id']?.toString() ??
        widget.order['id']?.toString() ??
        'N/A';
    return fullOrderId.length > 8 ? fullOrderId.substring(0, 8) : fullOrderId;
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown Date';
    }
  }
}
