import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/shimmer_loading.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/services/api/salon_wallet_service.dart';
import 'withdrawal_history_screen.dart';

class SalonWalletScreen extends StatefulWidget {
  const SalonWalletScreen({super.key});

  @override
  State<SalonWalletScreen> createState() => _SalonWalletScreenState();
}

class _SalonWalletScreenState extends State<SalonWalletScreen> {
  bool _isLoading = true;
  bool _hasPendingWithdrawRequest = false;
  double _balance = 0.0;

  // Stats data
  Map<String, dynamic> _stats = {};

  // Three-months chart data
  Map<String, dynamic> _threeMonthsStats = {};

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      print('💰 === LOADING SALON WALLET DATA ===');

      // Fetch balance, stats, and three-months stats in parallel
      final results = await Future.wait([
        SalonWalletService.getBalance(),
        SalonWalletService.getStats(),
        SalonWalletService.getThreeMonthsStats(),
      ]);

      final balanceResult = results[0];
      final statsResult = results[1];
      final threeMonthsResult = results[2];

      if (mounted) {
        // Handle balance result
        if (balanceResult['success'] == true) {
          _balance = (balanceResult['balance'] as num).toDouble();
          print('💰 Balance loaded successfully: €$_balance');
        } else {
          _balance = 0.0; // Set to 0 if failed to load
          print('❌ Failed to load balance: ${balanceResult['message']}');
        }

        // Handle stats result
        if (statsResult['success'] == true) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
          print('📊 Stats loaded successfully: $_stats');
        } else {
          _stats = {}; // Set to empty if failed to load
          print('❌ Failed to load stats: ${statsResult['message']}');
        }

        // Handle three-months stats result
        if (threeMonthsResult['success'] == true) {
          _threeMonthsStats =
              threeMonthsResult['threeMonthsStats'] as Map<String, dynamic>;
          print(
              '📈 Three-months stats loaded successfully: $_threeMonthsStats');
        } else {
          _threeMonthsStats = {}; // Set to empty if failed to load
          print(
              '❌ Failed to load three-months stats: ${threeMonthsResult['message']}');
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _balance = 0.0; // Set to 0 on error
          _stats = {}; // Set to empty on error
          _threeMonthsStats = {}; // Set to empty on error
        });
      }
      print('❌ Error loading wallet data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadWalletData,
        color: Colors.white,
        backgroundColor: const Color(0xFF3A3A3A),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.getString(context, 'wallet'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.getString(
                        context, 'track_earnings_realtime'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Balance card (dark gray)
              _isLoading
                  ? const ShimmerCard(
                      height: 72,
                      borderRadius: BorderRadius.all(Radius.circular(12)))
                  : _buildBalanceCard(),

              const SizedBox(height: 16),

              // Metrics grid (2 columns)
              _isLoading ? _buildMetricsShimmer() : _buildMetricsGrid(context),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),

              const SizedBox(height: 24),

              // Orders section
              _buildChartSection(
                title: AppTranslations.getString(context, 'orders'),
                subtitle:
                    AppTranslations.getString(context, 'from_last_3_months'),
                isLoading: _isLoading,
                child: _buildOrdersChart(),
              ),

              const SizedBox(height: 24),

              // Revenue section
              _buildChartSection(
                title: AppTranslations.getString(context, 'revenue'),
                subtitle:
                    AppTranslations.getString(context, 'from_last_3_months'),
                isLoading: _isLoading,
                child: _buildRevenueChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Withdraw history button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WithdrawalHistoryScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.transparent,
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
        ),
        // Only show request withdraw button if no pending request
        if (!_hasPendingWithdrawRequest) ...[
          const SizedBox(height: 12),
          // Request withdraw button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                _showWithdrawRequestDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
          ),
        ],
        // Show pending request message if request was submitted
        if (_hasPendingWithdrawRequest) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Withdraw request pending approval',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required bool isLoading,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        isLoading
            ? const ShimmerCard(
                height: 160, borderRadius: BorderRadius.all(Radius.circular(8)))
            : child,
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.getString(context, 'balance'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '€ ${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildMetricsShimmer() {
    return Row(
      children: const [
        Expanded(
            child: ShimmerCard(
                height: 76,
                borderRadius: BorderRadius.all(Radius.circular(8)))),
        SizedBox(width: 12),
        Expanded(
            child: ShimmerCard(
                height: 76,
                borderRadius: BorderRadius.all(Radius.circular(8)))),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: AppTranslations.getString(context, 'total_revenue'),
                value:
                    '€ ${(_stats['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                subtitle:
                    '${_stats['totalRevenueChange'] ?? 0.0}% ${AppTranslations.getString(context, 'from_last_month')}',
                icon: LucideIcons.euro,
                isError: false,
                changePercentage:
                    (_stats['totalRevenueChange'] ?? 0.0).toDouble(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: AppTranslations.getString(context, 'ready_to_withdraw'),
                value: '€ ${_balance.toStringAsFixed(2)}',
                subtitle: 'Available balance',
                icon: LucideIcons.wallet,
                isError: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: AppTranslations.getString(context, 'number_orders'),
                value: '${_stats['totalOrderCount'] ?? 0}',
                subtitle:
                    '${_stats['totalOrderCountChange'] ?? 0.0}% ${AppTranslations.getString(context, 'from_last_month')}',
                icon: LucideIcons.boxes,
                isError: false,
                changePercentage:
                    (_stats['totalOrderCountChange'] ?? 0.0).toDouble(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: AppTranslations.getString(context, 'avg_order_value'),
                value:
                    '€ ${(_stats['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}',
                subtitle:
                    '${_stats['averageOrderValueChange'] ?? 0.0}% ${AppTranslations.getString(context, 'from_last_month')}',
                icon: LucideIcons.euro,
                isError: false,
                changePercentage:
                    (_stats['averageOrderValueChange'] ?? 0.0).toDouble(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersChart() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _OrdersChartPainter(
          orderTrend: _threeMonthsStats['orderTrend'],
          hasError: false, // Always show data, never error
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _RevenueChartPainter(
          revenueTrend: _threeMonthsStats['revenueTrend'],
          hasError: false, // Always show data, never error
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
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isError;
  final double? changePercentage;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isError = false,
    this.changePercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isError ? Colors.red : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color:
                  isError ? Colors.red.withOpacity(0.7) : _getSubtitleColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubtitleColor() {
    if (changePercentage == null) {
      return Colors.white.withOpacity(0.7);
    }

    if (changePercentage! > 0) {
      return Colors.green.withOpacity(0.8);
    } else if (changePercentage! < 0) {
      return Colors.red.withOpacity(0.8);
    } else {
      return Colors.white.withOpacity(0.7);
    }
  }
}

class _OrdersChartPainter extends CustomPainter {
  final Map<String, dynamic>? orderTrend;
  final bool hasError;

  const _OrdersChartPainter({
    this.orderTrend,
    this.hasError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    // Horizontal grid lines
    const gridLines = 4;
    final padding = 25.0;
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      canvas.drawLine(
          Offset(padding, dy), Offset(size.width - padding, dy), axisPaint);
    }

    // Get real data or use fallback
    List<Map<String, dynamic>> trends = [];
    List<String> xLabels = ['AUG', 'SEP', 'OCT'];
    List<double> yLabels = [2, 1.5, 1, 0.5, 0];

    // Check if we have real data or if all values are 0
    bool hasRealData = false;
    if (orderTrend != null && orderTrend!['trends'] != null) {
      final trends = List<Map<String, dynamic>>.from(orderTrend!['trends']);
      if (trends.isNotEmpty) {
        final maxValue = trends
            .map((trend) => (trend['value'] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);
        hasRealData = maxValue > 0;
      }
    }

    if (hasError || !hasRealData) {
      // Show zero data state instead of error or when all values are 0
      final zeroTextPainter = TextPainter(
        text: TextSpan(
          text: '0',
          style: textStyle.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
        textDirection: TextDirection.ltr,
      );
      zeroTextPainter.layout();
      zeroTextPainter.paint(
        canvas,
        Offset(
          (size.width - zeroTextPainter.width) / 2,
          (size.height - zeroTextPainter.height) / 2,
        ),
      );
      return;
    }

    if (orderTrend != null && orderTrend!['trends'] != null) {
      trends = List<Map<String, dynamic>>.from(orderTrend!['trends']);
      if (trends.isNotEmpty) {
        xLabels =
            trends.map((trend) => trend['month']?.toString() ?? '').toList();
        // Calculate Y-axis labels based on max value
        final maxValue = trends
            .map((trend) => (trend['value'] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);
        if (maxValue > 0) {
          yLabels = [
            maxValue,
            maxValue * 0.75,
            maxValue * 0.5,
            maxValue * 0.25,
            0
          ];
        } else {
          // If all values are 0, show a small range to make the line visible
          yLabels = [1, 0.75, 0.5, 0.25, 0];
        }
      }
    }

    // Y-axis labels - show only unique values
    final uniqueLabels = <String>[];
    for (int i = 0; i <= gridLines; i++) {
      final label = yLabels[i].toStringAsFixed(0);
      if (!uniqueLabels.contains(label)) {
        uniqueLabels.add(label);
      }
    }

    for (int i = 0; i < uniqueLabels.length; i++) {
      final dy = size.height * (i / (uniqueLabels.length - 1));
      final label = uniqueLabels[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(
            color: Colors.white.withOpacity(0.4), // More subtle color
            fontSize: 10, // Smaller font size
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, dy - textPainter.height / 2),
      );
    }

    // X-axis labels - positioned at zero line level
    final xPositions = [0.15, 0.5, 0.9]; // Positions for the labels
    final zeroLineY =
        size.height * 0.95; // Zero line position (bottom of chart)
    final labelOffset = 15.0; // Space below zero line
    for (int i = 0; i < xLabels.length; i++) {
      final x = padding + (size.width - 2 * padding) * xPositions[i];
      final textPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, zeroLineY + labelOffset),
      );
    }

    // Data points from real API data
    final chartWidth = size.width - padding;
    List<Offset> dataPoints = [];

    if (trends.isNotEmpty) {
      final maxValue = yLabels[0];
      for (int i = 0; i < trends.length; i++) {
        final value = (trends[i]['value'] ?? 0).toDouble();
        double normalizedY;
        if (maxValue > 0) {
          normalizedY = (maxValue - value) / maxValue;
        } else {
          // If all values are 0, show the line in the middle of the chart
          normalizedY = 0.5;
        }
        final x = padding + (chartWidth * xPositions[i]);
        final y = size.height * (0.05 + normalizedY * 0.9);
        dataPoints.add(Offset(x, y));
      }
    } else {
      // No data points when there's no real data
      dataPoints = [];
    }

    // Orders line
    final linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (dataPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(dataPoints[0].dx, dataPoints[0].dy);

      // Create smooth curves using cubic Bézier curves
      for (int i = 1; i < dataPoints.length; i++) {
        final currentPoint = dataPoints[i];
        final previousPoint = dataPoints[i - 1];

        // Calculate smooth control points for cubic Bézier curve
        double controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y;

        if (i == 1) {
          // First curve - use simple control points
          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.3;
          controlPoint1Y = previousPoint.dy;
          controlPoint2X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.7;
          controlPoint2Y = currentPoint.dy;
        } else if (i == dataPoints.length - 1) {
          // Last curve - use simple control points
          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.3;
          controlPoint1Y = previousPoint.dy;
          controlPoint2X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.7;
          controlPoint2Y = currentPoint.dy;
        } else {
          // Middle curves - use smooth control points based on neighboring points
          final nextPoint = dataPoints[i + 1];
          final prevPoint = dataPoints[i - 2];

          // Calculate smooth control points
          final tension =
              0.3; // Controls curve smoothness (0.0 = straight, 1.0 = very curved)

          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - prevPoint.dx) * tension;
          controlPoint1Y =
              previousPoint.dy + (currentPoint.dy - prevPoint.dy) * tension;

          controlPoint2X =
              currentPoint.dx - (nextPoint.dx - previousPoint.dx) * tension;
          controlPoint2Y =
              currentPoint.dy - (nextPoint.dy - previousPoint.dy) * tension;
        }

        path.cubicTo(
          controlPoint1X,
          controlPoint1Y,
          controlPoint2X,
          controlPoint2Y,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
      canvas.drawPath(path, linePaint);

      // Data point dots (drawn on top of line)
      final dotPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.fill;

      for (final point in dataPoints) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RevenueChartPainter extends CustomPainter {
  final Map<String, dynamic>? revenueTrend;
  final bool hasError;

  const _RevenueChartPainter({
    this.revenueTrend,
    this.hasError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final axisPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1;

    // Horizontal grid lines
    const gridLines = 4;
    final padding = 25.0;
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      canvas.drawLine(
          Offset(padding, dy), Offset(size.width - padding, dy), axisPaint);
    }

    // Get real data or use fallback
    List<Map<String, dynamic>> trends = [];
    List<String> xLabels = ['AUG', 'SEP', 'OCT'];
    List<double> yLabels = [200, 150, 100, 50, 0];

    // Check if we have real data or if all values are 0
    bool hasRealData = false;
    if (revenueTrend != null && revenueTrend!['trends'] != null) {
      final trends = List<Map<String, dynamic>>.from(revenueTrend!['trends']);
      if (trends.isNotEmpty) {
        final maxValue = trends
            .map((trend) => (trend['value'] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);
        hasRealData = maxValue > 0;
      }
    }

    if (hasError || !hasRealData) {
      // Show zero data state instead of error or when all values are 0
      final zeroTextPainter = TextPainter(
        text: TextSpan(
          text: '0',
          style: textStyle.copyWith(color: Colors.white.withOpacity(0.7)),
        ),
        textDirection: TextDirection.ltr,
      );
      zeroTextPainter.layout();
      zeroTextPainter.paint(
        canvas,
        Offset(
          (size.width - zeroTextPainter.width) / 2,
          (size.height - zeroTextPainter.height) / 2,
        ),
      );
      return;
    }

    if (revenueTrend != null && revenueTrend!['trends'] != null) {
      trends = List<Map<String, dynamic>>.from(revenueTrend!['trends']);
      if (trends.isNotEmpty) {
        xLabels =
            trends.map((trend) => trend['month']?.toString() ?? '').toList();
        // Calculate Y-axis labels based on max value
        final maxValue = trends
            .map((trend) => (trend['value'] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);
        if (maxValue > 0) {
          yLabels = [
            maxValue,
            maxValue * 0.75,
            maxValue * 0.5,
            maxValue * 0.25,
            0
          ];
        } else {
          // If all values are 0, show a small range to make the line visible
          yLabels = [1, 0.75, 0.5, 0.25, 0];
        }
      }
    }

    // Y-axis labels - inverted order
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      final label = yLabels[i].toStringAsFixed(0);
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, dy - textPainter.height / 2),
      );
    }

    // X-axis labels - positioned at zero line level
    final xPositions = [0.15, 0.5, 0.9]; // Positions for the labels
    final zeroLineY =
        size.height * 0.95; // Zero line position (bottom of chart)
    final labelOffset = 15.0; // Space below zero line
    for (int i = 0; i < xLabels.length; i++) {
      final x = padding + (size.width - 2 * padding) * xPositions[i];
      final textPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, zeroLineY + labelOffset),
      );
    }

    // Data points from real API data
    final chartWidth = size.width - padding;
    List<Offset> dataPoints = [];

    if (trends.isNotEmpty) {
      final maxValue = yLabels[0];
      for (int i = 0; i < trends.length; i++) {
        final value = (trends[i]['value'] ?? 0).toDouble();
        double normalizedY;
        if (maxValue > 0) {
          normalizedY = (maxValue - value) / maxValue;
        } else {
          // If all values are 0, show the line in the middle of the chart
          normalizedY = 0.5;
        }
        final x = padding + (chartWidth * xPositions[i]);
        final y = size.height * (0.05 + normalizedY * 0.9);
        dataPoints.add(Offset(x, y));
      }
    } else {
      // No data points when there's no real data
      dataPoints = [];
    }

    // Revenue line
    final linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (dataPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(dataPoints[0].dx, dataPoints[0].dy);

      // Create smooth curves using cubic Bézier curves
      for (int i = 1; i < dataPoints.length; i++) {
        final currentPoint = dataPoints[i];
        final previousPoint = dataPoints[i - 1];

        // Calculate smooth control points for cubic Bézier curve
        double controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y;

        if (i == 1) {
          // First curve - use simple control points
          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.3;
          controlPoint1Y = previousPoint.dy;
          controlPoint2X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.7;
          controlPoint2Y = currentPoint.dy;
        } else if (i == dataPoints.length - 1) {
          // Last curve - use simple control points
          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.3;
          controlPoint1Y = previousPoint.dy;
          controlPoint2X =
              previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.7;
          controlPoint2Y = currentPoint.dy;
        } else {
          // Middle curves - use smooth control points based on neighboring points
          final nextPoint = dataPoints[i + 1];
          final prevPoint = dataPoints[i - 2];

          // Calculate smooth control points
          final tension =
              0.3; // Controls curve smoothness (0.0 = straight, 1.0 = very curved)

          controlPoint1X =
              previousPoint.dx + (currentPoint.dx - prevPoint.dx) * tension;
          controlPoint1Y =
              previousPoint.dy + (currentPoint.dy - prevPoint.dy) * tension;

          controlPoint2X =
              currentPoint.dx - (nextPoint.dx - previousPoint.dx) * tension;
          controlPoint2Y =
              currentPoint.dy - (nextPoint.dy - previousPoint.dy) * tension;
        }

        path.cubicTo(
          controlPoint1X,
          controlPoint1Y,
          controlPoint2X,
          controlPoint2Y,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
      canvas.drawPath(path, linePaint);

      // Data point dots (drawn on top of line)
      final dotPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.fill;

      for (final point in dataPoints) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  AppTranslations.getString(context, 'amount_placeholder'),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF3A3A3A),
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
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      return;
    }

    // Parse the amount
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      // Show error message
      TopNotificationService.showError(
        context: context,
        message:
            AppTranslations.getString(context, 'please_enter_valid_amount'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Call the API
      final result = await SalonWalletService.submitWithdrawalRequest(amount);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result['success'] == true) {
          // Success - close dialog and show success message
          Navigator.of(context).pop();
          widget.onRequestSubmitted?.call();
          _showThankYouDialog(context);
        } else {
          // Error - show error message using TopNotification
          String errorMessage =
              result['message'] ?? 'Failed to submit withdrawal request';

          // Check if it's the specific pending withdrawal error
          if (errorMessage.contains('pending withdrawal request')) {
            errorMessage = AppTranslations.getString(
                context, 'pending_withdrawal_request');
          }

          TopNotificationService.showError(
            context: context,
            message: errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        TopNotificationService.showError(
          context: context,
          message: 'Error: ${e.toString()}',
        );
      }
    }
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
