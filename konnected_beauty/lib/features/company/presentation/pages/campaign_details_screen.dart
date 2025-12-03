import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/campaigns/campaigns_state.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'orders_screen.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;

  const CampaignDetailsScreen({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  bool _isLoading = true;
  late ConfettiController _confettiController;
  Map<String, dynamic>? _freshCampaignData;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Fetch fresh campaign data from API
    _fetchFreshCampaignData();
  }

  Future<void> _fetchFreshCampaignData() async {
    final campaignId = widget.campaign['id'];
    if (campaignId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('🔍 === FETCHING FRESH CAMPAIGN DATA ===');
      print('🔍 Campaign ID: $campaignId');

      final result = await InfluencersService.getSalonCampaignDetails(
        campaignId: campaignId,
      );

      if (result['success'] == true) {
        setState(() {
          _freshCampaignData = result['data'];
          _isLoading = false;
        });

        // Debug: Print the fresh campaign data response in JSON format
        print('🔍 === FRESH CAMPAIGN API RESPONSE ===');
        print('🔍 JSON Response:');
        print('{');
        print('    "message": "success",');
        print('    "statusCode": 200,');
        print('    "data": {');
        print('        "id": "${_freshCampaignData?['id']}",');
        print('        "createdAt": "${_freshCampaignData?['createdAt']}",');
        print('        "updatedAt": "${_freshCampaignData?['updatedAt']}",');
        print('        "status": "${_freshCampaignData?['status']}",');
        print('        "promotion": ${_freshCampaignData?['promotion']},');
        print(
            '        "promotionType": "${_freshCampaignData?['promotionType']}",');
        print(
            '        "invitationMessage": "${_freshCampaignData?['invitationMessage'] ?? ""}",');
        print('        "initiator": "${_freshCampaignData?['initiator']}",');
        print('        "clicks": ${_freshCampaignData?['clicks']},');
        print('        "link": "${_freshCampaignData?['link']}",');
        print('        "influencer": {');
        print(
            '            "id": "${_freshCampaignData?['influencer']?['id'] ?? ""}",');
        print('            "profile": {');
        print(
            '                "pseudo": "${_freshCampaignData?['influencer']?['profile']?['pseudo'] ?? ""}",');
        print(
            '                "bio": "${_freshCampaignData?['influencer']?['profile']?['bio'] ?? ""}",');
        print(
            '                "zone": "${_freshCampaignData?['influencer']?['profile']?['zone'] ?? ""}",');
        print(
            '                "profilePicture": "${_freshCampaignData?['influencer']?['profile']?['profilePicture'] ?? null}"');
        print('            }');
        print('        },');
        print('        "totalAmount": ${_freshCampaignData?['totalAmount']},');
        print(
            '        "totalCompletedOrders": ${_freshCampaignData?['totalCompletedOrders']}');
        print('    }');
        print('}');
        print('🔍 === END FRESH CAMPAIGN API RESPONSE ===');
      } else {
        print('❌ Failed to fetch fresh campaign data: ${result['message']}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching fresh campaign data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to get campaign data (fresh from API or fallback to widget data)
  Map<String, dynamic> get campaignData {
    return _freshCampaignData ?? widget.campaign;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
            body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF1F1E1E), // Bottom color (darker)
                    Color(0xFF3B3B3B), // Top color (lighter)
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Campaign Information
                    Expanded(
                      child: _isLoading
                          ? _buildShimmerContent()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCampaignWithSection(),
                                  const SizedBox(height: 24),
                                  _buildCreatedAtSection(),
                                  const SizedBox(height: 24),
                                  _buildPromotionSection(),
                                  const SizedBox(height: 24),
                                  _buildClicksSection(),
                                  const SizedBox(height: 24),
                                  _buildCompletedOrdersSection(),
                                  const SizedBox(height: 24),
                                  _buildViewOrdersButton(),
                                  const SizedBox(height: 24),
                                  _buildTotalSection(),
                                  const SizedBox(height: 20),
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // Confetti Animation
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 1.57, // Downward direction
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.yellow,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.brown,
                  Colors.lightBlue,
                  Colors.red,
                ],
                createParticlePath: (size) {
                  // Create various shapes for confetti
                  final random = (DateTime.now().millisecondsSinceEpoch % 4);
                  switch (random) {
                    case 0:
                      return drawStar(size);
                    case 1:
                      return drawCircle(size);
                    case 2:
                      return drawSquare(size);
                    case 3:
                      return drawTriangle(size);
                    default:
                      return drawCircle(size);
                  }
                },
              ),
            ),
          ],
        ));
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              // Refresh campaigns when going back
              if (mounted) {
                context.read<CampaignsBloc>().add(RefreshCampaigns(
                      status: 'pending',
                      limit: 10,
                    ));
              }
              Navigator.of(context).pop();
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                AppTranslations.getString(context, 'campaign_with'),
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            // Status Button
            _buildStatusButton(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Profile Picture
            _buildProfilePicture(),
            const SizedBox(width: 12),
            Text(
              '@${campaignData['influencer']?['profile']?['pseudo'] ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreatedAtSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'created_at'),
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDate(campaignData['createdAt'] ?? ''),
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.getString(context, 'promotion_type'),
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                campaignData['promotionType'] ?? 'percentage',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Value',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatPromotionValue(widget.campaign['promotion'],
                    widget.campaign['promotionType']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'clicks'),
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.campaign['clicks']} Clicks',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed orders',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final completedOrders = campaignData['totalCompletedOrders'] ?? 0;
            print('🔍 === COMPLETED ORDERS ===');
            print(
                '🔍 Raw: ${campaignData['totalCompletedOrders']} | Processed: $completedOrders');
            print('🔍 === END COMPLETED ORDERS ===');
            return Text(
              '$completedOrders',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewOrdersButton() {
    final status = campaignData['status']?.toString().toLowerCase() ?? '';

    // Only show button for finished or ongoing campaigns
    if (status != 'finished' && status != 'in progress') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrdersScreen(campaign: widget.campaign),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppTheme.transparentBackground,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppTranslations.getString(context, 'view_orders'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final totalAmount = campaignData['totalAmount'] ?? 0;
            print('🔍 === TOTAL AMOUNT ===');
            print(
                '🔍 Raw: ${campaignData['totalAmount']} | Processed: $totalAmount');
            print('🔍 === END TOTAL AMOUNT ===');
            return Text(
              '$totalAmount EUR',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusButton() {
    final status = campaignData['status']?.toString().toLowerCase() ?? '';

    if (status == 'finished') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              AppTranslations.getString(context, 'finished'),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Icon(
              Icons.done_all_outlined, // 👤 profile icon
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ],
        ),
      );
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              AppTranslations.getString(context, 'rejected'),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Icon(
              Icons.cancel_outlined,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ],
        ),
      );
    } else if (status == 'pending') {
      final initiator = campaignData['initiator'] ?? 'salon';
      final statusText = initiator == 'influencer'
          ? AppTranslations.getString(context, 'waiting_for_salon')
          : AppTranslations.getString(context, 'waiting_for_influencer');
      final statusIcon = initiator == 'influencer'
          ? LucideIcons.store
          : Icons.person_2_outlined;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              width: 5,
            ),
            Icon(
              statusIcon,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ],
        ),
      );
    } else {
      // On going or other statuses
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppTranslations.getString(context, 'on_going_status'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.black, width: 1, style: BorderStyle.solid),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    final status = campaignData['status']?.toString().toLowerCase() ?? '';
    final initiator = campaignData['initiator'] ?? 'salon';

    if (status == 'finished') {
      // No buttons for finished campaigns
      return const SizedBox.shrink();
    } else if (status == 'rejected') {
      // No buttons for rejected campaigns
      return const SizedBox.shrink();
    } else if (status == 'pending') {
      // Check if influencer initiated the campaign
      if (initiator == 'influencer') {
        // Show accept/refuse buttons when influencer invited salon
        return Column(
          children: [
            // Accept Campaign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptCampaign(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenColor,
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
                        AppTranslations.getString(context, 'accept_campaign'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.checkCheck,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Refuse Campaign Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _refuseCampaign(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
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
                        AppTranslations.getString(context, 'refuse_campaign'),
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
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      } else {
        // Only delete button for pending campaigns when salon initiated
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showDeleteCampaignDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.transparentBackground,
              foregroundColor: AppTheme.borderColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                    color: Colors.white, width: 1), // ✅ White border
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppTranslations.getString(context, 'delete_campaign'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.xCircle, size: 24),
              ],
            ),
          ),
        );
      }
    } else {
      // Both buttons for ongoing campaigns
      return Column(
        children: [
          // Finish Campaign Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showFinishCampaignDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppTranslations.getString(context, 'finish_campaign'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 24),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteCampaignDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'delete_campaign'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'delete_campaign_confirm'),
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
            BlocListener<CampaignsBloc, CampaignsState>(
              listener: (context, state) {
                if (state is CampaignDeleted) {
                  Navigator.of(context).pop(); // Close dialog
                  TopNotificationService.showSuccess(
                    context: context,
                    message: state.message,
                  );
                  Navigator.of(context).pop(); // Go back to campaigns screen
                } else if (state is CampaignsError) {
                  Navigator.of(context).pop(); // Close dialog
                  TopNotificationService.showError(
                    context: context,
                    message: state.message,
                  );
                }
              },
              child: TextButton(
                onPressed: () {
                  context.read<CampaignsBloc>().add(
                        DeleteCampaign(campaignId: widget.campaign['id']),
                      );
                },
                child: Text(
                  AppTranslations.getString(
                      context, 'delete_campaign_confirm_button'),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatPromotionValue(dynamic promotion, String? promotionType) {
    if (promotion == null) return '0';

    final promotionValue = promotion.toString();
    if (promotionType == 'percentage') {
      return '$promotionValue%';
    } else {
      return '$promotionValue EUR';
    }
  }

  void _acceptCampaign() {
    _showAcceptCampaignDialog();
  }

  void _showAcceptCampaignDialog() {
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
                _performAcceptCampaign();
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

  void _performAcceptCampaign() async {
    try {
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

      final result = await InfluencersService.acceptInfluencerInvite(
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
              AppTranslations.getString(context, 'campaign_accepted_success'),
        );

        // Update the campaign status to 'in progress' locally
        widget.campaign['status'] = 'in progress';

        // Also update _freshCampaignData if it exists
        if (_freshCampaignData != null) {
          _freshCampaignData!['status'] = 'in progress';
        }

        // Reload fresh campaign data from API to ensure everything is up to date
        await _fetchFreshCampaignData();

        // Trigger a rebuild to show the new buttons
        if (mounted) {
          setState(() {});
        }
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to accept campaign',
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      TopNotificationService.showError(
        context: context,
        message: 'Error accepting campaign: $e',
      );
    }
  }

  void _refuseCampaign() {
    _showRefuseCampaignDialog();
  }

  void _showRefuseCampaignDialog() {
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
            AppTranslations.getString(context, 'refuse_campaign_confirmation'),
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
                _performRefuseCampaign();
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

  void _performRefuseCampaign() async {
    try {
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

      final result = await InfluencersService.refuseCampaign(
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

        // Navigate back to campaigns screen
        if (mounted) {
          Navigator.of(context).pop();
        }
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

  Widget _buildProfilePicture() {
    final profilePicture =
        widget.campaign['influencer']?['profile']?['profilePicture'];

    if (profilePicture != null && profilePicture.toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profilePicture.toString(),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[600],
              child: Icon(
                Icons.person,
                color: AppTheme.textPrimaryColor,
                size: 30,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[600],
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AppTheme.textPrimaryColor,
              ),
            );
          },
        ),
      );
    } else {
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[600],
        child: Icon(
          Icons.person,
          color: AppTheme.textPrimaryColor,
          size: 30,
        ),
      );
    }
  }

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign with section shimmer
            _buildShimmerCampaignWithSection(),
            const SizedBox(height: 24),

            // Created at section shimmer
            _buildShimmerCreatedAtSection(),
            const SizedBox(height: 24),

            // Promotion section shimmer
            _buildShimmerPromotionSection(),
            const SizedBox(height: 24),

            // Clicks section shimmer
            _buildShimmerClicksSection(),
            const SizedBox(height: 24),

            // Completed orders section shimmer
            _buildShimmerCompletedOrdersSection(),
            const SizedBox(height: 24),

            // View orders button shimmer (only for finished/ongoing campaigns)
            _buildShimmerViewOrdersButton(),
            const SizedBox(height: 24),

            // Total section shimmer
            _buildShimmerTotalSection(),
            const SizedBox(height: 20),

            // Action buttons shimmer
            _buildShimmerActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCampaignWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              height: 24,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCreatedAtSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerPromotionSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerClicksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCompletedOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerViewOrdersButton() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildShimmerTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerActionButtons() {
    return Column(
      children: [
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  // Confetti shape drawing methods
  Path drawStar(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 144.0) * (3.14159 / 180.0);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  Path drawCircle(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  Path drawSquare(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  Path drawTriangle(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  void _showFinishCampaignDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppTranslations.getString(context, 'finish_campaign'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppTranslations.getString(context, 'confirm_finish_campaign'),
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
                _finishCampaign();
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

  void _finishCampaign() async {
    try {
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

      final result = await InfluencersService.finishCampaign(
        campaignId: campaignId,
      );

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        // Start confetti animation
        _confettiController.play();

        // Update the campaign status to 'finished' locally
        widget.campaign['status'] = 'finished';

        // Show success message
        TopNotificationService.showSuccess(
          context: context,
          message: AppTranslations.getString(
              context, 'congratulations_campaign_finished'),
        );

        // Trigger a rebuild to hide buttons and show finished status
        if (mounted) {
          setState(() {});
        }

        // Show rating modal after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showRatingModal();
          }
        });

        // Stop confetti after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _confettiController.stop();
          }
        });
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to finish campaign',
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      TopNotificationService.showError(
        context: context,
        message: 'Error finishing campaign: $e',
      );
    }
  }

  void _showRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => RatingModal(
        campaignId: widget.campaign['id'] as String? ?? '',
        onSubmitRating: _submitRating,
      ),
    );
  }

  void _submitRating(int stars, String comment) async {
    try {
      final campaignId = widget.campaign['id'] as String?;
      if (campaignId == null || campaignId.isEmpty) {
        TopNotificationService.showError(
          context: context,
          message: 'Campaign ID not found',
        );
        return;
      }

      // Close the modal first
      Navigator.of(context).pop();

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

      final result = await InfluencersService.rateInfluencer(
        campaignId: campaignId,
        stars: stars,
        comment: comment,
      );

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        TopNotificationService.showSuccess(
          context: context,
          message: AppTranslations.getString(
              context, 'rating_submitted_successfully'),
        );

        // Show thank you modal after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showThankYouModal();
          }
        });
      } else {
        TopNotificationService.showError(
          context: context,
          message: result['message'] ?? 'Failed to submit rating',
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      TopNotificationService.showError(
        context: context,
        message: 'Error submitting rating: $e',
      );
    }
  }

  void _showThankYouModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => _buildThankYouModal(),
    );
  }

  Widget _buildThankYouModal() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'thank_you_for_reviewing'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            AppTranslations.getString(context, 'thank_you_helping_message'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1),
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

class RatingModal extends StatefulWidget {
  final String campaignId;
  final Function(int stars, String comment) onSubmitRating;

  const RatingModal({
    super.key,
    required this.campaignId,
    required this.onSubmitRating,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  int selectedStars = 0;
  final TextEditingController reviewController = TextEditingController();

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'how_was_it'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            AppTranslations.getString(context, 'rate_review'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Rate Section
          Text(
            AppTranslations.getString(context, 'rate'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedStars = index + 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(
                    index < selectedStars ? Icons.star : Icons.star_border,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Review Section
          Text(
            AppTranslations.getString(context, 'review'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Review Text Field
          Container(
            decoration: BoxDecoration(
              color: AppTheme.transparentBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: TextField(
              controller: reviewController,
              maxLines: 4,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText:
                    AppTranslations.getString(context, 'describe_your_review'),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1),
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

              // Submit Button
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedStars > 0
                      ? () {
                          widget.onSubmitRating(
                              selectedStars, reviewController.text);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    AppTranslations.getString(context, 'submit'),
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
    );
  }
}
