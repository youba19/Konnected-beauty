import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/salon_wallet_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/common/shimmer_loading.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() =>
      _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _withdrawals.clear();
        _hasMoreData = true;
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final result = await SalonWalletService.getWithdrawalHistory(
        page: _currentPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });

        if (result['success'] == true) {
          try {
            final data = result['data'];
            print('📊 Withdrawal History Data: $data');
            print('📊 Data Type: ${data.runtimeType}');

            // The API returns data as a direct array, not wrapped in an object
            List<dynamic> withdrawals = [];
            if (data is List) {
              withdrawals = data;
            } else if (data is Map && data['withdrawals'] is List) {
              withdrawals = data['withdrawals'];
            } else if (data is Map && data['data'] is List) {
              withdrawals = data['data'];
            }
            print('📊 Withdrawals List: $withdrawals');

            // Extract pagination info from the original result
            final currentPageNum = _parseInt(result['currentPage']) ?? 1;
            final totalPagesNum = _parseInt(result['totalPages']) ?? 1;

            final pagination = {
              'totalPages': totalPagesNum,
              'currentPage': currentPageNum,
              'total': _parseInt(result['total']) ?? 0,
              'hasNextPage': currentPageNum < totalPagesNum,
            };
            print('📊 Pagination: $pagination');

            if (refresh) {
              _withdrawals = withdrawals;
            } else {
              _withdrawals.addAll(withdrawals);
            }

            _hasMoreData = _parseBool(pagination['hasNextPage']) ?? false;
            _currentPage++;
          } catch (e) {
            print('❌ Error processing withdrawal data: $e');
            _hasError = true;
            _errorMessage = 'Error processing withdrawal data: ${e.toString()}';

            TopNotificationService.showError(
              context: context,
              message: _errorMessage,
            );
          }
        } else {
          _hasError = true;
          _errorMessage =
              result['message'] ?? 'Failed to load withdrawal history';

          TopNotificationService.showError(
            context: context,
            message: _errorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasError = true;
          _errorMessage = 'Error loading withdrawal history: ${e.toString()}';
        });

        TopNotificationService.showError(
          context: context,
          message: _errorMessage,
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore && _hasMoreData) {
      setState(() {
        _isLoadingMore = true;
      });
      await _loadWithdrawals();
    }
  }

  Future<void> _refresh() async {
    await _loadWithdrawals(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // List Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppTheme.accentColor,
                  child: _buildListContent(),
                ),
              ),
            ],
          ),
        ),
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
            child: const Icon(
              LucideIcons.arrowLeft,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.getString(context, 'withdrawal_history'),
            style: const TextStyle(
              color: Colors.white,
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
    } else if (_hasError) {
      return _buildErrorContent();
    } else if (_withdrawals.isEmpty) {
      return _buildEmptyContent();
    } else {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _withdrawals.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _withdrawals.length) {
            return _buildLoadMoreButton();
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildWithdrawalCard(_withdrawals[index]),
          );
        },
      );
    }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ShimmerLoading(
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Amount shimmer
                    Container(
                      height: 18,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date shimmer
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side status shimmer
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
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
            color: AppTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: AppTheme.textPrimaryColor,
            ),
            child: Text(
              AppTranslations.getString(context, 'retry'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
              color: AppTheme.textSecondaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.getString(context, 'no_withdrawals_found'),
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    try {
      print('🔍 Processing withdrawal: $withdrawal');

      // Extract data from API response
      final id = _safeString(withdrawal['id']) ?? 'N/A';
      final amount = _parseDouble(withdrawal['amount']) ?? 0.0;
      final status = _safeString(withdrawal['status']) ?? 'unknown';
      final createdAt = _safeString(withdrawal['createdAt']) ?? '';
      final updatedAt = _safeString(withdrawal['updatedAt']) ?? '';

      // Format amount
      final formattedAmount = 'EUR ${_formatAmount(amount.toString())}';

      // Format date
      final formattedDate =
          _formatDate(createdAt.isNotEmpty ? createdAt : updatedAt);

      // Get status color
      final statusColor = _getStatusColor(status);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.transparentBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white,
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
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Amount
                  Text(
                    formattedAmount,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Date
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

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
    } catch (e) {
      print('❌ Error parsing withdrawal data: $e');
      print('❌ Withdrawal data: $withdrawal');

      // Return a safe fallback card
      return _buildErrorCard('Error loading withdrawal data');
    }
  }

  Widget _buildLoadMoreButton() {
    if (!_hasMoreData) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: _isLoadingMore
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                  strokeWidth: 2,
                ),
              ),
            )
          : Center(
              child: ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(AppTranslations.getString(context, 'load_more')),
              ),
            ),
    );
  }

  String? _safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
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
        return Colors.green;
      case 'pending':
      case 'requested':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return AppTheme.textPrimaryColor;
    }
  }
}
