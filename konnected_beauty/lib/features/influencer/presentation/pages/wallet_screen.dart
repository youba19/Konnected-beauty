import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import 'package:konnected_beauty/core/translations/app_translations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/services/api/influencer_wallet_service.dart';
import '../../../../core/services/api/http_interceptor.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'withdrawal_history_screen.dart';
import 'report_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = true;
  bool _hasPendingWithdrawRequest = false;
  double _balance = 0.0;

  // Stats data from the same stats API
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      print('💰 === LOADING INFLUENCER WALLET DATA ===');

      // Fetch balance and stats in parallel
      final results = await Future.wait([
        InfluencerWalletService.getBalance(),
        InfluencerWalletService.getStats(),
      ]);

      final balanceResult = results[0];
      final statsResult = results[1];

      if (mounted) {
        // Handle balance result
        if (balanceResult['success'] == true) {
          _balance = (balanceResult['balance'] as num).toDouble();
          print('💰 Balance loaded successfully: €$_balance');
        } else {
          _balance = 0.0; // Set to 0 if failed to load
          print('❌ Failed to load balance: ${balanceResult['message']}');
        }

        // Handle stats result - using the same stats API for all data
        if (statsResult['success'] == true) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
          print('📊 Stats loaded successfully: $_stats');
          print(
              '📊 Total Revenue: €${_stats['totalRevenue']?['totalRevenue'] ?? 0}');
          print('📊 Total Orders: ${_stats['totalOrders']?['current'] ?? 0}');
          print(
              '📊 Completed Orders: ${_stats['totalCompletedOrders']?['current'] ?? 0}');
          print(
              '📊 Average Order Value: €${_stats['averageOrderValue']?['current'] ?? 0}');
          print('📊 Pending Requests: ${_stats['pendingRequests'] ?? 0}');
        } else {
          _stats = {}; // Set to empty if failed to load
          print('❌ Failed to load stats: ${statsResult['message']}');
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading wallet data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _balance = 0.0; // Set to 0 on error
          _stats = {}; // Set to empty on error
        });
      }
    }
  }

  String _getStartDate() {
    final dailyRevenue = _stats['totalRevenue']?['dailyRevenue'] ?? [];
    if (dailyRevenue.isNotEmpty) {
      final firstDay = dailyRevenue.first;
      if (firstDay is Map<String, dynamic> && firstDay['date'] != null) {
        final date = DateTime.parse(firstDay['date']);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    }
    return '01/01';
  }

  String _getEndDate() {
    final dailyRevenue = _stats['totalRevenue']?['dailyRevenue'] ?? [];
    if (dailyRevenue.isNotEmpty) {
      final lastDay = dailyRevenue.last;
      if (lastDay is Map<String, dynamic> && lastDay['date'] != null) {
        final date = DateTime.parse(lastDay['date']);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    }
    return '01/31';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (within the scroll)
                  _buildHeader(),

                  // Main content (non-nested scroll)
                  _isLoading ? _buildLoadingContent() : _buildWalletContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.getString(context, 'wallet'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'track_earnings_realtime'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildShimmerBalanceCard(),
            const SizedBox(height: 8),
            _buildShimmerRevenueCard(),
            const SizedBox(height: 8),
            _buildShimmerInfoCard(),
            const SizedBox(height: 8),
            _buildShimmerInfoCard(),
            const SizedBox(height: 8),
            _buildShimmerInfoCard(),
            const SizedBox(height: 20),
            _buildShimmerButton(),
            const SizedBox(height: 12),
            _buildShimmerButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRevenueCard() {
    return Container(
      height: 206,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 28,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 14,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Container(
                height: 14,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerInfoCard() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 20,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildWalletContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 8),
          buildTotalRevenueCard(),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: LucideIcons.euro,
            title: AppTranslations.getString(context, 'pending_requests'),
            value: '${_stats['pendingRequests'] ?? 0}',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: LucideIcons.boxes,
            title: AppTranslations.getString(context, 'total_orders'),
            value: '${_stats['totalOrders']?['current'] ?? 0}',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: LucideIcons.euro,
            title: AppTranslations.getString(context, 'avg_order_value'),
            value:
                '€ ${(_stats['averageOrderValue']?['current'] ?? 0.0).toStringAsFixed(2)}',
          ),
          const SizedBox(height: 20),
          _buildWithdrawHistoryButton(),
          const SizedBox(height: 12),
          _buildRequestWithdrawButton(),
          const SizedBox(height: 12),
          _buildViewReportsButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.euro,
                  color: Color(0xFF337f2b),
                  size: 22,
                ),
                Text(
                  AppTranslations.getString(context, 'your_balance'),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '€ ${_balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ));
  }

  Widget buildTotalRevenueCard() {
    return SizedBox(
      height: 206,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: value + euro icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '€ ${(_stats['totalRevenue']?['totalRevenue'] ?? 0.0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Color(0xFF16A34A),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.euro,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Green curved chart - Expanded to fill remaining space
            Expanded(
              child: CustomPaint(
                painter: _RevenueChartPainter(
                  dailyRevenue: _stats['totalRevenue']?['dailyRevenue'] ?? [],
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
            const SizedBox(height: 12),

            // Dates row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStartDate(),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getEndDate(),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bottom label
            const Text(
              'Total Revenue',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ----
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side (icon + title)
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Icon(
                      icon,
                      color: const Color(0xFF16A34A),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis, // 👈 Prevent overflow
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewReportsButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ReportScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppTheme.transparentBackground, // Dark gray background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          elevation: 0,
        ),
        child: Text(
          AppTranslations.getString(context, 'view_reports'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawHistoryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const WithdrawalHistoryScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppTheme.transparentBackground, // Dark gray background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          elevation: 0,
        ),
        child: Text(
          AppTranslations.getString(context, 'withdraw_history'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestWithdrawButton() {
    if (_hasPendingWithdrawRequest) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Withdraw request pending...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _showWithdrawRequestDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          AppTranslations.getString(context, 'request_withdraw'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showWithdrawRequestDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _WithdrawRequestDialog(
          onRequestSubmitted: () {
            setState(() {
              _hasPendingWithdrawRequest = true;
            });
          },
        );
      },
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _ThankYouDialog();
      },
    );
  }
}

// Custom painter for the chart
class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Create a simple area chart
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);

    // Create smooth curves using cubic Bézier
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        final current = points[i];
        final previous = points[i - 1];

        // Calculate control points for smooth curves
        double tension = 0.3; // Controls curve smoothness
        double controlPointOffset = (current.dx - previous.dx) * tension;

        Offset controlPoint1, controlPoint2;

        if (i == 1) {
          // First curve segment
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else if (i == points.length - 1) {
          // Last curve segment
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else {
          // Middle curve segments
          final next = points[i + 1];
          final prev = points[i - 1];

          controlPoint1 = Offset(
            previous.dx + (current.dx - prev.dx) * tension,
            previous.dy + (current.dy - prev.dy) * tension,
          );
          controlPoint2 = Offset(
            current.dx - (next.dx - previous.dx) * tension,
            current.dy - (next.dy - previous.dy) * tension,
          );
        }

        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, current.dx, current.dy);
        fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, current.dx, current.dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RevenueChartPainter extends CustomPainter {
  final List<dynamic> dailyRevenue;

  _RevenueChartPainter({required this.dailyRevenue});

  @override
  void paint(Canvas canvas, Size size) {
    // Process daily revenue data from stats API
    List<double> revenueValues = [];
    if (dailyRevenue.isNotEmpty) {
      for (var day in dailyRevenue) {
        if (day is Map<String, dynamic>) {
          revenueValues.add((day['revenue'] ?? 0.0).toDouble());
        }
      }
    }

    // If no data, create a flat line
    if (revenueValues.isEmpty) {
      revenueValues = List.filled(30, 0.0);
    }

    // Find max value for scaling
    double maxValue = revenueValues.isNotEmpty
        ? revenueValues.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxValue == 0) maxValue = 1.0; // Avoid division by zero

    // Create path based on actual data from stats API with smooth curves
    final path = Path();
    final linePath = Path();

    // Check if we have real data (not all zeros)
    final hasRealData = maxValue > 0;

    if (!hasRealData) {
      // If no real data, draw a flat line at the bottom
      path.moveTo(0, size.height * 0.9);
      path.lineTo(size.width, size.height * 0.9);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      linePath.moveTo(0, size.height * 0.9);
      linePath.lineTo(size.width, size.height * 0.9);
    } else {
      // Calculate data points
      List<Offset> dataPoints = [];
      for (int i = 0; i < revenueValues.length; i++) {
        double x = (i / (revenueValues.length - 1)) * size.width;
        double normalizedValue = revenueValues[i] / maxValue;
        double y = size.height -
            (normalizedValue * size.height * 0.8) -
            (size.height * 0.1);
        dataPoints.add(Offset(x, y));
      }

      // Create smooth curves using cubic Bézier
      if (dataPoints.isNotEmpty) {
        path.moveTo(dataPoints[0].dx, dataPoints[0].dy);
        linePath.moveTo(dataPoints[0].dx, dataPoints[0].dy);

        for (int i = 1; i < dataPoints.length; i++) {
          final current = dataPoints[i];
          final previous = dataPoints[i - 1];

          // Calculate control points for smooth curves
          double tension = 0.3; // Controls curve smoothness
          double controlPointOffset = (current.dx - previous.dx) * tension;

          Offset controlPoint1, controlPoint2;

          if (i == 1) {
            // First curve segment
            controlPoint1 = Offset(
              previous.dx + controlPointOffset,
              previous.dy,
            );
            controlPoint2 = Offset(
              current.dx - controlPointOffset,
              current.dy,
            );
          } else if (i == dataPoints.length - 1) {
            // Last curve segment
            controlPoint1 = Offset(
              previous.dx + controlPointOffset,
              previous.dy,
            );
            controlPoint2 = Offset(
              current.dx - controlPointOffset,
              current.dy,
            );
          } else {
            // Middle curve segments
            final next = dataPoints[i + 1];
            final prev = dataPoints[i - 1];

            controlPoint1 = Offset(
              previous.dx + (current.dx - prev.dx) * tension,
              previous.dy + (current.dy - prev.dy) * tension,
            );
            controlPoint2 = Offset(
              current.dx - (next.dx - previous.dx) * tension,
              current.dy - (next.dy - previous.dy) * tension,
            );
          }

          path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
              controlPoint2.dy, current.dx, current.dy);
          linePath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
              controlPoint2.dy, current.dx, current.dy);
        }
      }
    }

    // Close the path for fill
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF22C55E),
          Color(0x00FFFFFF),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw fill
    canvas.drawPath(path, fillPaint);

    // Draw line
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _RevenueChartPainter) {
      return oldDelegate.dailyRevenue != dailyRevenue;
    }
    return true;
  }
}

class _WithdrawRequestDialog extends StatefulWidget {
  final VoidCallback? onRequestSubmitted;

  const _WithdrawRequestDialog({this.onRequestSubmitted});

  @override
  _WithdrawRequestDialogState createState() => _WithdrawRequestDialogState();
}

class _WithdrawRequestDialogState extends State<_WithdrawRequestDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'request_a_withdraw'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            AppTranslations.getString(context, 'send_withdraw_request'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Amount input
          Text(
            AppTranslations.getString(context, 'enter_the_amount'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Allow only numbers and one decimal point
                if (newValue.text.isEmpty) return newValue;

                // Check if it's a valid number format
                final regex = RegExp(r'^\d+\.?\d{0,2}$');
                if (regex.hasMatch(newValue.text)) {
                  return newValue;
                }
                return oldValue;
              }),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  AppTranslations.getString(context, 'amount_placeholder'),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppTheme.transparentBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A3A3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    AppTranslations.getString(context, 'cancel'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          AppTranslations.getString(context, 'submit'),
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
        ],
      ),
    );
  }

  void _submitRequest() async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      return;
    }

    // Validate amount
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      _showErrorSnackBar(
          AppTranslations.getString(context, 'please_enter_valid_amount'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('💰 === SUBMITTING WITHDRAWAL REQUEST ===');
      print('💰 Amount: $amountValue');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'POST',
        endpoint: '/influencer-withdrawals',
        headers: {
          'Content-Type': 'application/json',
        },
        body: {
          'amount': amountValue,
        },
      );

      print('💰 Withdrawal API Response Status: ${response.statusCode}');
      print('💰 Withdrawal API Response Body: ${response.body}');

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success
          Navigator.of(context).pop();
          widget.onRequestSubmitted?.call();
          TopNotificationService.showSuccess(
            context: context,
            message: AppTranslations.getString(
                context, 'withdrawal_request_submitted'),
          );
          _showThankYouDialog(context);
        } else {
          // Error - show simple translated message
          String errorMessage =
              AppTranslations.getString(context, 'withdrawal_request_failed');

          // Check if it's a pending request error
          if (response.statusCode == 401) {
            errorMessage =
                AppTranslations.getString(context, 'pending_withdrawal_exists');
          }

          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('❌ Error submitting withdrawal request: $e');
      if (mounted) {
        _showErrorSnackBar(
            AppTranslations.getString(context, 'withdrawal_request_error'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    TopNotificationService.showError(
      context: context,
      message: message,
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _ThankYouDialog();
      },
    );
  }
}

class _ThankYouDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'thank_you_for_request'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            AppTranslations.getString(context, 'team_contact_message'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A3A3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppTranslations.getString(context, 'close'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
