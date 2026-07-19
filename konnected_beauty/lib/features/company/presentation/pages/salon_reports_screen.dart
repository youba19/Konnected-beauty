import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/salon_wallet_service.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Reports screen layout tokens (colors via [SalonUiTheme]).
abstract final class _SalonReportsUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
  static const double metricCardHeight = 120;
}

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

  Color _getChangeColor(double change) {
    return const Color(0xFF5B8FD9);
  }

  @override
  Widget build(BuildContext context) {
    final ui = SalonUiTheme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ui.systemOverlay,
      child: Scaffold(
        backgroundColor: ui.bg,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ui.fullSheetGradient,
                    stops: ui.fullSheetStops,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _isLoading
                  ? _buildShimmerContent(ui)
                  : _buildContent(ui),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContent(SalonUiTheme ui) {
    final baseColor = ui.isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = ui.isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final placeholderColor =
        ui.isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.08);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(ui),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 28,
                  width: 140,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius:
                              BorderRadius.circular(_SalonReportsUi.radius),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius:
                              BorderRadius.circular(_SalonReportsUi.radius),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius:
                              BorderRadius.circular(_SalonReportsUi.radius),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: placeholderColor,
                          borderRadius:
                              BorderRadius.circular(_SalonReportsUi.radius),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(_SalonReportsUi.radius),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(_SalonReportsUi.radius),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SalonUiTheme ui) {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: Colors.white,
      backgroundColor: SalonUiTheme.blueUpper,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(ui),
            const SizedBox(height: 24),
            _buildMetricsGrid(ui),
            const SizedBox(height: 28),
            _buildChartsSection(ui),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _SalonReportsUi.buttonSize,
        height: _SalonReportsUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.buttonFillTop,
              ui.buttonFillBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(_SalonReportsUi.buttonRadius),
          border: Border.all(color: ui.cardBorder, width: 1),
        ),
        child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildHeader(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildBackButton(ui),
            const Spacer(),
            GestureDetector(
              onTap: _showFilterDialog,
              child: Container(
                width: _SalonReportsUi.buttonSize,
                height: _SalonReportsUi.buttonSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ui.buttonFillTop,
                      ui.buttonFillBottom,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(_SalonReportsUi.buttonRadius),
                  border: Border.all(
                    color: ui.cardBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  LucideIcons.listFilter,
                  color: ui.buttonIcon,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          AppTranslations.getString(context, 'reports'),
          style: TextStyle(
            color: ui.isDark ? Colors.white : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppTranslations.getString(context, 'filter_from')} ${_getStartDate()} ${AppTranslations.getString(context, 'filter_to')} ${_getEndDate()}',
          style: TextStyle(
            color: ui.isDark ? Colors.white70 : Colors.black,
            fontSize: 14,
          ),
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
        final ui = SalonUiTheme.of(context);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ui.fullSheetGradient,
              stops: ui.headerStops,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.getString(context, 'reports_filter'),
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ui.sheetOverlayButton,
                          borderRadius: BorderRadius.circular(
                            _SalonReportsUi.buttonRadius,
                          ),
                          border: Border.all(
                            color: ui.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.x,
                          color: ui.isDark ? Colors.white : Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppTranslations.getString(
                      context, 'select_influencer_period'),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white70 : Colors.black,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Start Date
                Text(
                  AppTranslations.getString(context, 'filter_start'),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
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
                        final pickerUi = SalonUiTheme.of(context);
                        return Theme(
                          data: pickerUi.isDark
                              ? ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: SalonUiTheme.accentBlue,
                                    surface: pickerUi.card,
                                  ),
                                )
                              : ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: SalonUiTheme.accentBlue,
                                    surface: pickerUi.card,
                                  ),
                                ),
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
                      color: ui.card,
                      borderRadius:
                          BorderRadius.circular(_SalonReportsUi.radius),
                      border: Border.all(
                        color: ui.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tempStartDate != null
                          ? DateFormat('MM/dd/yyyy').format(tempStartDate!)
                          : AppTranslations.getString(context, 'filter_start'),
                      style: TextStyle(
                        color: tempStartDate != null
                            ? (ui.isDark ? Colors.white : Colors.black)
                            : (ui.isDark ? Colors.white54 : Colors.black),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End Date
                Text(
                  AppTranslations.getString(context, 'filter_end'),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
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
                        final pickerUi = SalonUiTheme.of(context);
                        return Theme(
                          data: pickerUi.isDark
                              ? ThemeData.dark().copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: SalonUiTheme.accentBlue,
                                    surface: pickerUi.card,
                                  ),
                                )
                              : ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: SalonUiTheme.accentBlue,
                                    surface: pickerUi.card,
                                  ),
                                ),
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
                      color: ui.card,
                      borderRadius:
                          BorderRadius.circular(_SalonReportsUi.radius),
                      border: Border.all(
                        color: ui.cardBorder,
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
                            ? (ui.isDark ? Colors.white : Colors.black)
                            : (ui.isDark ? Colors.white54 : Colors.black),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Influencer Dropdown
                Text(
                  AppTranslations.getString(context, 'filter_influencer'),
                  style: TextStyle(
                    color: ui.isDark ? Colors.white : Colors.black,
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
                    color: ui.card,
                    borderRadius: BorderRadius.circular(_SalonReportsUi.radius),
                    border: Border.all(
                      color: ui.cardBorder,
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
                          color: ui.isDark ? Colors.white54 : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      icon: Icon(
                        LucideIcons.chevronDown,
                        color: ui.isDark ? Colors.white : Colors.black,
                        size: 18,
                      ),
                      style: TextStyle(
                        color: ui.isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      dropdownColor: ui.card,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            AppTranslations.getString(
                                context, 'search_by_name'),
                            style: TextStyle(
                              color: ui.isDark ? Colors.white54 : Colors.black,
                            ),
                          ),
                        ),
                        ..._influencersList
                            .map((influencer) {
                              final id = influencer['id']?.toString() ??
                                  influencer['_id']?.toString() ??
                                  '';
                              final profile = influencer['profile'] ?? {};
                              final pseudo = profile['pseudo'] ??
                                  AppTranslations.getString(context, 'unknown');

                              return DropdownMenuItem<String>(
                                value: id.isNotEmpty ? id : null,
                                child: Text(
                                  pseudo,
                                  style: TextStyle(color: ui.isDark ? Colors.white : Colors.black),
                                ),
                              );
                            })
                            .where((item) => item.value != null)
                            .toList(),
                      ],
                      onChanged: (String? newValue) {
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
                            tempSelectedInfluencerName =
                                influencer['profile']?['pseudo'] ?? '';
                          } else {
                            tempSelectedInfluencerName = null;
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
                          side: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _SalonReportsUi.buttonRadius,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          AppTranslations.getString(context, 'cancel'),
                          style: TextStyle(
                            color: ui.isDark ? Colors.white : Colors.black,
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
                          setState(() {
                            _startDate = tempStartDate;
                            _endDate = tempEndDate;
                            _selectedInfluencerId = tempSelectedInfluencerId;
                            _selectedInfluencerName =
                                tempSelectedInfluencerName;
                          });

                          Navigator.pop(context);
                          _loadReportData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ui.primaryButtonBg,
                          foregroundColor: ui.primaryButtonFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _SalonReportsUi.buttonRadius,
                            ),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildMetricsGrid(SalonUiTheme ui) {
    final totalRevenue = _stats['totalRevenue'] ?? 0.0;
    final totalRevenueChange = _stats['totalRevenueChange'] ?? 0.0;
    final totalOrderCount = _stats['totalOrderCount'] ?? 0;
    final totalOrderCountChange = _stats['totalOrderCountChange'] ?? 0.0;
    final totalCampaigns = _stats['totalCampaigns'] ?? 0;
    final totalCampaignsChange = _stats['totalCampaignsChange'] ?? 0.0;
    final avgOrderValue = _stats['averageOrderValue'] ?? 0.0;
    final avgOrderValueChange = _stats['averageOrderValueChange'] ?? 0.0;
    final avgPromotion = _stats['avgPromotion'] ?? 0.0;
    final avgPromotionChange = _stats['avgPromotionChange'] ?? 0.0;
    final totalInfluencers = _stats['totalInfluencers'] ?? 0;
    final totalInfluencersChange = _stats['totalInfluencersChange'] ?? 0.0;

    return Column(
      children: [
        _buildMetricRow([
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(context, 'total_revenue'),
            value: _formatCurrency(totalRevenue),
            change: totalRevenueChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(context, 'number_orders'),
            value: _formatNumber(totalOrderCount),
            change: totalOrderCountChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
        ]),
        const SizedBox(height: 12),
        _buildMetricRow([
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(context, 'total_campaigns'),
            value: totalCampaigns.toString(),
            change: totalCampaignsChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(context, 'avg_order_value'),
            value: _formatCurrency(avgOrderValue),
            change: avgOrderValueChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
        ]),
        const SizedBox(height: 12),
        _buildMetricRow([
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(context, 'avg_promotion_percent'),
            value: '${avgPromotion.toStringAsFixed(0)}%',
            change: avgPromotionChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
          _buildMetricCard(
            ui: ui,
            title: AppTranslations.getString(
              context,
              'total_influencers_worked_with',
            ),
            value: totalInfluencers.toString(),
            change: totalInfluencersChange,
            changeLabel: AppTranslations.getString(context, 'from_last_month'),
          ),
        ]),
      ],
    );
  }

  Widget _buildMetricRow(List<Widget> cards) {
    return SizedBox(
      height: _SalonReportsUi.metricCardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required SalonUiTheme ui,
    required String title,
    required String value,
    double? change,
    String? changeLabel,
    String? subtitle,
    bool accentSubtitle = false,
  }) {
    final footerText = change != null && changeLabel != null
        ? '${_formatPercentage(change)} $changeLabel'
        : subtitle;
    final footerColor = change != null
        ? _getChangeColor(change)
        : (accentSubtitle
            ? SalonUiTheme.profileBlue
            : (ui.isDark ? Colors.white54 : Colors.black));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_SalonReportsUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ui.isDark ? Colors.white70 : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: footerText == null
                ? const SizedBox.shrink()
                : Text(
                    footerText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: footerColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(SalonUiTheme ui) {
    return Column(
      children: [
        _buildChartCard(
          ui: ui,
          title: AppTranslations.getString(context, 'orders'),
          subtitle: AppTranslations.getString(context, 'from_last_3_months'),
          trend: _threeMonthsStats['orderTrend'],
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          ui: ui,
          title: AppTranslations.getString(context, 'revenue'),
          subtitle: AppTranslations.getString(context, 'from_last_3_months'),
          trend: _threeMonthsStats['revenueTrend'],
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required SalonUiTheme ui,
    required String title,
    required String subtitle,
    required Map<String, dynamic>? trend,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_SalonReportsUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: ui.isDark ? Colors.white70 : Colors.black,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: _ReportChartPainter(
                trend: trend,
                isRevenue: title.toLowerCase() == 'revenue' ||
                    title.toLowerCase() == 'revenus',
                labelColor: ui.isDark ? Colors.white : Colors.black,
                axisLabelColor: ui.isDark ? Colors.white54 : Colors.black,
                gridColor: (ui.isDark ? Colors.white54 : Colors.black).withValues(alpha: 0.25),
              ),
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
  final Color labelColor;
  final Color axisLabelColor;
  final Color gridColor;

  _ReportChartPainter({
    required this.trend,
    required this.isRevenue,
    required this.labelColor,
    required this.axisLabelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: labelColor,
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
            color: axisLabelColor,
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
      ..color = const Color(0xFF3B6FD4)
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
        ..color = const Color(0xFF3B6FD4)
        ..style = PaintingStyle.fill;
      for (final point in dataPoints) {
        canvas.drawCircle(point, 4, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReportChartPainter oldDelegate) {
    return oldDelegate.trend != trend ||
        oldDelegate.isRevenue != isRevenue ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.axisLabelColor != axisLabelColor ||
        oldDelegate.gridColor != gridColor;
  }
}
