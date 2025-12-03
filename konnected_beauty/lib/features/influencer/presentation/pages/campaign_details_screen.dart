import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_bloc.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_event.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_state.dart';
import '../../../../core/bloc/campaign_actions/campaign_actions_bloc.dart';
import '../../../../core/bloc/campaign_actions/campaign_actions_event.dart';
import '../../../../core/bloc/campaign_actions/campaign_actions_state.dart';
import '../../../../core/services/api/http_interceptor.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback? onCampaignDeleted;

  const CampaignDetailsScreen({
    super.key,
    required this.campaign,
    this.onCampaignDeleted,
  });

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  bool _isLoadingDetails = false;
  String? _campaignLink;
  String _totalAmount = '0';
  String _totalCompletedOrders = '0';

  @override
  void initState() {
    super.initState();
    _fetchCampaignDetails();
  }

  Future<void> _fetchCampaignDetails() async {
    final campaignId = widget.campaign['id'];
    if (campaignId == null) return;

    setState(() {
      _isLoadingDetails = true;
    });

    try {
      print('📋 === FETCHING CAMPAIGN DETAILS ===');
      print('📋 Campaign ID: $campaignId');

      final response = await HttpInterceptor.authenticatedRequest(
        method: 'GET',
        endpoint: '/campaign/influencer-campaign/$campaignId',
      );

      print('📋 Campaign Details API Response Status: ${response.statusCode}');
      print('📋 Campaign Details API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['statusCode'] == 200 &&
            responseData['message'] == 'success') {
          final campaignData = responseData['data'] as Map<String, dynamic>;

          setState(() {
            _campaignLink = campaignData['link'];
            _totalAmount = campaignData['totalAmount']?.toString() ?? '0';
            _totalCompletedOrders =
                campaignData['totalCompletedOrders']?.toString() ?? '0';
            _isLoadingDetails = false;
          });

          print('✅ Campaign details fetched successfully');
          print('📋 Link: $_campaignLink');
          print('📋 Total Amount: $_totalAmount');
          print('📋 Total Completed Orders: $_totalCompletedOrders');
        } else {
          setState(() {
            _isLoadingDetails = false;
          });
          print('❌ API Error: ${responseData['message']}');
        }
      } else {
        setState(() {
          _isLoadingDetails = false;
        });
        print('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
      print('❌ Error fetching campaign details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final salonName = campaign['salonName'] ??
        AppTranslations.getString(context, 'saloon_name');
    final createdAt = campaign['createdAt'] ?? '';
    final message = campaign['invitationMessage'] ?? '';
    final promotion = campaign['promotion'] ?? 0;
    final promotionType = campaign['promotionType'] ?? 'percentage';
    final status = campaign['status'] ?? 'pending';
    final initiator =
        campaign['initiator'] ?? 'salon'; // 'salon' or 'influencer'

    // Format date
    final date = _formatDate(createdAt);

    // Format promotion
    final promotionText = _formatPromotion(promotion, promotionType);
    final promotionTypeText = _formatPromotionType(promotionType);

    return BlocProvider(
      create: (context) => CampaignActionsBloc(),
      child: BlocListener<CampaignActionsBloc, CampaignActionsState>(
        listener: (context, state) {
          if (state is CampaignAccepted) {
            TopNotificationService.showSuccess(
              context: context,
              message: state.message,
            );
            // Call the callback to refresh campaigns if provided
            if (widget.onCampaignDeleted != null) {
              widget.onCampaignDeleted!();
            }
            // Navigate back to campaigns screen
            Navigator.of(context).pop();
          } else if (state is CampaignRejected) {
            TopNotificationService.showSuccess(
              context: context,
              message: state.message,
            );
            // Call the callback to refresh campaigns if provided
            if (widget.onCampaignDeleted != null) {
              widget.onCampaignDeleted!();
            }
            // Navigate back to campaigns screen
            Navigator.of(context).pop();
          } else if (state is CampaignActionsError) {
            TopNotificationService.showError(
              context: context,
              message: state.message,
            );
          }
        },
        child: BlocListener<DeleteCampaignBloc, DeleteCampaignState>(
          listener: (context, state) {
            if (state is DeleteCampaignSuccess) {
              TopNotificationService.showSuccess(
                context: context,
                message: state.message,
              );
              // Call the callback to refresh campaigns if provided
              if (widget.onCampaignDeleted != null) {
                widget.onCampaignDeleted!();
              }
              // Navigate back to campaigns screen
              Navigator.of(context).pop();
            } else if (state is DeleteCampaignError) {
              TopNotificationService.showError(
                context: context,
                message: state.message,
              );
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
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
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCampaignInfo(salonName, status, initiator),
                              const SizedBox(height: 24),
                              if (status == 'in progress') ...[
                                _buildCreatedAndStartedAt(date),
                                const SizedBox(height: 24),
                              ] else ...[
                                _buildCreatedAt(date),
                                const SizedBox(height: 24),
                              ],
                              _buildPromotionDetails(
                                  promotionTypeText, promotionText),
                              const SizedBox(height: 24),
                              if (status == 'in progress') ...[
                                _buildClicks(campaign['clicks'] ?? 0),
                                const SizedBox(height: 24),
                                _buildCompletedOrders(
                                    int.tryParse(_totalCompletedOrders) ?? 0),
                                const SizedBox(height: 24),
                                _buildTotal(int.tryParse(_totalAmount) ?? 0),
                                const SizedBox(height: 24),
                              ],
                              _buildMessage(message),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      _buildActionButtons(status, initiator),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.accentColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignInfo(String salonName, String status, String initiator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.getString(context, 'campaign_with'),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 14,
              ),
            ),
            _buildStatusTag(status, initiator),
          ],
        ),
        Text(
          salonName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status, String initiator) {
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        if (initiator == 'influencer') {
          statusText = AppTranslations.getString(context, 'Waiting_for_Saloon');
          statusIcon = LucideIcons.store;
        } else {
          statusText = AppTranslations.getString(context, 'waiting_for_you');
          statusIcon = LucideIcons.userSquare;
        }
        break;
      case 'in progress':
        statusText = AppTranslations.getString(context, 'on_going');
        statusIcon = LucideIcons.circleDotDashed;
        break;
      case 'finished':
        statusText = AppTranslations.getString(context, 'finished');
        statusIcon = LucideIcons.checkCircle;
        break;
      default:
        statusText = status;
        statusIcon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            statusIcon,
            color: Colors.black,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildCreatedAt(String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'created_at'),
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatedAndStartedAt(String date) {
    return Row(
      children: [
        Expanded(
          child: _buildCreatedAt(date),
        ),
      ],
    );
  }

  Widget _buildClicks(int clicks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'clicks'),
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatNumber(clicks)} ${AppTranslations.getString(context, 'clicks')}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrders(int orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'completed_orders'),
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(orders),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotal(int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'total'),
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_formatNumber(total)} EUR',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionDetails(String promotionType, String promotionValue) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'promotion_type'),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                promotionType,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'value'),
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                promotionValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'message'),
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message.isEmpty
              ? AppTranslations.getString(context, 'no_message')
              : message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons(String status, String initiator) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: BlocBuilder<CampaignActionsBloc, CampaignActionsState>(
        builder: (context, state) {
          final isLoading = state is CampaignActionsLoading;

          return Column(
            children: [
              if (status == 'pending') ...[
                if (initiator == 'salon') ...[
                  // Salon invited influencer - show Accept/Refuse buttons
                  // Accept Campaign Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _acceptCampaign(
                              context.read<CampaignActionsBloc>()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              isLoading
                                  ? 'Accepting...'
                                  : AppTranslations.getString(
                                      context, 'accept_campaign'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isLoading) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.checkCheck,
                              color: Colors.black,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Refuse Campaign Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => _refuseCampaign(
                              context.read<CampaignActionsBloc>()),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              isLoading
                                  ? 'Rejecting...'
                                  : AppTranslations.getString(
                                      context, 'refuse_campaign'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isLoading) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ] else if (initiator == 'influencer') ...[
                  // Influencer invited salon - show Delete button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _deleteCampaignRequest,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.accentColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              AppTranslations.getString(
                                  context, 'delete_campaign_request'),
                              style: const TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.xCircle,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (status == 'in progress') ...[
                // Copy Link Button - only show if link is available
                if (_campaignLink != null && _campaignLink!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _copyLink,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              AppTranslations.getString(context, 'copy_link'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.link,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_isLoadingDetails) ...[
                  // Show loading indicator while fetching campaign details
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Show message if no link is available
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Campaign link not available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              // No buttons for 'finished' status
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  String _formatPromotion(int promotion, String promotionType) {
    if (promotionType == 'percentage') {
      return '$promotion%';
    } else {
      return 'EUR $promotion';
    }
  }

  String _formatPromotionType(String promotionType) {
    if (promotionType == 'percentage') {
      return AppTranslations.getString(context, 'percentage');
    } else {
      return AppTranslations.getString(context, 'fixed');
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _acceptCampaign(CampaignActionsBloc bloc) {
    _showAcceptCampaignDialog(bloc);
  }

  void _refuseCampaign(CampaignActionsBloc bloc) {
    _showRefuseCampaignDialog(bloc);
  }

  void _showAcceptCampaignDialog(CampaignActionsBloc bloc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'accept_campaign'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'confirm_accept_campaign'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performAcceptCampaign(bloc);
              },
              child: Text(
                AppTranslations.getString(context, 'confirm'),
                style: const TextStyle(
                  color: AppTheme.greenColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRefuseCampaignDialog(CampaignActionsBloc bloc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'refuse_campaign'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'confirm_refuse_campaign'),
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                AppTranslations.getString(context, 'cancel'),
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performRefuseCampaign(bloc);
              },
              child: Text(
                AppTranslations.getString(context, 'confirm'),
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performAcceptCampaign(CampaignActionsBloc bloc) {
    final campaignId = widget.campaign['id'] as String?;
    if (campaignId == null || campaignId.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
      return;
    }

    bloc.add(
      AcceptCampaign(campaignId: campaignId),
    );
  }

  void _performRefuseCampaign(CampaignActionsBloc bloc) {
    final campaignId = widget.campaign['id'] as String?;
    if (campaignId == null || campaignId.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
      return;
    }

    bloc.add(
      RejectCampaign(campaignId: campaignId),
    );
  }

  void _copyLink() {
    if (_campaignLink != null && _campaignLink!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _campaignLink!));
      TopNotificationService.showSuccess(
        context: context,
        message: AppTranslations.getString(context, 'campaign_link_copied'),
      );
    } else {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign link not available',
      );
    }
  }

  void _deleteCampaignRequest() {
    _showDeleteConfirmationDialog();
  }

  void _showDeleteConfirmationDialog() {
    final deleteBloc = context.read<DeleteCampaignBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: deleteBloc,
          child: BlocBuilder<DeleteCampaignBloc, DeleteCampaignState>(
            builder: (context, state) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  AppTranslations.getString(
                      context, 'delete_campaign_confirmation_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  AppTranslations.getString(
                      context, 'delete_campaign_confirmation_message'),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppTranslations.getString(
                          context, 'delete_campaign_cancel_button'),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: state is DeleteCampaignLoading
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                            _performDeleteCampaign();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state is DeleteCampaignLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            AppTranslations.getString(
                                context, 'delete_campaign_confirm_button'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _performDeleteCampaign() {
    final campaignId = widget.campaign['id'] ?? widget.campaign['campaignId'];
    if (campaignId != null) {
      context.read<DeleteCampaignBloc>().add(
            DeleteCampaignInvitation(campaignId: campaignId.toString()),
          );
    } else {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
    }
  }
}
