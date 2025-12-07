import 'package:flutter/material.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/influencer_wallet_service.dart';
import '../../../../core/services/api/saloons_service.dart';
import 'package:shimmer/shimmer.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  String? _selectedSalonId;
  String? _selectedSalonName;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    try {
      print('📊 === LOADING INFLUENCER REPORT DATA ===');
      print('🏢 Selected Salon ID: $_selectedSalonId');
      print('📅 Start Date: $_startDate');
      print('📅 End Date: $_endDate');

      final statsResult = await InfluencerWalletService.getStats(
        salonId: _selectedSalonId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        if (statsResult['success'] == true) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
          print('📊 Report stats loaded successfully: $_stats');
        } else {
          _stats = {};
          print('❌ Failed to load report stats: ${statsResult['message']}');
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading report data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _stats = {};
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    // Format: MM/YY (e.g., 01/25)
    return '${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  String _getStartDate() {
    final dailyRevenue = _stats['totalRevenue']?['dailyRevenue'] ?? [];
    if (dailyRevenue.isNotEmpty) {
      final firstDay = dailyRevenue.first;
      if (firstDay is Map<String, dynamic> && firstDay['date'] != null) {
        final date = DateTime.parse(firstDay['date']);
        return _formatDate(date);
      }
    }
    return _formatDate(_startDate);
  }

  String _getEndDate() {
    final dailyRevenue = _stats['totalRevenue']?['dailyRevenue'] ?? [];
    if (dailyRevenue.isNotEmpty) {
      final lastDay = dailyRevenue.last;
      if (lastDay is Map<String, dynamic> && lastDay['date'] != null) {
        final date = DateTime.parse(lastDay['date']);
        return _formatDate(date);
      }
    }
    return _formatDate(_endDate);
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###');
    return '€ ${formatter.format(value)}';
  }

  String _formatNumber(int value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),

                  // Main content
                  _isLoading ? _buildLoadingContent() : _buildReportContent(),
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
          // Back arrow
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppTranslations.getString(context, 'report'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppTranslations.getString(context, 'filter_from')} ${_getStartDate()} ${AppTranslations.getString(context, 'filter_to')} ${_getEndDate()}',
                style: TextStyle(
                  color: AppTheme.textWhite70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showFilterModal();
                },
                child: Icon(
                  LucideIcons.filter,
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildShimmerCard(206),
          SizedBox(height: 12),
          _buildShimmerCard(100),
          SizedBox(height: 12),
          _buildShimmerCard(206),
          SizedBox(height: 12),
          _buildShimmerCard(100),
          SizedBox(height: 12),
          _buildShimmerCard(100),
          SizedBox(height: 12),
          _buildShimmerCard(100),
          SizedBox(height: 12),
          _buildShimmerCard(100),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(double height) {
    return Shimmer.fromColors(
      baseColor: AppTheme.getShimmerBase(Theme.of(context).brightness),
      highlightColor:
          AppTheme.getShimmerHighlight(Theme.of(context).brightness),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.shimmerBaseMediumDark,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Total Revenue Card with Chart
          _buildTotalRevenueCard(),
          SizedBox(height: 12),

          // Total clicks on promotions
          _buildMetricCard(
            title:
                AppTranslations.getString(context, 'total_clicks_promotions'),
            value: _formatNumber(_stats['totalClicksOnPromotions'] ?? 1200),
          ),
          SizedBox(height: 12),

          // Total Orders Card with Chart
          _buildTotalOrdersCard(),
          SizedBox(height: 12),

          // Avg Order Value
          _buildMetricCard(
            title: AppTranslations.getString(context, 'avg_order_value'),
            value:
                '€ ${(_stats['averageOrderValue']?['current'] ?? 124.3).toStringAsFixed(1)}',
          ),
          SizedBox(height: 12),

          // Total campaigns
          _buildMetricCard(
            title: AppTranslations.getString(context, 'total_campaigns'),
            value: _formatNumber(_stats['totalCampaigns'] ?? 20),
          ),
          SizedBox(height: 12),

          // Avg promotion %
          _buildMetricCard(
            title: AppTranslations.getString(context, 'avg_promotion_percent'),
            value: '${_stats['avgPromotionPercent'] ?? 15}%',
          ),
          SizedBox(height: 12),

          // Total influencers you've worked with
          _buildMetricCard(
            title: AppTranslations.getString(
                context, 'total_influencers_worked_with'),
            value: _formatNumber(_stats['totalInfluencersWorkedWith'] ?? 5),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTotalRevenueCard() {
    final dailyRevenue = _stats['totalRevenue']?['dailyRevenue'] ?? [];
    return SizedBox(
      height: 206,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTextPrimaryColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getString(context, 'total_revenue'),
              style: TextStyle(
                color: AppTheme.lightTextPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _formatCurrency((_stats['totalRevenue']?['totalRevenue'] ?? 12124)
                  .toDouble()),
              style: TextStyle(
                color: AppTheme.lightTextPrimaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            // Chart area - Expanded to fill remaining space
            Expanded(
              child: CustomPaint(
                painter: _RevenueAreaChartPainter(
                  dailyRevenue: dailyRevenue,
                  brightness: Theme.of(context).brightness,
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStartDate(),
                  style: TextStyle(
                    color: AppTheme.lightTextSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getEndDate(),
                  style: TextStyle(
                    color: AppTheme.lightTextSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalOrdersCard() {
    final dailyOrders = _stats['totalOrders']?['dailyOrders'] ?? [];
    return SizedBox(
      height: 206,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTextPrimaryColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.getString(context, 'total_orders'),
              style: TextStyle(
                color: AppTheme.lightTextPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _formatNumber(_stats['totalOrders']?['current'] ?? 1200),
              style: TextStyle(
                color: AppTheme.lightTextPrimaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            // Chart area - Expanded to fill remaining space
            Expanded(
              child: CustomPaint(
                painter: _OrdersAreaChartPainter(
                  dailyOrders: dailyOrders,
                  brightness: Theme.of(context).brightness,
                ),
                size: const Size(double.infinity, double.infinity),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStartDate(),
                  style: TextStyle(
                    color: AppTheme.lightTextSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getEndDate(),
                  style: TextStyle(
                    color: AppTheme.lightTextSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTextPrimaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.lightTextPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.lightTextPrimaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.transparentBackground
          : AppTheme.textWhite54,
      builder: (BuildContext context) {
        return _FilterModal(
          startDate: _startDate,
          endDate: _endDate,
          selectedSalonId: _selectedSalonId,
          selectedSalonName: _selectedSalonName,
          onApply: (startDate, endDate, salonId, salonName) {
            setState(() {
              _startDate = startDate;
              _endDate = endDate;
              _selectedSalonId = salonId;
              _selectedSalonName = salonName;
            });
            // Reload data with new filters
            _loadReportData();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

// Filter Modal Widget
class _FilterModal extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedSalonId;
  final String? selectedSalonName;
  final Function(DateTime, DateTime, String?, String?) onApply;

  const _FilterModal({
    required this.startDate,
    required this.endDate,
    this.selectedSalonId,
    this.selectedSalonName,
    required this.onApply,
  });

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedSalonId;
  String? _selectedSalonName;
  final TextEditingController _salonSearchController = TextEditingController();
  List<Map<String, dynamic>> _salons = [];
  bool _isLoadingSalons = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedSalonId = widget.selectedSalonId;
    _selectedSalonName = widget.selectedSalonName;
    if (_selectedSalonName != null) {
      _salonSearchController.text = _selectedSalonName!;
    }
  }

  @override
  void dispose() {
    _salonSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchSalons(String query) async {
    if (query.isEmpty) {
      setState(() {
        _salons = [];
      });
      return;
    }

    setState(() {
      _isLoadingSalons = true;
    });

    try {
      final result = await SaloonsService.getSaloons(
        page: 1,
        limit: 20,
        search: query,
      );

      if (result['success'] == true) {
        setState(() {
          _salons = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoadingSalons = false;
        });
      } else {
        setState(() {
          _salons = [];
          _isLoadingSalons = false;
        });
      }
    } catch (e) {
      print('❌ Error searching salons: $e');
      setState(() {
        _salons = [];
        _isLoadingSalons = false;
      });
    }
  }

  String _formatDateForInput(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: Theme.of(context).brightness,
              primary: AppTheme.greenPrimary,
              onPrimary:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              secondary: AppTheme.greenPrimary,
              onSecondary:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              error: AppTheme.statusRed,
              onError: AppTheme.textPrimaryColor,
              surface:
                  AppTheme.getScaffoldBackground(Theme.of(context).brightness),
              onSurface:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: Theme.of(context).brightness,
              primary: AppTheme.greenPrimary,
              onPrimary:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              secondary: AppTheme.greenPrimary,
              onSecondary:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              error: AppTheme.statusRed,
              onError: AppTheme.textPrimaryColor,
              surface:
                  AppTheme.getScaffoldBackground(Theme.of(context).brightness),
              onSurface:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getScaffoldBackground(Theme.of(context).brightness),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'reports_filter'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          // Subtitle
          Text(
            AppTranslations.getString(context, 'select_influencer_period'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 24),
          // Date Range Row (Start and End in same row)
          Row(
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'filter_start'),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectStartDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.getScaffoldBackground(
                              Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatDateForInput(_startDate),
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'filter_end'),
                      style: TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectEndDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.getScaffoldBackground(
                              Theme.of(context).brightness),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _endDate.day == DateTime.now().day &&
                                  _endDate.month == DateTime.now().month &&
                                  _endDate.year == DateTime.now().year
                              ? AppTranslations.getString(context, 'today')
                              : _formatDateForInput(_endDate),
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // Salon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'saloon'),
                style: TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.getScaffoldBackground(
                      Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _salonSearchController,
                        onChanged: (value) {
                          _searchSalons(value);
                        },
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: AppTranslations.getString(
                              context, 'search_by_name'),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      LucideIcons.chevronDown,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Salon suggestions dropdown
          if (_salons.isNotEmpty || _isLoadingSalons)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: _isLoadingSalons
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _salons.length,
                      itemBuilder: (context, index) {
                        final salon = _salons[index];
                        final name = salon['name'] ?? 'Unknown';
                        return ListTile(
                          title: Text(
                            name,
                            style: TextStyle(
                              color: AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSalonId = salon['id'] as String?;
                              _selectedSalonName = name;
                              _salonSearchController.text = name;
                              _salons = [];
                            });
                          },
                        );
                      },
                    ),
            ),
          SizedBox(height: 32),
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withOpacity(0.3), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.transparentBackground
                            : AppTheme.textWhite54,
                  ),
                  child: Text(
                    AppTranslations.getString(context, 'cancel'),
                    style: TextStyle(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _startDate,
                      _endDate,
                      _selectedSalonId,
                      _selectedSalonName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightCardBackground,
                    foregroundColor: AppTheme.lightTextPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    AppTranslations.getString(context, 'apply_filter'),
                    style: TextStyle(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
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
}

// Area chart painter for revenue
class _RevenueAreaChartPainter extends CustomPainter {
  final List<dynamic> dailyRevenue;
  final Brightness brightness;

  _RevenueAreaChartPainter(
      {required this.dailyRevenue, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.greenPrimary.withOpacity(0.3), // Light green for area fill
          brightness == Brightness.dark
              ? AppTheme.transparentBackground
              : AppTheme.textWhite54,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.greenPrimary // Light green for line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Process daily revenue data
    List<double> revenueValues = [];
    if (dailyRevenue.isNotEmpty) {
      for (var day in dailyRevenue) {
        if (day is Map<String, dynamic>) {
          revenueValues.add((day['revenue'] ?? 0.0).toDouble());
        }
      }
    }

    // If no data, create sample data
    if (revenueValues.isEmpty) {
      revenueValues = [0.8, 0.6, 0.4, 0.3, 0.2, 0.1];
    }

    // Find max value for scaling
    double maxValue = revenueValues.isNotEmpty
        ? revenueValues.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxValue == 0) maxValue = 1.0;

    // Create smooth area chart
    final path = Path();
    final linePath = Path();

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

    if (dataPoints.isNotEmpty) {
      path.moveTo(dataPoints[0].dx, size.height);
      path.lineTo(dataPoints[0].dx, dataPoints[0].dy);
      linePath.moveTo(dataPoints[0].dx, dataPoints[0].dy);

      for (int i = 1; i < dataPoints.length; i++) {
        final current = dataPoints[i];
        final previous = dataPoints[i - 1];

        double tension = 0.3;
        double controlPointOffset = (current.dx - previous.dx) * tension;

        Offset controlPoint1, controlPoint2;

        if (i == 1) {
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else if (i == dataPoints.length - 1) {
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else {
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

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _RevenueAreaChartPainter) {
      return oldDelegate.dailyRevenue != dailyRevenue;
    }
    return true;
  }
}

// Area chart painter for orders
class _OrdersAreaChartPainter extends CustomPainter {
  final List<dynamic> dailyOrders;
  final Brightness brightness;

  _OrdersAreaChartPainter(
      {required this.dailyOrders, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.greenPrimary.withOpacity(0.3), // Light green for area fill
          brightness == Brightness.dark
              ? AppTheme.transparentBackground
              : AppTheme.textWhite54,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.greenPrimary // Light green for line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Process daily orders data
    List<double> orderValues = [];
    if (dailyOrders.isNotEmpty) {
      for (var day in dailyOrders) {
        if (day is Map<String, dynamic>) {
          orderValues.add((day['orders'] ?? 0.0).toDouble());
        }
      }
    }

    // If no data, create sample data
    if (orderValues.isEmpty) {
      orderValues = [0.7, 0.5, 0.3, 0.25, 0.15, 0.1];
    }

    // Find max value for scaling
    double maxValue = orderValues.isNotEmpty
        ? orderValues.reduce((a, b) => a > b ? a : b)
        : 1.0;
    if (maxValue == 0) maxValue = 1.0;

    // Create smooth area chart
    final path = Path();
    final linePath = Path();

    // Calculate data points
    List<Offset> dataPoints = [];
    for (int i = 0; i < orderValues.length; i++) {
      double x = (i / (orderValues.length - 1)) * size.width;
      double normalizedValue = orderValues[i] / maxValue;
      double y = size.height -
          (normalizedValue * size.height * 0.8) -
          (size.height * 0.1);
      dataPoints.add(Offset(x, y));
    }

    if (dataPoints.isNotEmpty) {
      path.moveTo(dataPoints[0].dx, size.height);
      path.lineTo(dataPoints[0].dx, dataPoints[0].dy);
      linePath.moveTo(dataPoints[0].dx, dataPoints[0].dy);

      for (int i = 1; i < dataPoints.length; i++) {
        final current = dataPoints[i];
        final previous = dataPoints[i - 1];

        double tension = 0.3;
        double controlPointOffset = (current.dx - previous.dx) * tension;

        Offset controlPoint1, controlPoint2;

        if (i == 1) {
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else if (i == dataPoints.length - 1) {
          controlPoint1 = Offset(
            previous.dx + controlPointOffset,
            previous.dy,
          );
          controlPoint2 = Offset(
            current.dx - controlPointOffset,
            current.dy,
          );
        } else {
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

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is _OrdersAreaChartPainter) {
      return oldDelegate.dailyOrders != dailyOrders;
    }
    return true;
  }
}
