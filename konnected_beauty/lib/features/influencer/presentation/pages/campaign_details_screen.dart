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
import '../../../../core/services/api/influencers_service.dart';

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
  Map<String, dynamic>? _updatedCampaignData;
  final TextEditingController _refuseMessageController =
      TextEditingController();
  final TextEditingController _replyMessageController =
      TextEditingController();

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

          // Extract salon name from API response structure
          final salon = campaignData['salon'] as Map<String, dynamic>? ?? {};
          final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};
          final salonName =
              salonInfo['name'] ?? campaignData['salonName'] ?? '';

          // Update campaign data with salon name if not present
          if (salonName.isNotEmpty && campaignData['salonName'] == null) {
            campaignData['salonName'] = salonName;
          }

          setState(() {
            _updatedCampaignData = campaignData;
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
          print('📋 Salon Name: $salonName');
          print('📋 Reply Message: ${campaignData['replyMessage']}');
          print('📋 Influencer Reply Message: ${campaignData['influencerReplyMessage']}');
          print('📋 Campaign Data Keys: ${campaignData.keys.toList()}');
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

  Future<void> _refreshCampaignData() async {
    await _fetchCampaignDetails();
    // Trigger a rebuild to show the updated data
    if (mounted) {
      setState(() {});
    }
  }

  // Helper method to get campaign data (updated from API or fallback to widget data)
  Map<String, dynamic> get campaignData {
    return _updatedCampaignData ?? widget.campaign;
  }

  @override
  Widget build(BuildContext context) {
    final campaign = campaignData;

    // Extract salon name from various possible locations in the data structure
    String salonName = campaign['salonName'] ?? '';
    if (salonName.isEmpty) {
      final salon = campaign['salon'] as Map<String, dynamic>? ?? {};
      final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};
      salonName = salonInfo['name'] ?? '';
    }
    if (salonName.isEmpty) {
      salonName = AppTranslations.getString(context, 'saloon_name');
    }
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
            // Refresh campaign data to show the reply message
            _refreshCampaignData();
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
            backgroundColor:
                AppTheme.getScaffoldBackground(Theme.of(context).brightness),
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
                            Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.transparentBackground
                                : AppTheme.textWhite54,
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
                      // Header
                      _buildHeader(),
                      // Campaign Information (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCampaignInfo(salonName, status, initiator),
                                SizedBox(height: 24),
                                // Show reply message if it exists (when influencer replied)
                                if (_shouldShowInfluencerReplyMessage())
                                  _buildInfluencerReplyMessageCard(),
                                if (_shouldShowInfluencerReplyMessage())
                              SizedBox(height: 24),
                              // Show salon message card if campaign is rejected
                              if (status == 'rejected' &&
                                  _shouldShowSalonMessage())
                                _buildSalonMessageCard(),
                              if (status == 'rejected' &&
                                  _shouldShowSalonMessage())
                                SizedBox(height: 24),
                              if (status == 'in progress') ...[
                                _buildCreatedAndStartedAt(date),
                                SizedBox(height: 24),
                              ] else ...[
                                _buildCreatedAt(date),
                                SizedBox(height: 24),
                              ],
                              _buildPromotionDetails(
                                  promotionTypeText, promotionText),
                              SizedBox(height: 24),
                              if (status == 'in progress') ...[
                                _buildClicks(campaign['clicks'] ?? 0),
                                SizedBox(height: 24),
                                _buildCompletedOrders(
                                    int.tryParse(_totalCompletedOrders) ?? 0),
                                SizedBox(height: 24),
                                _buildTotal(int.tryParse(_totalAmount) ?? 0),
                                SizedBox(height: 24),
                              ],
                              _buildMessage(message),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      ),
                      // Action Buttons (Fixed at bottom)
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
            child: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.lightTextPrimaryColor
                  : AppTheme.accentColor,
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
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.getString(context, 'campaign_with'),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.light
                    ? AppTheme.lightTextPrimaryColor
                    : AppTheme.accentColor,
                fontSize: 14,
              ),
            ),
            _buildStatusTag(status, initiator),
          ],
        ),
        Text(
          salonName,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusTag(String status, String initiator) {
    final brightness = Theme.of(context).brightness;
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
        color: brightness == Brightness.light
            ? AppTheme.lightCardBackground
            : AppTheme.getTextPrimaryColor(brightness),
        borderRadius: BorderRadius.circular(8),
        border: brightness == Brightness.light
            ? Border.all(color: AppTheme.lightCardBorderColor, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                color: brightness == Brightness.light
                    ? AppTheme.lightTextPrimaryColor
                    : AppTheme.lightTextPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            statusIcon,
            color: brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.lightTextPrimaryColor,
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.accentColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.accentColor,
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextSecondaryColor
                : AppTheme.getTextTertiaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${_formatNumber(clicks)} ${AppTranslations.getString(context, 'clicks')}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextSecondaryColor
                : AppTheme.getTextTertiaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _formatNumber(orders),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextSecondaryColor
                : AppTheme.getTextTertiaryColor(Theme.of(context).brightness),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${_formatNumber(total)} EUR',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextTertiaryColor(
                          Theme.of(context).brightness),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                promotionType,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'value'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextTertiaryColor(
                          Theme.of(context).brightness),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                promotionValue,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppTheme.lightTextPrimaryColor
                      : AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.accentColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          message.isEmpty
              ? AppTranslations.getString(context, 'no_message')
              : message,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? AppTheme.lightTextPrimaryColor
                : AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
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
                  // Salon invited influencer - show Reply/Accept/Refuse buttons
                  // Reply Button (FIRST)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => _showReplyDialog(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              AppTranslations.getString(context, 'reply'),
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.reply,
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Brightness.light
                                        : Brightness.dark),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              isLoading
                                  ? 'Accepting...'
                                  : AppTranslations.getString(
                                      context, 'accept_campaign'),
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Brightness.light
                                        : Brightness.dark),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isLoading) ...[
                            SizedBox(width: 8),
                            Icon(
                              LucideIcons.checkCheck,
                              color: AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Brightness.light
                                      : Brightness.dark),
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                        side: BorderSide(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              isLoading
                                  ? 'Rejecting...'
                                  : AppTranslations.getString(
                                      context, 'refuse_campaign'),
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!isLoading) ...[
                            SizedBox(width: 8),
                            Icon(
                              Icons.close,
                              color: AppTheme.getTextPrimaryColor(
                                  Theme.of(context).brightness),
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
                        side: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.accentColor,
                            width: 1),
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
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            LucideIcons.xCircle,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? AppTheme.lightTextPrimaryColor
                                    : AppTheme.accentColor,
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
                        side: BorderSide(
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                            width: 1),
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
                              style: TextStyle(
                                color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.link,
                            color: AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
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
                            color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness)
                                .withOpacity(0.3),
                            width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
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
                            color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness)
                                .withOpacity(0.3),
                            width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Campaign link not available',
                          style: TextStyle(
                            color: AppTheme.getTextPrimaryColor(
                                    Theme.of(context).brightness)
                                .withOpacity(0.7),
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
          backgroundColor:
              AppTheme.getSecondaryColor(Theme.of(context).brightness),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'accept_campaign'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'confirm_accept_campaign'),
            style: TextStyle(
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
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
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(
                      Theme.of(context).brightness),
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
                style: TextStyle(
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
      builder: (BuildContext dialogContext) {
        final brightness = Theme.of(context).brightness;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getSecondaryColor(brightness),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main question
                Text(
                  AppTranslations.getString(
                      context, 'are_you_sure_refuse_campaign'),
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(brightness),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Warning message
                Text(
                  AppTranslations.getString(context, 'no_going_back_warning'),
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(brightness),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Cancel button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.getTextPrimaryColor(brightness),
                          width: 1,
                        ),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        AppTranslations.getString(context, 'cancel'),
                        style: TextStyle(
                          color: AppTheme.getTextPrimaryColor(brightness),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes, Refuse button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _performRefuseCampaign(bloc);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        AppTranslations.getString(context, 'yes_refuse'),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
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

  void _performRefuseCampaign(CampaignActionsBloc bloc) async {
    final campaignId = widget.campaign['id'] as String?;
    if (campaignId == null || campaignId.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.greenColor,
        ),
      ),
    );

    try {
      final result = await InfluencersService.rejectSalonInvite(
        campaignId: campaignId,
      );

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        TopNotificationService.showSuccess(
          context: context,
          message: result['message'] ??
              AppTranslations.getString(context, 'campaign_refused_success'),
        );

        // Refresh campaign data
        await _fetchCampaignDetails();
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to refuse campaign',
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      TopNotificationService.showError(
        context: context,
        message: 'Error refusing campaign: $e',
      );
    }
  }

  void _showReplyDialog() {
    _replyMessageController.clear(); // Clear previous message
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppTheme.secondaryColor,
          insetPadding: EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    AppTranslations.getString(context, 'reply'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : AppTheme.textPrimaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Message to salon section
                  Text(
                    AppTranslations.getString(context, 'message_to_salon'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Text input field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[100]
                          : AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[300]!
                            : AppTheme.border2,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _replyMessageController,
                      maxLines: 5,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : AppTheme.textPrimaryColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: AppTranslations.getString(
                            context, 'write_message'),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[600]
                              : AppTheme.textSecondaryColor.withOpacity(0.6),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info text
                  Text(
                    AppTranslations.getString(
                        context, 'single_message_allowed'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[600]
                          : AppTheme.textSecondaryColor.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Column(
                    children: [
                      // Send Reply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _performReply();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.greenColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  AppTranslations.getString(
                                      context, 'send_reply'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.send,
                                size: 20,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey[300]!
                                  : AppTheme.textSecondaryColor,
                              width: 1,
                            ),
                            foregroundColor:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : AppTheme.textPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'cancel'),
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
          ),
        );
      },
    );
  }

  void _performReply() async {
    try {
    final campaignId = widget.campaign['id'] as String?;
    if (campaignId == null || campaignId.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
      return;
    }

      final replyMessage = _replyMessageController.text.trim();
      if (replyMessage.isEmpty) {
      TopNotificationService.showError(
        context: context,
          message: 'Please enter a message',
      );
      return;
    }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.greenColor,
          ),
        ),
      );

      final result = await InfluencersService.sendReplyToSalonInvite(
        campaignId: campaignId,
        replyMessage: replyMessage,
      );

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        TopNotificationService.showSuccess(
          context: context,
          message: result['message'] ??
              AppTranslations.getString(context, 'reply_sent_successfully'),
        );

        // Refresh campaign data to show the message
        await _fetchCampaignDetails();
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to send reply',
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      TopNotificationService.showError(
        context: context,
        message: 'Error sending reply: $e',
    );
    }
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
                backgroundColor:
                    AppTheme.getCardBackground(Theme.of(context).brightness),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  AppTranslations.getString(
                      context, 'delete_campaign_confirmation_title'),
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  AppTranslations.getString(
                      context, 'delete_campaign_confirmation_message'),
                  style: TextStyle(
                    color: AppTheme.getTextTertiaryColor(
                        Theme.of(context).brightness),
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      AppTranslations.getString(
                          context, 'delete_campaign_cancel_button'),
                      style: TextStyle(
                        color: AppTheme.getTextTertiaryColor(
                            Theme.of(context).brightness),
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
                      foregroundColor: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state is DeleteCampaignLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.getTextPrimaryColor(
                                      Theme.of(context).brightness)),
                            ),
                          )
                        : Text(
                            AppTranslations.getString(
                                context, 'delete_campaign_confirm_button'),
                            style: TextStyle(
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

  bool _shouldShowInfluencerReplyMessage() {
    // Show reply message if it exists (when influencer replied to salon invite)
    final campaign = campaignData;
    final status = campaign['status']?.toString().toLowerCase() ?? '';
    final initiator = campaign['initiator']?.toString().toLowerCase() ?? '';
    
    // Show if status is pending and salon initiated (influencer can reply)
    if (status == 'pending' && initiator == 'salon') {
      // Check for influencer reply message in various possible fields
      final influencerReplyMessage = campaign['influencerReplyMessage'] ??
          campaign['replyMessage'] ??
          campaign['influencerMessage'] ??
          '';
      
      print('🔍 === CHECKING INFLUENCER REPLY MESSAGE ===');
      print('🔍 Status: $status');
      print('🔍 Initiator: $initiator');
      print('🔍 influencerReplyMessage: ${campaign['influencerReplyMessage']}');
      print('🔍 replyMessage: ${campaign['replyMessage']}');
      print('🔍 influencerMessage: ${campaign['influencerMessage']}');
      print('🔍 Final message: $influencerReplyMessage');
      print('🔍 Should show: ${influencerReplyMessage.toString().isNotEmpty}');
      print('🔍 === END CHECKING INFLUENCER REPLY MESSAGE ===');
      
      return influencerReplyMessage.toString().isNotEmpty;
    }
    
    return false;
  }

  bool _shouldShowSalonMessage() {
    final campaign = campaignData;
    final status = campaign['status']?.toString().toLowerCase() ?? '';

    // Show message card if campaign is rejected
    if (status == 'rejected') {
      final salonMessage = campaign['replyMessage'] ?? '';
      return salonMessage.toString().isNotEmpty;
    }
    return false;
  }

  Widget _buildInfluencerReplyMessageCard() {
    final campaign = campaignData;
    
    // Get influencer reply message from various possible fields
    final replyMessage = campaign['influencerReplyMessage'] ??
        campaign['replyMessage'] ??
        campaign['influencerMessage'] ??
        '';

    if (replyMessage.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isLightMode
            ? AppTheme.lightCardBackground
            : AppTheme.border2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon for influencer message
                  Icon(
                    Icons.person_outline,
                    color: isLightMode
                        ? AppTheme.lightTextPrimaryColor
                        : Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    AppTranslations.getString(context, 'reply_message'),
                    style: TextStyle(
                      color: isLightMode
                          ? AppTheme.lightTextPrimaryColor
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message content
          Text(
            replyMessage.toString(),
            style: TextStyle(
              color: isLightMode
                  ? AppTheme.lightTextPrimaryColor
                  : Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalonMessageCard() {
    final campaign = campaignData;
    final status = campaign['status']?.toString().toLowerCase() ?? '';

    String message = '';
    String titleKey = 'salon_message';

    // Get the reply message
    if (status == 'rejected') {
      message = campaign['replyMessage'] ?? '';
      print('📋 === SALON MESSAGE CARD ===');
      print('📋 Status: $status');
      print('📋 Reply Message: $message');
      print('📋 === END SALON MESSAGE CARD ===');
    }

    if (message.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isLightMode
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.lightCardBackground,
                  AppTheme.lightCardBackground,
                ],
                stops: const [0.0, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1F1E1E), // Dark gray at top
                  const Color(0xFF1F1E1E), // Dark gray continues
                ],
                stops: const [0.0, 1.0],
              ),
        border: Border.all(
          color: isLightMode ? Colors.grey[300]! : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.getString(context, titleKey),
                style: TextStyle(
                  color: isLightMode ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                LucideIcons.badgeX,
                size: 16,
                color: isLightMode ? Colors.black : Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message content
          Text(
            message.toString(),
            style: TextStyle(
              color: isLightMode ? Colors.black : Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refuseMessageController.dispose();
    _replyMessageController.dispose();
    super.dispose();
  }
}
