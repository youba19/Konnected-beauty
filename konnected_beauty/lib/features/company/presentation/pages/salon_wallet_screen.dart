import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/salon_profile_service.dart';
import '../../../../widgets/common/shimmer_loading.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/services/api/salon_wallet_service.dart';
import '../../../../core/services/api/stripe_service.dart';
import 'salon_reports_screen.dart';
import 'salon_settings_screen.dart';

/// Revenue tab — layout radius tokens (colors via [SalonUiTheme]).
abstract final class _SalonRevenueUi {
  static const double radius = 16;
  static const double buttonRadius = 14;
}

class SalonWalletScreen extends StatefulWidget {
  const SalonWalletScreen({super.key});

  @override
  State<SalonWalletScreen> createState() => _SalonWalletScreenState();
}

class _SalonWalletScreenState extends State<SalonWalletScreen> {
  bool _isLoading = true;
  bool _isLoadingStripe = false;
  double _balance = 0.0;
  String _profileInitial = 'K';
  final ScrollController _scrollController = ScrollController();

  // Stats data
  Map<String, dynamic> _stats = {};

  // Three-months chart data
  Map<String, dynamic> _threeMonthsStats = {};

  @override
  void initState() {
    super.initState();
    _loadProfileInitial();
    _loadWalletData(showLoading: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileInitial() async {
    try {
      final result = await SalonProfileService().getSalonProfile();
      if (!mounted || result['success'] != true) return;
      final data = result['data'] as Map<String, dynamic>?;
      final salonName = data?['salonInfo']?['name']?.toString() ?? '';
      final personalName = data?['name']?.toString() ?? '';
      final source = salonName.isNotEmpty ? salonName : personalName;
      if (source.isNotEmpty) {
        setState(() => _profileInitial = source[0].toUpperCase());
      }
    } catch (_) {
      // Keep default initial.
    }
  }

  Future<void> _loadWalletData({bool showLoading = false}) async {
    try {
      if (showLoading && mounted) {
        setState(() => _isLoading = true);
      }

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

      if (!mounted) return;

      setState(() {
        if (balanceResult['success'] == true) {
          _balance = (balanceResult['balance'] as num).toDouble();
          print('💰 Balance loaded successfully: €$_balance');
        } else if (showLoading) {
          _balance = 0.0;
          print('❌ Failed to load balance: ${balanceResult['message']}');
        }

        if (statsResult['success'] == true) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
          print('📊 Stats loaded successfully: $_stats');
        } else if (showLoading) {
          _stats = {};
          print('❌ Failed to load stats: ${statsResult['message']}');
        }

        if (threeMonthsResult['success'] == true) {
          _threeMonthsStats =
              threeMonthsResult['threeMonthsStats'] as Map<String, dynamic>;
          print(
              '📈 Three-months stats loaded successfully: $_threeMonthsStats');
        } else if (showLoading) {
          _threeMonthsStats = {};
          print(
              '❌ Failed to load three-months stats: ${threeMonthsResult['message']}');
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep existing data on refresh errors so the screen stays fixed.
          if (showLoading) {
            _balance = 0.0;
            _stats = {};
            _threeMonthsStats = {};
          }
        });
      }
      print('❌ Error loading wallet data: $e');
    }
  }

  Future<void> _onRefresh() async {
    // Silent refresh: keep current UI, update values in place.
    await _loadWalletData(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final ui = SalonUiTheme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: ui.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: SalonUiTheme.blueUpper,
            displacement: topInset + 40,
            edgeOffset: topInset,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(topInset),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getString(context, 'revenue'),
                                style: TextStyle(
                                  color: ui.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTranslations.getString(
                                  context,
                                  'track_earnings_realtime',
                                ),
                                style: TextStyle(
                                  color: ui.isDark ? ui.textSecondary : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _isLoading
                                  ? const ShimmerCard(
                                      height: 88,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(16),
                                      ),
                                    )
                                  : _buildBalanceCard(ui),
                              const SizedBox(height: 16),
                              _isLoading
                                  ? _buildMetricsShimmer()
                                  : _buildMetricsGrid(context, ui),
                              const SizedBox(height: 20),
                              _buildActionButtons(ui),
                              const SizedBox(height: 28),
                              _buildChartSection(
                                ui: ui,
                                title: AppTranslations.getString(
                                  context,
                                  'orders',
                                ),
                                subtitle: AppTranslations.getString(
                                  context,
                                  'from_last_3_months',
                                ),
                                isLoading: _isLoading,
                                child: _buildOrdersChart(ui),
                              ),
                              const SizedBox(height: 28),
                              _buildChartSection(
                                ui: ui,
                                title: AppTranslations.getString(
                                  context,
                                  'revenue',
                                ),
                                subtitle: AppTranslations.getString(
                                  context,
                                  'from_last_3_months',
                                ),
                                isLoading: _isLoading,
                                child: _buildRevenueChart(ui),
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topInset) {
    final ui = SalonUiTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: ui.headerGradient,
          stops: ui.headerStops,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topInset + 6, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/Konected beauty - Logo white.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SalonSettingsScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: SalonUiTheme.profileBlue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _profileInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SalonUiTheme ui) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SalonReportsScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: ui.outlinedButtonBorder,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(_SalonRevenueUi.buttonRadius),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: Text(
              AppTranslations.getString(context, 'view_reports'),
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildStripeButton(ui),
      ],
    );
  }

  Widget _buildChartSection({
    required SalonUiTheme ui,
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
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: ui.isDark ? ui.textSecondary : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        isLoading
            ? const ShimmerCard(
                height: 180,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                decoration: BoxDecoration(
                  color: ui.card,
                  borderRadius: BorderRadius.circular(_SalonRevenueUi.radius),
                  border: Border.all(
                    color: ui.cardBorder,
                    width: 1,
                  ),
                ),
                child: child,
              ),
      ],
    );
  }

  Widget _buildBalanceCard(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_SalonRevenueUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Text(
            AppTranslations.getString(context, 'balance'),
            style: TextStyle(
              color: ui.isDark ? ui.textSecondary : Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '€ ${_balance.toStringAsFixed(2)}',
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsShimmer() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ShimmerCard(
                height: 110,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ShimmerCard(
                height: 110,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShimmerCard(
                height: 110,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ShimmerCard(
                height: 110,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SalonUiTheme ui) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                ui: ui,
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
                ui: ui,
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
          ],
        ),
        const SizedBox(height: 12),
        _MetricTile(
          ui: ui,
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
      ],
    );
  }

  Widget _buildOrdersChart(SalonUiTheme ui) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _OrdersChartPainter(
          orderTrend: _threeMonthsStats['orderTrend'],
          hasError: false,
          textColor: ui.textPrimary,
          mutedTextColor: ui.isDark ? ui.textMuted : Colors.black,
          gridColor: (ui.isDark ? ui.textMuted : Colors.black).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(SalonUiTheme ui) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _RevenueChartPainter(
          revenueTrend: _threeMonthsStats['revenueTrend'],
          hasError: false,
          textColor: ui.textPrimary,
          mutedTextColor: ui.isDark ? ui.textMuted : Colors.black,
          gridColor: (ui.isDark ? ui.textMuted : Colors.black).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _openStripeDashboard() async {
    if (_isLoadingStripe) return;

    setState(() {
      _isLoadingStripe = true;
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
      if (mounted) {
        setState(() {
          _isLoadingStripe = false;
        });
      }
    }
  }

  Widget _buildStripeButton(SalonUiTheme ui) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoadingStripe ? null : _openStripeDashboard,
        style: ElevatedButton.styleFrom(
          backgroundColor: ui.primaryButtonBg,
          foregroundColor: ui.primaryButtonFg,
          disabledBackgroundColor: ui.primaryButtonBg.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_SalonRevenueUi.buttonRadius),
          ),
        ),
        child: Row(
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
              _isLoadingStripe ? 'Loading...' : 'Open Stripe dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ui.primaryButtonFg,
              ),
            ),
            if (_isLoadingStripe) ...[
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

class _MetricTile extends StatelessWidget {
  final SalonUiTheme ui;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isError;
  final double? changePercentage;

  const _MetricTile({
    required this.ui,
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_SalonRevenueUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: ui.isDark ? ui.textSecondary : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: ui.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: isError ? Colors.red : ui.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color:
                  isError ? Colors.red.withValues(alpha: 0.7) : _getSubtitleColor(),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getSubtitleColor() {
    if (changePercentage == null) {
      return ui.isDark ? ui.textMuted : Colors.black;
    }

    return SalonUiTheme.profileBlue;
  }
}

class _OrdersChartPainter extends CustomPainter {
  final Map<String, dynamic>? orderTrend;
  final bool hasError;
  final Color textColor;
  final Color mutedTextColor;
  final Color gridColor;

  const _OrdersChartPainter({
    this.orderTrend,
    this.hasError = false,
    required this.textColor,
    required this.mutedTextColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final axisPaint = Paint()
      ..color = gridColor
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
          style: textStyle.copyWith(color: mutedTextColor),
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
            color: mutedTextColor,
            fontSize: 10,
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
      ..color = const Color(0xFF3B6FD4)
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
        ..color = const Color(0xFF3B6FD4)
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
  final Color textColor;
  final Color mutedTextColor;
  final Color gridColor;

  const _RevenueChartPainter({
    this.revenueTrend,
    this.hasError = false,
    required this.textColor,
    required this.mutedTextColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final axisPaint = Paint()
      ..color = gridColor
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
          style: textStyle.copyWith(color: mutedTextColor),
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
      ..color = const Color(0xFF3B6FD4)
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
        ..color = const Color(0xFF3B6FD4)
        ..style = PaintingStyle.fill;

      for (final point in dataPoints) {
        canvas.drawCircle(point, 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
