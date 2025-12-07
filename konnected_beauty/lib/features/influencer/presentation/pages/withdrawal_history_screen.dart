import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/shimmer_loading.dart';
import '../../../../core/services/api/http_interceptor.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _withdrawals = [];
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadWithdrawalHistory();
  }

  Future<void> _loadWithdrawalHistory({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        setState(() {
          _currentPage = 1;
          _withdrawals.clear();
          _isLoading = true;
          _errorMessage = '';
        });
      }

      print('💰 === LOADING WITHDRAWAL HISTORY ===');
      print('💰 Page: $_currentPage');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/influencer-withdrawals',
        queryParameters: {
          'page': _currentPage,
          'limit': 10,
        },
      );

      print(
          '💰 Withdrawal History API Response Status: ${response.statusCode}');
      print('💰 Withdrawal History API Response Body: ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (responseData['statusCode'] == 200) {
            // The data field contains a list of withdrawals directly
            final withdrawalsList =
                List<Map<String, dynamic>>.from(responseData['data'] ?? []);
            final currentPage =
                int.tryParse(responseData['currentPage']?.toString() ?? '1') ??
                    1;
            final totalPages = responseData['totalPages'] ?? 1;

            setState(() {
              if (isRefresh) {
                _withdrawals = withdrawalsList;
              } else {
                _withdrawals.addAll(withdrawalsList);
              }
              _currentPage = currentPage;
              _totalPages = totalPages;
              _hasMore = _currentPage < _totalPages;
              _isLoading = false;
              _isLoadingMore = false;
              _errorMessage = '';
            });

            print('💰 Withdrawals loaded: ${_withdrawals.length}');
            print('💰 Current Page: $_currentPage');
            print('💰 Total Pages: $_totalPages');
            print('💰 Has More: $_hasMore');
          } else {
            setState(() {
              _isLoading = false;
              _isLoadingMore = false;
              _errorMessage = responseData['message'] ??
                  'Failed to load withdrawal history';
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = 'Failed to load withdrawal history';
          });
        }
      }
    } catch (e) {
      print('❌ Error loading withdrawal history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Error loading withdrawal history: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadMoreWithdrawals() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadWithdrawalHistory();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      body: Stack(
        children: [
          // Green gradient at top
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

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // List Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadWithdrawalHistory(isRefresh: true),
                    child: _buildListContent(),
                  ),
                ),
              ],
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              size: 24,
            ),
          ),
          SizedBox(height: 16),
          Text(
            AppTranslations.getString(context, 'withdrawal_history'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_isLoading) {
      return _buildLoadingContent();
    } else if (_errorMessage.isNotEmpty) {
      return _buildErrorContent();
    } else if (_withdrawals.isEmpty) {
      return _buildEmptyContent();
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _withdrawals.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _withdrawals.length) {
            // Load more button
            return Container(
              margin: const EdgeInsets.only(top: 16, bottom: 20),
              child: _isLoadingMore
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _loadMoreWithdrawals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.transparentBackground
                                : AppTheme.textWhite54,
                        foregroundColor: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        side: BorderSide(
                            color: AppTheme.getBorderColor(
                                Theme.of(context).brightness)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppTranslations.getString(context, 'load_more'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildWithdrawalCard(_withdrawals[index]),
          );
        },
      );
    }
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              AppTranslations.getString(context, 'no_withdrawals_found'),
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) {
          return _buildShimmerCard();
        }),
      ),
    );
  }

  Widget _buildShimmerCard() {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ShimmerLoading(
        baseColor: brightness == Brightness.light
            ? AppTheme.lightBannerBackground
            : null,
        highlightColor: brightness == Brightness.light
            ? AppTheme.lightCardBackground
            : null,
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: brightness == Brightness.light
                ? AppTheme.lightCardBackground
                : AppTheme.transparentBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.getBorderColor(brightness),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Left side shimmer content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ID shimmer
                    Container(
                      height: 14,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    // Amount shimmer
                    Container(
                      height: 18,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Date shimmer
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              // Right side status shimmer
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadWithdrawalHistory(isRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor:
                  AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            ),
            child: Text(
              AppTranslations.getString(context, 'retry'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    // Extract data from API response
    final id = withdrawal['id']?.toString() ?? 'N/A';
    final amount = withdrawal['amount']?.toString() ?? '0';
    final status = withdrawal['status']?.toString() ?? 'unknown';
    final createdAt = withdrawal['createdAt']?.toString() ?? '';
    final updatedAt = withdrawal['updatedAt']?.toString() ?? '';

    // Format amount
    final formattedAmount = 'EUR ${_formatAmount(amount)}';

    // Format date
    final formattedDate =
        _formatDate(createdAt.isNotEmpty ? createdAt : updatedAt);

    // Get status color
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.transparentBackground
            : AppTheme.textWhite54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getBorderColor(Theme.of(context).brightness),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left side - ID, Amount, Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Transaction ID
                Text(
                  id.length > 8 ? '${id.substring(0, 8)}...' : id,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),

                // Amount
                Text(
                  formattedAmount,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),

                // Date
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Right side - Status
          Text(
            AppTranslations.getString(context, status),
            style: TextStyle(
              color: statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  String _formatAmount(String amount) {
    try {
      final value = double.parse(amount);
      if (value == value.toInt()) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(2);
      }
    } catch (e) {
      return '0';
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return AppTranslations.getString(context, 'yesterday');
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${AppTranslations.getString(context, 'days_ago')}';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
      case 'approved':
        return AppTheme.statusGreen;
      case 'pending':
      case 'requested':
        return AppTheme.statusOrange;
      case 'rejected':
      case 'cancelled':
        return AppTheme.statusRed;
      case 'processing':
        return AppTheme.statusBlue;
      default:
        return AppTheme.getTextPrimaryColor(Theme.of(context).brightness);
    }
  }
}
