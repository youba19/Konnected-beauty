import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/salon_wallet_service.dart';
import '../../../../core/services/api/influencers_service.dart';
import 'package:shimmer/shimmer.dart';

class SalonReportsScreen extends StatefulWidget {
  const SalonReportsScreen({super.key});

  @override
  State<SalonReportsScreen> createState() => _SalonReportsScreenState();
}

class _SalonReportsScreenState extends State<SalonReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _threeMonthsStats = {};

  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedInfluencerId;
  String? _selectedInfluencerName;
  List<Map<String, dynamic>> _influencersList = [];

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate =
        DateTime.now().subtract(const Duration(days: 90)); // 3 months before
    _loadInfluencers();
    _loadReportData();
  }

  Future<void> _loadInfluencers() async {
    try {
      print('👥 === LOADING INFLUENCERS FOR FILTER (COLLABORATED ONLY) ===');

      // First, get all salon campaigns to extract influencer IDs
      final campaignsResult = await InfluencersService.getSalonCampaigns(
        page: 1,
        limit: 1000, // Get a large number to get all campaigns
      );

      if (!mounted) return;

      if (campaignsResult['success'] != true) {
        print('❌ Failed to load campaigns: ${campaignsResult['message']}');
        setState(() {
          _influencersList = [];
        });
        return;
      }

      final campaigns =
          List<Map<String, dynamic>>.from(campaignsResult['data'] ?? []);
      print('📊 Loaded ${campaigns.length} campaigns');

      // Extract unique influencer IDs from campaigns
      final Set<String> influencerIds = {};
      for (final campaign in campaigns) {
        // Try different possible structures for influencer ID
        final influencer = campaign['influencer'];
        if (influencer != null) {
          if (influencer is Map<String, dynamic>) {
            // Check for id or _id in influencer object
            final id = influencer['id']?.toString() ??
                influencer['_id']?.toString() ??
                '';
            if (id.isNotEmpty) {
              influencerIds.add(id);
              print('👤 Found influencer ID from campaign: $id');
            }
          } else if (influencer is String) {
            influencerIds.add(influencer);
            print('👤 Found influencer ID as string: $influencer');
          }
        }

        // Also check for receiverId, receiver, or initiator fields
        final receiverId = campaign['receiverId']?.toString() ??
            campaign['receiver']?.toString() ??
            '';
        if (receiverId.isNotEmpty) {
          influencerIds.add(receiverId);
          print('👤 Found influencer ID from receiver: $receiverId');
        }

        // Check if initiator is 'influencer' and there's a receiver
        final initiator = campaign['initiator']?.toString() ?? '';
        if (initiator == 'influencer') {
          final receiver = campaign['receiverId']?.toString() ??
              campaign['receiver']?.toString() ??
              '';
          if (receiver.isNotEmpty) {
            influencerIds.add(receiver);
            print('👤 Found influencer ID from initiator: $receiver');
          }
        }
      }

      print(
          '👥 Found ${influencerIds.length} unique influencer IDs from campaigns');
      print('👥 Influencer IDs: $influencerIds');

      if (influencerIds.isEmpty) {
        print('⚠️ No influencers found in campaigns');
        setState(() {
          _influencersList = [];
        });
        return;
      }

      // Now fetch details for these specific influencers
      final List<Map<String, dynamic>> collaboratedInfluencers = [];

      for (final influencerId in influencerIds) {
        try {
          // Try to get influencer details by ID
          final influencerResult =
              await InfluencersService.getInfluencerDetails(influencerId);
          if (influencerResult['success'] == true &&
              influencerResult['data'] != null) {
            collaboratedInfluencers
                .add(influencerResult['data'] as Map<String, dynamic>);
          }
        } catch (e) {
          print('⚠️ Error fetching influencer $influencerId: $e');
        }
      }

      print(
          '👥 Loaded ${collaboratedInfluencers.length} collaborated influencers');
      if (collaboratedInfluencers.isNotEmpty) {
        print('👥 First influencer structure: ${collaboratedInfluencers[0]}');
        print(
            '👥 First influencer ID: ${collaboratedInfluencers[0]['id'] ?? collaboratedInfluencers[0]['_id']}');
      }

      setState(() {
        _influencersList = collaboratedInfluencers;
      });
    } catch (e) {
      print('❌ Error loading influencers: $e');
      if (mounted) {
        setState(() {
          _influencersList = [];
        });
      }
    }
  }

  Future<void> _loadReportData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('📊 === LOADING SALON REPORT DATA ===');
      print('📅 Start Date: $_startDate');
      print('📅 End Date: $_endDate');
      print('👤 Influencer ID: $_selectedInfluencerId');

      // Always use filtered API with dates (default dates if not set)
      final startDate = _startDate ??
          DateTime.now().subtract(const Duration(days: 90)); // 3 months before
      final endDate = _endDate ?? DateTime.now();

      print('📊 Using dates for API call:');
      print('📅 Start Date: $startDate');
      print('📅 End Date: $endDate');
      print('👤 Influencer ID: $_selectedInfluencerId');
      print('👤 Influencer ID Type: ${_selectedInfluencerId.runtimeType}');
      print('👤 Influencer ID is null: ${_selectedInfluencerId == null}');
      print(
          '👤 Influencer ID is empty: ${_selectedInfluencerId?.isEmpty ?? true}');

      final results = await Future.wait([
        SalonWalletService.getStatsWithFilters(
          startDate: startDate,
          endDate: endDate,
          influencerId: _selectedInfluencerId,
        ),
        SalonWalletService.getThreeMonthsStats(),
      ]);

      final statsResult = results[0];
      final threeMonthsResult = results[1];

      if (mounted) {
        if (statsResult['success'] == true) {
          _stats = statsResult['stats'] as Map<String, dynamic>;
          print('📊 Report stats loaded successfully: $_stats');
        } else {
          _stats = {};
          print('❌ Failed to load report stats: ${statsResult['message']}');
        }

        if (threeMonthsResult['success'] == true) {
          _threeMonthsStats =
              threeMonthsResult['threeMonthsStats'] as Map<String, dynamic>;
          print(
              '📈 Three-months stats loaded successfully: $_threeMonthsStats');
        } else {
          _threeMonthsStats = {};
          print(
              '❌ Failed to load three-months stats: ${threeMonthsResult['message']}');
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
          _threeMonthsStats = {};
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###.00');
    return '€ ${formatter.format(value)}';
  }

  String _formatNumber(int value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  String _formatPercentage(double value) {
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}%';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MM/dd/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getChangeColor(double change) {
    if (change > 0) return const Color(0xFF22C55E); // Green
    if (change < 0) return const Color(0xFFEF4444); // Red
    return Colors.white.withOpacity(0.7); // Neutral
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1F1E1E),
        body: Container(
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
          child: SafeArea(
            child: _isLoading ? _buildShimmerContent() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[600]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 100, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 16, width: 150, color: Colors.white),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Container(height: 120, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(height: 200, color: Colors.white),
                const SizedBox(height: 24),
                Container(height: 200, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: Colors.white,
      backgroundColor: const Color(0xFF3A3A3A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Metrics Grid
            _buildMetricsGrid(),
            const SizedBox(height: 24),

            // Charts
            _buildChartsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        // Title and Filter Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.getString(context, 'reports'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppTranslations.getString(context, 'filter_from')} ${_getStartDate()} ${AppTranslations.getString(context, 'filter_to')} ${_getEndDate()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
              ),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          ],
        ),
      ],
    );
  }

  String _getStartDate() {
    if (_startDate != null) {
      return DateFormat('MM/dd/yyyy').format(_startDate!);
    }
    return '01/01/2025';
  }

  String _getEndDate() {
    if (_endDate != null) {
      return DateFormat('MM/dd/yyyy').format(_endDate!);
    }
    return DateFormat('MM/dd/yyyy').format(DateTime.now());
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    String? tempSelectedInfluencerId = _selectedInfluencerId;
    String? tempSelectedInfluencerName = _selectedInfluencerName;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'reports_filter'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                      context, 'select_influencer_period'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Start Date
                Text(
                  AppTranslations.getString(context, 'filter_start'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        tempStartDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tempStartDate != null
                          ? DateFormat('MM/dd/yyyy').format(tempStartDate!)
                          : AppTranslations.getString(context, 'filter_start'),
                      style: TextStyle(
                        color: tempStartDate != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date
                Text(
                  AppTranslations.getString(context, 'filter_end'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark(),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        tempEndDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tempEndDate != null
                          ? (tempEndDate!.year == DateTime.now().year &&
                                  tempEndDate!.month == DateTime.now().month &&
                                  tempEndDate!.day == DateTime.now().day
                              ? AppTranslations.getString(context, 'today')
                              : DateFormat('MM/dd/yyyy').format(tempEndDate!))
                          : AppTranslations.getString(context, 'filter_end'),
                      style: TextStyle(
                        color: tempEndDate != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Influencer Dropdown
                Text(
                  AppTranslations.getString(context, 'filter_influencer'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tempSelectedInfluencerId,
                      isExpanded: true,
                      hint: Text(
                        AppTranslations.getString(context, 'search_by_name'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            AppTranslations.getString(
                                context, 'search_by_name'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                        ..._influencersList
                            .map((influencer) {
                              // Try different possible ID fields
                              final id = influencer['id']?.toString() ??
                                  influencer['_id']?.toString() ??
                                  '';
                              final profile = influencer['profile'] ?? {};
                              final pseudo = profile['pseudo'] ??
                                  AppTranslations.getString(context, 'unknown');

                              print(
                                  '👤 Influencer in dropdown: pseudo=$pseudo, id=$id');

                              return DropdownMenuItem<String>(
                                value: id.isNotEmpty ? id : null,
                                child: Text(
                                  pseudo,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            })
                            .where((item) => item.value != null)
                            .toList(),
                      ],
                      onChanged: (String? newValue) {
                        print('🔍 === INFLUENCER SELECTED IN DROPDOWN ===');
                        print('🔍 Selected Value: $newValue');
                        print('🔍 Type: ${newValue.runtimeType}');

                        setModalState(() {
                          tempSelectedInfluencerId = newValue;
                          if (newValue != null && newValue.isNotEmpty) {
                            final influencer = _influencersList.firstWhere(
                              (inf) {
                                final infId = inf['id']?.toString() ??
                                    inf['_id']?.toString() ??
                                    '';
                                return infId == newValue;
                              },
                              orElse: () => {},
                            );

                            print('🔍 Found Influencer: $influencer');
                            print(
                                '🔍 Influencer ID: ${influencer['id'] ?? influencer['_id']}');

                            tempSelectedInfluencerName =
                                influencer['profile']?['pseudo'] ?? '';
                            print(
                                '🔍 Influencer Name: $tempSelectedInfluencerName');
                          } else {
                            tempSelectedInfluencerName = null;
                            print('🔍 No influencer selected');
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
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
                        onPressed: () {
                          print('🔍 === APPLYING FILTERS ===');
                          print('🔍 Temp Start Date: $tempStartDate');
                          print('🔍 Temp End Date: $tempEndDate');
                          print(
                              '🔍 Temp Influencer ID: $tempSelectedInfluencerId');

                          setState(() {
                            _startDate = tempStartDate;
                            _endDate = tempEndDate;
                            _selectedInfluencerId = tempSelectedInfluencerId;
                            _selectedInfluencerName =
                                tempSelectedInfluencerName;
                          });

                          print('🔍 Applied Start Date: $_startDate');
                          print('🔍 Applied End Date: $_endDate');
                          print(
                              '🔍 Applied Influencer ID: $_selectedInfluencerId');

                          Navigator.pop(context);
                          _loadReportData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppTranslations.getString(context, 'apply_filter'),
                          style: const TextStyle(
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
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid() {
    final totalRevenue = _stats['totalRevenue'] ?? 0.0;
    final totalRevenueChange = _stats['totalRevenueChange'] ?? 0.0;
    final totalOrderCount = _stats['totalOrderCount'] ?? 0;
    final totalOrderCountChange = _stats['totalOrderCountChange'] ?? 0.0;
    final totalCampaigns = _stats['totalCampaigns'] ?? 0;
    final totalCampaignsChange = _stats['totalCampaignsChange'] ?? 0.0;
    final pendingWithdrawl = _stats['pendingWithdrawl'] ?? {};
    final pendingAmount = (pendingWithdrawl['amoount'] ?? 0.0).toDouble();
    final pendingSince = pendingWithdrawl['since'] ?? '';
    final avgOrderValue = _stats['averageOrderValue'] ?? 0.0;
    final avgOrderValueChange = _stats['averageOrderValueChange'] ?? 0.0;
    final avgPromotion = _stats['avgPromotion'] ?? 0.0;
    final avgPromotionChange = _stats['avgPromotionChange'] ?? 0.0;
    final totalInfluencers = _stats['totalInfluencers'] ?? 0;
    final totalInfluencersChange = _stats['totalInfluencersChange'] ?? 0.0;

    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: AppTranslations.getString(context, 'total_revenue'),
                value: _formatCurrency(totalRevenue),
                change: totalRevenueChange,
                changeLabel:
                    AppTranslations.getString(context, 'from_last_month'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: AppTranslations.getString(context, 'number_orders'),
                value: _formatNumber(totalOrderCount),
                change: totalOrderCountChange,
                changeLabel:
                    AppTranslations.getString(context, 'from_last_month'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: AppTranslations.getString(context, 'total_campaigns'),
                value: totalCampaigns.toString(),
                change: totalCampaignsChange,
                changeLabel:
                    AppTranslations.getString(context, 'from_last_month'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: AppTranslations.getString(context, 'pending_withdraw'),
                value: _formatCurrency(pendingAmount),
                subtitle: pendingSince.isNotEmpty
                    ? '${AppTranslations.getString(context, 'since')} ${_formatDate(pendingSince)}'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: AppTranslations.getString(context, 'avg_order_value'),
                value: _formatCurrency(avgOrderValue),
                change: avgOrderValueChange,
                changeLabel:
                    AppTranslations.getString(context, 'from_last_month'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title:
                    AppTranslations.getString(context, 'avg_promotion_percent'),
                value: '${avgPromotion.toStringAsFixed(0)}%',
                change: avgPromotionChange,
                changeLabel:
                    AppTranslations.getString(context, 'from_last_month'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fourth row - full width
        _buildMetricCard(
          title: AppTranslations.getString(
              context, 'total_influencers_worked_with'),
          value: totalInfluencers.toString(),
          change: totalInfluencersChange,
          changeLabel: AppTranslations.getString(context, 'from_last_month'),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    double? change,
    String? changeLabel,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (change != null && changeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatPercentage(change)} $changeLabel',
              style: TextStyle(
                color: _getChangeColor(change),
                fontSize: 12,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // Orders Chart
        _buildChartCard(
          title: AppTranslations.getString(context, 'orders'),
          subtitle: AppTranslations.getString(context, 'from_last_3_months'),
          trend: _threeMonthsStats['orderTrend'],
        ),
        const SizedBox(height: 24),
        // Revenue Chart
        _buildChartCard(
          title: AppTranslations.getString(context, 'revenue'),
          subtitle: AppTranslations.getString(context, 'from_last_3_months'),
          trend: _threeMonthsStats['revenueTrend'],
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Map<String, dynamic>? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _ReportChartPainter(
                trend: trend,
                isRevenue: title.toLowerCase() == 'revenue',
              ),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportChartPainter extends CustomPainter {
  final Map<String, dynamic>? trend;
  final bool isRevenue;

  _ReportChartPainter({
    required this.trend,
    required this.isRevenue,
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

    // Get trends data
    List<Map<String, dynamic>> trends = [];
    List<String> xLabels = [];
    List<double> yLabels = [20, 15, 10, 5, 0];

    if (trend != null && trend!['trends'] != null) {
      trends = List<Map<String, dynamic>>.from(trend!['trends']);
      if (trends.isNotEmpty) {
        xLabels = trends.map((t) => t['month']?.toString() ?? '').toList();
        // Calculate Y-axis labels based on max value
        final maxValue = trends
            .map((t) => (t['value'] ?? 0).toDouble())
            .reduce((a, b) => a > b ? a : b);
        if (maxValue > 0) {
          yLabels = [
            maxValue,
            maxValue * 0.75,
            maxValue * 0.5,
            maxValue * 0.25,
            0
          ];
        }
      }
    }

    // Y-axis labels
    final uniqueLabels = <String>[];
    for (int i = 0; i <= gridLines; i++) {
      final label = isRevenue
          ? '${(yLabels[i] / 1000).toStringAsFixed(0)}K'
          : yLabels[i].toStringAsFixed(0);
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
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, dy - textPainter.height / 2),
      );
    }

    // X-axis labels
    final xPositions = [0.15, 0.5, 0.9];
    final zeroLineY = size.height * 0.95;
    final labelOffset = 15.0;
    for (int i = 0; i < xLabels.length && i < xPositions.length; i++) {
      final x = padding + (size.width - 2 * padding) * xPositions[i];
      final textPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, zeroLineY + labelOffset),
      );
    }

    // Data points
    final chartWidth = size.width - padding;
    List<Offset> dataPoints = [];

    if (trends.isNotEmpty) {
      final maxValue = yLabels[0];
      for (int i = 0; i < trends.length && i < xPositions.length; i++) {
        final value = (trends[i]['value'] ?? 0).toDouble();
        double normalizedY;
        if (maxValue > 0) {
          normalizedY = (maxValue - value) / maxValue;
        } else {
          normalizedY = 0.5;
        }
        final x = padding + (chartWidth * xPositions[i]);
        final y = size.height * (0.05 + normalizedY * 0.9);
        dataPoints.add(Offset(x, y));
      }
    }

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (dataPoints.length >= 2) {
      final path = Path();
      path.moveTo(dataPoints[0].dx, dataPoints[0].dy);
      for (int i = 1; i < dataPoints.length; i++) {
        path.lineTo(dataPoints[i].dx, dataPoints[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw points
      final pointPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..style = PaintingStyle.fill;
      for (final point in dataPoints) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
