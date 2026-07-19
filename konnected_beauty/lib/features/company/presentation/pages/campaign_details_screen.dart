import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/campaigns/campaigns_state.dart';
import '../../../../core/models/campaign_chat_message.dart';
import '../../../../core/services/api/campaign_messages_service.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../core/services/campaign_chat_socket_service.dart';
import '../../../../widgets/common/campaign_conversation_tab.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import '../../../../widgets/common/stripe_link_required_dialog.dart';
import '../../../../core/services/api/stripe_service.dart';
import '../../../../core/bloc/influencer_details/influencer_details_bloc.dart';
import 'influencer_details_screen.dart';
import 'orders_screen.dart';

abstract final class _CampaignDetailsUi {
  static const double radius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
  static const double horizontalPadding = 16;
}

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
  int _selectedTabIndex = 0;
  late ConfettiController _confettiController;
  Map<String, dynamic>? _freshCampaignData;
  final TextEditingController _refuseMessageController =
      TextEditingController();
  final TextEditingController _replyMessageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _conversationScrollController = ScrollController();
  final FocusNode _replyFocusNode = FocusNode();
  final CampaignChatSocketService _chatSocket = CampaignChatSocketService();
  final Map<String, CampaignChatMessageItem> _liveMessagesById = {};
  bool _campaignMessagesLoading = false;
  /// When the messages API returns history, skip legacy invitation/reply lines to avoid duplicates.
  bool _useApiMessagesOnly = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _replyFocusNode.addListener(_onReplyFocusChange);
    _chatSocket.onMessage = _onSocketChatMessage;
    _chatSocket.onError = _onSocketChatError;

    // Fetch fresh campaign data from API
    _fetchFreshCampaignData();
  }

  void _onSocketChatMessage(CampaignChatMessageItem m) {
    if (!mounted) return;
    setState(() {
      _liveMessagesById[m.id] = m;
    });
    if (_selectedTabIndex == 1) {
      _scrollContentToBottom();
    }
  }

  void _onSocketChatError(String message) {
    if (!mounted) return;
    TopNotificationService.showError(
      context: context,
      message: message,
    );
  }

  Future<void> _fetchCampaignChatMessages(String campaignId) async {
    if (!mounted) return;
    setState(() => _campaignMessagesLoading = true);

    final result =
        await CampaignMessagesService.getCampaignMessages(campaignId: campaignId);

    if (!mounted) return;

    if (result['success'] == true) {
      final raw = result['data'];
      final list = raw is List<CampaignChatMessageItem>
          ? List<CampaignChatMessageItem>.from(raw)
          : <CampaignChatMessageItem>[];

      setState(() {
        _campaignMessagesLoading = false;
        _liveMessagesById
          ..clear()
          ..addEntries(list.map((m) => MapEntry(m.id, m)));
        _useApiMessagesOnly = list.isNotEmpty;
      });
    } else {
      setState(() {
        _campaignMessagesLoading = false;
        _useApiMessagesOnly = false;
        _liveMessagesById.clear();
      });
      if (mounted) {
        TopNotificationService.showError(
          context: context,
          message: result['message']?.toString() ?? 'Failed to load messages',
        );
      }
    }
  }

  Future<void> _attachChatSocket() async {
    final id = widget.campaign['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _fetchCampaignChatMessages(id);
    if (!mounted) return;
    await _chatSocket.connectJoin(
      id,
      forceRefresh: true,
    );
  }

  /// First message from whoever sent the invitation ([invitationMessage]), for merging with API chat history.
  List<_ConversationLine> _legacyInvitationLinesOnly() {
    final data = campaignData;
    final initiator =
        (data['initiator'] ?? 'salon').toString().toLowerCase().trim();
    final invitation = data['invitationMessage']?.toString().trim() ?? '';
    if (invitation.isEmpty) return [];

    DateTime? dt;
    final dateRaw = data['createdAt'];
    if (dateRaw != null && dateRaw.toString().isNotEmpty) {
      try {
        dt = DateTime.parse(dateRaw.toString());
      } catch (_) {}
    }
    final salonSentInvitation = initiator == 'salon';
    return [
      _ConversationLine(
        text: invitation,
        isSalon: salonSentInvitation,
        at: dt,
      ),
    ];
  }

  List<_ConversationLine> _mergedConversationLines() {
    final data = campaignData;
    final initiator =
        (data['initiator'] ?? 'salon').toString().toLowerCase().trim();
    final invitation = data['invitationMessage']?.toString().trim() ?? '';
    final inviterIsSalon = initiator == 'salon';

    final List<_ConversationLine> legacy;
    if (_useApiMessagesOnly) {
      final inviteAlreadyInApi = invitation.isNotEmpty &&
          _liveMessagesById.values.any(
            (m) =>
                m.content.trim() == invitation &&
                (m.senderType.toLowerCase().trim() ==
                        CampaignMessageSenderType.salon.name) ==
                    inviterIsSalon,
          );
      legacy =
          inviteAlreadyInApi ? <_ConversationLine>[] : _legacyInvitationLinesOnly();
    } else {
      legacy = _conversationLines();
    }

    final live = _liveMessagesById.values
        .map(
          (m) => _ConversationLine(
            text: m.content,
            isSalon: m.senderType.toLowerCase().trim() ==
                CampaignMessageSenderType.salon.name,
            at: m.createdAt,
          ),
        )
        .toList();

    final merged = [...legacy, ...live];
    merged.sort((a, b) {
      final ta = a.at;
      final tb = b.at;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });
    return merged;
  }

  void _onReplyFocusChange() {
    if (!_replyFocusNode.hasFocus) return;
    if (_selectedTabIndex != 1) return;
    void scrollAfterKeyboard() {
      _scrollContentToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollContentToBottom();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollAfterKeyboard();
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) scrollAfterKeyboard();
    });
  }

  Future<void> _fetchFreshCampaignData() async {
    final campaignId = widget.campaign['id']?.toString();
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
        // Keep Details tab scrolled to top so header + action buttons stay visible.
        if (_selectedTabIndex == 1) {
          _scrollContentToBottom();
        }

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
    _chatSocket.disconnect();
    _confettiController.dispose();
    _refuseMessageController.dispose();
    _replyMessageController.dispose();
    _replyFocusNode.removeListener(_onReplyFocusChange);
    _replyFocusNode.dispose();
    _scrollController.dispose();
    _conversationScrollController.dispose();
    super.dispose();
  }

  void _scrollContentToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void scroll(ScrollController c) {
        if (!c.hasClients) return;
        c.animateTo(
          c.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }

      if (_selectedTabIndex == 1) {
        scroll(_conversationScrollController);
      } else {
        scroll(_scrollController);
      }
    });
  }

  bool get _canSendCampaignChat {
    final status =
        campaignData['status']?.toString().toLowerCase().trim() ?? '';
    if (status.isEmpty) return false;

    const closedStatuses = {
      'finished',
      'canceled',
      'cancelled',
    };

    return !closedStatuses.contains(status);
  }

  int _currentPromotionValue() {
    final value = campaignData['promotion'];
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _currentPromotionType() {
    final type = campaignData['promotionType']?.toString().trim();
    return (type == null || type.isEmpty) ? 'percentage' : type;
  }

  bool get _canEditCampaignValue {
    final status =
        campaignData['status']?.toString().toLowerCase().trim() ?? '';
    final initiator =
        campaignData['initiator']?.toString().toLowerCase().trim() ?? 'salon';
    return status == 'pending' && initiator == 'salon';
  }

  SalonUiTheme _salonUi(BuildContext context) =>
      SalonUiTheme.from(context.read<ThemeBloc>().state.brightness);

  Future<void> _showEditPromotionDialog() async {
    final ui = _salonUi(context);
    final promotionType = _currentPromotionType();
    final isPercentage = promotionType == 'percentage';
    final controller =
        TextEditingController(text: _currentPromotionValue().toString());
    var isSaving = false;

    final influencer = campaignData['influencer']?['profile'] ?? {};
    final pseudo = influencer['pseudo']?.toString() ?? 'Unknown';
    final zone = influencer['zone']?.toString() ?? '';
    final pictureUrl = influencer['profilePicture']?.toString();

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetBuilderContext, setSheetState) {
            Future<void> save() async {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) {
                TopNotificationService.showError(
                  context: sheetBuilderContext,
                  message: AppTranslations.getString(
                    sheetBuilderContext,
                    'please_enter_valid_campaign_value',
                  ),
                );
                return;
              }
              if (isPercentage && value > 100) {
                TopNotificationService.showError(
                  context: sheetBuilderContext,
                  message: AppTranslations.getString(
                    sheetBuilderContext,
                    'percentage_value_must_be_between',
                  ),
                );
                return;
              }

              setSheetState(() => isSaving = true);
              final result = await InfluencersService.updateCampaignPromotion(
                campaignId: campaignData['id']?.toString() ??
                    widget.campaign['id']?.toString() ??
                    '',
                promotion: value,
                promotionType: promotionType,
              );
              if (!mounted || !sheetContext.mounted) return;

              if (result['success'] == true) {
                setState(() {
                  widget.campaign['promotion'] = value;
                  widget.campaign['promotionType'] = promotionType;
                  _freshCampaignData ??=
                      Map<String, dynamic>.from(widget.campaign);
                  _freshCampaignData!['promotion'] = value;
                  _freshCampaignData!['promotionType'] = promotionType;
                });
                Navigator.of(sheetContext).pop(true);
              } else {
                setSheetState(() => isSaving = false);
                TopNotificationService.showError(
                  context: sheetBuilderContext,
                  message: result['message']?.toString() ??
                      AppTranslations.getString(
                        sheetBuilderContext,
                        'failed_to_update_value',
                      ),
                );
              }
            }

            final bottomInset =
                MediaQuery.viewInsetsOf(sheetBuilderContext).bottom;
            final bottomSafe =
                MediaQuery.paddingOf(sheetBuilderContext).bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.sizeOf(sheetBuilderContext).height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: ui.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 180,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: ui.sheetHeaderGradient,
                            stops: const [0.0, 0.35, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        28,
                        20,
                        18 + bottomSafe,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTranslations.getString(
                              sheetBuilderContext,
                              'edit_campaign_value_confirm_title',
                            ),
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildEditPromotionProfileCard(
                                    ui: ui,
                                    pseudo: pseudo,
                                    zone: zone,
                                    pictureUrl: pictureUrl,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildEditPromotionCommissionCard(ui),
                                  const SizedBox(height: 20),
                                  Text(
                                    AppTranslations.getString(
                                      sheetBuilderContext,
                                      isPercentage
                                          ? 'followers_promotion_value'
                                          : 'promotion_value',
                                    ),
                                    style: TextStyle(
                                      color: ui.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: TextStyle(
                                      color: ui.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '00',
                                      hintStyle: TextStyle(
                                        color: ui.textMuted,
                                      ),
                                      suffixText: isPercentage ? '%' : 'EUR',
                                      suffixStyle: TextStyle(
                                        color: ui.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          _CampaignDetailsUi.radius,
                                        ),
                                        borderSide: BorderSide(
                                          color: ui.outlinedButtonBorder,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          _CampaignDetailsUi.radius,
                                        ),
                                        borderSide: BorderSide(
                                          color: ui.textPrimary,
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ui.primaryButtonBg,
                                disabledBackgroundColor:
                                    ui.primaryButtonBg.withValues(alpha: 0.7),
                                foregroundColor: ui.primaryButtonFg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _CampaignDetailsUi.radius,
                                  ),
                                ),
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ui.primaryButtonFg,
                                      ),
                                    )
                                  : Text(
                                      AppTranslations.getString(
                                        sheetBuilderContext,
                                        'save_changes',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ui.textPrimary,
                                side: BorderSide(
                                  color: ui.outlinedButtonBorder,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    _CampaignDetailsUi.radius,
                                  ),
                                ),
                              ),
                              child: Text(
                                AppTranslations.getString(
                                  sheetBuilderContext,
                                  'cancel',
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);

    if (!mounted || updated != true) return;
    TopNotificationService.showSuccess(
      context: context,
      message: AppTranslations.getString(context, 'campaign_value_updated'),
    );
  }

  Widget _buildEditPromotionProfileCard({
    required SalonUiTheme ui,
    required String pseudo,
    required String zone,
    String? pictureUrl,
  }) {
    return Container(
      height: 55,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
        color: ui.card,
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 42,
              height: 42,
              child: pictureUrl != null && pictureUrl.isNotEmpty
                  ? Image.network(
                      pictureUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: ui.bannerFill,
                          child: Icon(
                            LucideIcons.user,
                            color: ui.textMuted,
                            size: 22,
                          ),
                        );
                      },
                    )
                  : ColoredBox(
                      color: ui.bannerFill,
                      child: Icon(
                        LucideIcons.user,
                        color: ui.textMuted,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '@$pseudo',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (zone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    zone,
                    style: TextStyle(
                      color: ui.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPromotionCommissionCard(SalonUiTheme ui) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
        border: Border.all(
          color: ui.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildEditPromotionCommissionRow(
            ui: ui,
            label: AppTranslations.getString(context, 'commission_influencer'),
            value: '8%',
          ),
          const SizedBox(height: 12),
          _buildEditPromotionCommissionRow(
            ui: ui,
            label: AppTranslations.getString(context, 'commission_kbeauty'),
            value: '3%',
          ),
        ],
      ),
    );
  }

  Widget _buildEditPromotionCommissionRow({
    required SalonUiTheme ui,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(LucideIcons.badgePercent, color: ui.textPrimary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<_ConversationLine> _conversationLines() {
    final data = campaignData;
    final initiator =
        (data['initiator'] ?? 'salon').toString().toLowerCase().trim();
    final lines = <_ConversationLine>[];

    void addLine(String? text, bool isSalon, dynamic dateRaw) {
      final t = text?.toString().trim() ?? '';
      if (t.isEmpty) return;
      DateTime? dt;
      if (dateRaw != null && dateRaw.toString().isNotEmpty) {
        try {
          dt = DateTime.parse(dateRaw.toString());
        } catch (_) {}
      }
      lines.add(_ConversationLine(text: t, isSalon: isSalon, at: dt));
    }

    final invitation = data['invitationMessage']?.toString().trim() ?? '';
    if (invitation.isNotEmpty) {
      final salonStarted = initiator == 'salon';
      addLine(invitation, salonStarted, data['createdAt']);
    }

    final influencerReply =
        data['influencerReplyMessage']?.toString().trim() ?? '';
    if (influencerReply.isNotEmpty) {
      addLine(influencerReply, false, data['updatedAt']);
    }

    final salonReply = data['replyMessage']?.toString().trim() ?? '';
    if (salonReply.isNotEmpty && salonReply != invitation) {
      addLine(salonReply, true, data['updatedAt']);
    }

    return lines;
  }

  String _formatConversationTimestamp(DateTime dt) {
    final loc = Localizations.localeOf(context);
    return DateFormat('d MMM y HH:mm', loc.toString()).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);

        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: ui.systemOverlay,
              child: ColoredBox(
                color: ui.bg,
                child: Scaffold(
                  resizeToAvoidBottomInset: true,
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: topInset + 180,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: ui.headerGradient,
                              stops: ui.headerStops,
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        bottom: MediaQuery.viewInsetsOf(context).bottom == 0,
                        child: _isLoading
                            ? Padding(
                                padding: EdgeInsets.only(top: topInset),
                                child: _buildShimmerContent(ui),
                              )
                            : _selectedTabIndex == 0
                                ? SingleChildScrollView(
                                    controller: _scrollController,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior.onDrag,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(height: topInset + 8),
                                        _buildHeader(ui),
                                        _buildTabBar(ui),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            _CampaignDetailsUi.horizontalPadding,
                                            16,
                                            _CampaignDetailsUi.horizontalPadding,
                                            0,
                                          ),
                                          child: _buildDetailsBody(ui),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            _CampaignDetailsUi.horizontalPadding,
                                            16,
                                            _CampaignDetailsUi.horizontalPadding,
                                            28,
                                          ),
                                          child: _buildActionButtons(ui),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(height: topInset + 8),
                                      _buildHeader(ui),
                                      _buildTabBar(ui),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          controller:
                                              _conversationScrollController,
                                          keyboardDismissBehavior:
                                              ScrollViewKeyboardDismissBehavior
                                                  .onDrag,
                                          child: _buildConversationScrollBody(ui),
                                        ),
                                      ),
                                      _buildConversationComposer(ui),
                                    ],
                                  ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection: 1.57,
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
                            final random =
                                (DateTime.now().millisecondsSinceEpoch % 4);
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
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _CampaignDetailsUi.horizontalPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (mounted) {
                context.read<CampaignsBloc>().add(RefreshCampaigns(
                      status: 'pending',
                      limit: 10,
                    ));
              }
              Navigator.of(context).pop();
            },
            child: Container(
              width: _CampaignDetailsUi.buttonSize,
              height: _CampaignDetailsUi.buttonSize,
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
                    BorderRadius.circular(_CampaignDetailsUi.buttonRadius),
                border: ui.isDark
                    ? null
                    : Border.all(color: ui.cardBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.62,
                ),
                child: _buildStatusButton(ui),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(SalonUiTheme ui) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _CampaignDetailsUi.horizontalPadding,
        8,
        _CampaignDetailsUi.horizontalPadding,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabLabel(
              ui: ui,
              index: 0,
              labelKey: 'tab_details',
            ),
          ),
          Expanded(
            child: CampaignConversationTabLabel(
              selected: _selectedTabIndex == 1,
              label: AppTranslations.getString(context, 'tab_conversation'),
              selectedColor: ui.textPrimary,
              unselectedColor: ui.textSecondary,
              pulseColor: SalonUiTheme.accentBlue,
              onTap: () async {
                setState(() => _selectedTabIndex = 1);
                await _attachChatSocket();
                _scrollContentToBottom();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel({
    required SalonUiTheme ui,
    required int index,
    required String labelKey,
  }) {
    final selected = _selectedTabIndex == index;
    return InkWell(
      onTap: () async {
        if (index == 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        setState(() => _selectedTabIndex = index);
        if (index == 1) {
          await _attachChatSocket();
          _scrollContentToBottom();
        }
      },
      child: Column(
        children: [
          Text(
            AppTranslations.getString(context, labelKey),
            style: TextStyle(
              color: selected ? ui.textPrimary : ui.textSecondary,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: selected ? ui.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBody(SalonUiTheme ui) {
    final status = campaignData['status']?.toString().toLowerCase().trim() ?? '';

    if (status == 'finished') {
      return _buildFinishedDetailsBody(ui);
    }

    if (status == 'in progress' || status == 'on_going' || status == 'ongoing') {
      return _buildOngoingDetailsBody(ui);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreatedAtInline(ui),
        const SizedBox(height: 18),
        _buildCampaignWithSection(ui),
        const SizedBox(height: 16),
        if (_campaignLink.isNotEmpty) ...[
          _buildDarkActionButton(
            ui: ui,
            label: AppTranslations.getString(context, 'copy_link'),
            icon: LucideIcons.link,
            onTap: _copyCampaignLink,
          ),
          const SizedBox(height: 12),
        ],
        if (_canEditCampaignValue) ...[
          _buildDarkActionButton(
            ui: ui,
            label: AppTranslations.getString(context, 'edit_promotion'),
            icon: LucideIcons.pencil,
            onTap: _showEditPromotionDialog,
          ),
          const SizedBox(height: 12),
        ],
        _buildPromotionCard(ui),
      ],
    );
  }

  Widget _buildOngoingDetailsBody(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCreatedAtInline(ui),
        const SizedBox(height: 18),
        _buildCampaignWithSection(ui),
        const SizedBox(height: 16),
        if (_campaignLink.isNotEmpty) ...[
          _buildDarkActionButton(
            ui: ui,
            label: AppTranslations.getString(context, 'copy_link'),
            icon: LucideIcons.link,
            onTap: _copyCampaignLink,
          ),
          const SizedBox(height: 12),
        ],
        _buildStatsCard(ui: ui, showViewOrders: true),
      ],
    );
  }

  Widget _buildFinishedDetailsBody(SalonUiTheme ui) {
    final finishedRaw = campaignData['finishedAt'] ??
        campaignData['completedAt'] ??
        campaignData['updatedAt'] ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateInline(
          ui: ui,
          labelKey: 'created_at',
          dateRaw: campaignData['createdAt'] ?? '',
        ),
        const SizedBox(height: 8),
        _buildDateInline(
          ui: ui,
          labelKey: 'finished_at',
          dateRaw: finishedRaw,
        ),
        const SizedBox(height: 18),
        _buildCampaignWithSection(ui),
        const SizedBox(height: 16),
        _buildStatsCard(ui: ui, showViewOrders: true),
      ],
    );
  }

  Widget _buildDateInline({
    required SalonUiTheme ui,
    required String labelKey,
    required dynamic dateRaw,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${AppTranslations.getString(context, labelKey)} ',
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: _formatDate(dateRaw?.toString() ?? ''),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required SalonUiTheme ui,
    required bool showViewOrders,
  }) {
    final clicks = campaignData['clicks'] ?? widget.campaign['clicks'] ?? 0;
    final completedOrders = campaignData['totalCompletedOrders'] ?? 0;
    final totalAmount = campaignData['totalAmount'] ?? 0;
    final promotion = _formatPromotionValue(
      campaignData['promotion'],
      campaignData['promotionType'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFinishedStatCell(
                  ui: ui,
                  label: AppTranslations.getString(context, 'promotion'),
                  value: promotion,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinishedStatCell(
                  ui: ui,
                  label: AppTranslations.getString(context, 'clicks'),
                  value: _formatNumber(clicks),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFinishedStatCell(
                  ui: ui,
                  label: AppTranslations.getString(context, 'completed_orders'),
                  value: _formatNumber(completedOrders),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFinishedStatCell(
                  ui: ui,
                  label: AppTranslations.getString(context, 'total'),
                  value: '${_formatNumber(totalAmount)} EUR',
                ),
              ),
            ],
          ),
          if (showViewOrders) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          OrdersScreen(campaign: widget.campaign),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ui.textPrimary,
                  side: BorderSide(color: ui.outlinedButtonBorder, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_CampaignDetailsUi.radius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppTranslations.getString(context, 'view_orders'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.shoppingBag, size: 18, color: ui.textPrimary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinishedStatCell({
    required SalonUiTheme ui,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ui.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  String _formatNumber(dynamic value) {
    final intValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
    final raw = intValue.toString();
    final buf = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buf.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String get _campaignLink {
    final link = campaignData['link']?.toString() ??
        widget.campaign['link']?.toString() ??
        '';
    return link.trim();
  }

  void _copyCampaignLink() {
    final link = _campaignLink;
    if (link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
    TopNotificationService.showSuccess(
      context: context,
      message: AppTranslations.getString(context, 'campaign_link_copied'),
    );
  }

  Widget _buildCreatedAtInline(SalonUiTheme ui) {
    return _buildDateInline(
      ui: ui,
      labelKey: 'created_at',
      dateRaw: campaignData['createdAt'] ?? '',
    );
  }

  Widget _buildDarkActionButton({
    required SalonUiTheme ui,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ui.card,
      borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
            border: Border.all(color: ui.cardBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ui.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: ui.textPrimary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionCard(SalonUiTheme ui) {
    return _buildInfoCard(
      ui: ui,
      label: AppTranslations.getString(context, 'promotion'),
      value: _formatPromotionValue(
        campaignData['promotion'],
        campaignData['promotionType'],
      ),
    );
  }

  Widget _buildInfoCard({
    required SalonUiTheme ui,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: ui.card,
        borderRadius: BorderRadius.circular(_CampaignDetailsUi.radius),
        border: Border.all(color: ui.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ui.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationScrollBody(SalonUiTheme ui) {
    if (_campaignMessagesLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Center(
          child: CircularProgressIndicator(
            color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
          ),
        ),
      );
    }

    final lines = _mergedConversationLines();
    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Text(
          AppTranslations.getString(context, 'conversation_empty'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui.textMuted,
            fontSize: 15,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (lines.length >= 2 && i == lines.length - 1) ...[
              const SizedBox(height: 8),
              _buildNewMessageDivider(ui),
              const SizedBox(height: 16),
            ],
            _buildConversationBubble(ui, lines[i]),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNewMessageDivider(SalonUiTheme ui) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: ui.borderSubtle.withValues(alpha: 0.35),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppTranslations.getString(context, 'new_message'),
            style: TextStyle(
              color: ui.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: ui.borderSubtle.withValues(alpha: 0.35),
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildConversationBubble(SalonUiTheme ui, _ConversationLine line) {
    final maxW = MediaQuery.of(context).size.width * 0.78;
    return Align(
      alignment: line.isSalon ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            line.isSalon ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (line.at != null)
            Padding(
              padding: EdgeInsets.only(
                bottom: 6,
                left: line.isSalon ? 0 : 4,
                right: line.isSalon ? 4 : 0,
              ),
              child: Text(
                _formatConversationTimestamp(line.at!),
                style: TextStyle(
                  color: ui.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ui.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.cardBorder, width: 1),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  line.text,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationComposer(SalonUiTheme ui) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    // Body is already resized above the keyboard; only add home-indicator padding.
    final bottomPad =
        12.0 + (viewInsets.bottom > 0 ? 0.0 : viewPadding.bottom);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
        child: _canSendCampaignChat
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyMessageController,
                      focusNode: _replyFocusNode,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 5,
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 15,
                      ),
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: AppTranslations.getString(
                          context,
                          'type_a_message',
                        ),
                        hintStyle: TextStyle(
                          color: ui.textMuted,
                        ),
                        filled: true,
                        fillColor: ui.card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: ui.textPrimary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: ui.primaryButtonBg,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _sendConversationMessage,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          LucideIcons.send,
                          color: ui.primaryButtonFg,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad),
                child: Text(
                  AppTranslations.getString(
                    context,
                    'conversation_cannot_reply',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ui.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _sendConversationMessage() async {
    final campaignId = widget.campaign['id']?.toString();
    if (campaignId == null || campaignId.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Campaign ID not found',
      );
      return;
    }

    final text = _replyMessageController.text.trim();
    if (text.isEmpty) {
      TopNotificationService.showError(
        context: context,
        message: 'Please enter a message',
      );
      return;
    }

    final sent = await _chatSocket.sendMessage(campaignId, text);
    if (!sent || !mounted) return;

    _replyMessageController.clear();

    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
      _scrollContentToBottom();
    }
  }

  Widget _buildCampaignWithSection(SalonUiTheme ui) {
    final influencerId = campaignData['influencer']?['id']?.toString() ??
        widget.campaign['influencer']?['id']?.toString();
    final pseudo =
        campaignData['influencer']?['profile']?['pseudo']?.toString() ??
            'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'campaign_with'),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (influencerId == null || influencerId.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => InfluencerDetailsBloc(),
                  child: InfluencerDetailsScreen(
                    influencerId: influencerId,
                  ),
                ),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _buildProfilePicture(ui),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '@$pseudo',
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(SalonUiTheme ui) {
    final status = campaignData['status']?.toString().toLowerCase() ?? '';

    String label;
    IconData icon;

    if (status == 'finished') {
      label = AppTranslations.getString(context, 'finished');
      icon = LucideIcons.checkCheck;
    } else if (status == 'rejected') {
      label = AppTranslations.getString(context, 'rejected');
      icon = LucideIcons.xCircle;
    } else if (status == 'pending') {
      final initiator = campaignData['initiator'] ?? 'salon';
      label = initiator == 'influencer'
          ? AppTranslations.getString(context, 'waiting_for_salon')
          : AppTranslations.getString(context, 'waiting_for_influencer');
      icon = initiator == 'influencer'
          ? LucideIcons.store
          : LucideIcons.userSquare;
    } else {
      label = AppTranslations.getString(context, 'on_going_status');
      icon = LucideIcons.circleDotDashed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ui.primaryButtonBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: ui.primaryButtonFg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, color: ui.primaryButtonFg, size: 14),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SalonUiTheme ui) {
    final status = campaignData['status']?.toString().toLowerCase() ?? '';
    final initiator = campaignData['initiator'] ?? 'salon';

    if (status == 'finished' || status == 'rejected') {
      return const SizedBox.shrink();
    }

    if (status == 'pending') {
      if (initiator == 'influencer') {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _acceptCampaign(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ui.primaryButtonBg,
                  foregroundColor: ui.primaryButtonFg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_CampaignDetailsUi.radius),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        AppTranslations.getString(context, 'accept_campaign'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.checkCheck, size: 18, color: ui.primaryButtonFg),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDarkActionButton(
              ui: ui,
              label: AppTranslations.getString(context, 'refuse_campaign'),
              icon: LucideIcons.x,
              onTap: () => _refuseCampaign(),
            ),
          ],
        );
      }

      return _buildDarkActionButton(
        ui: ui,
        label: AppTranslations.getString(context, 'delete_campaign'),
        icon: LucideIcons.xCircle,
        onTap: _showDeleteCampaignDialog,
      );
    }

    return _buildDarkActionButton(
      ui: ui,
      label: AppTranslations.getString(context, 'finish_campaign'),
      icon: LucideIcons.check,
      onTap: _showFinishCampaignDialog,
    );
  }

  void _showDeleteCampaignDialog() {
    final ui = _salonUi(context);
    final pageContext = context;
    showModalBottomSheet<void>(
      context: pageContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'delete_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'delete_campaign_confirm',
                      ),
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    BlocListener<CampaignsBloc, CampaignsState>(
                      listener: (listenerContext, state) {
                        if (state is CampaignDeleted) {
                          Navigator.of(sheetContext).pop();
                          if (!pageContext.mounted) return;
                          TopNotificationService.showSuccess(
                            context: pageContext,
                            message: state.message,
                          );
                          Navigator.of(pageContext).pop();
                        } else if (state is CampaignsError) {
                          Navigator.of(sheetContext).pop();
                          if (!pageContext.mounted) return;
                          TopNotificationService.showError(
                            context: pageContext,
                            message: state.message,
                          );
                        }
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            sheetContext.read<CampaignsBloc>().add(
                                  DeleteCampaign(
                                    campaignId: widget.campaign['id'],
                                  ),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _CampaignDetailsUi.radius,
                              ),
                            ),
                          ),
                          child: Text(
                            AppTranslations.getString(
                              sheetContext,
                              'delete_campaign_confirm_button',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ui.textPrimary,
                          side: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
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

  Future<void> _acceptCampaign() async {
    final stripeStatus = await StripeService.verifyAccountStatus();
    if (!mounted) return;

    final isOnboarded =
        stripeStatus['success'] == true &&
        (stripeStatus['data'] as Map<String, dynamic>?)?['isOnboarded'] == true;

    if (!isOnboarded) {
      await StripeLinkRequiredDialog.show(context);
      return;
    }

    _showAcceptCampaignDialog();
  }

  void _showAcceptCampaignDialog() {
    final ui = _salonUi(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'accept_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'confirm_accept_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _performAcceptCampaign();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ui.primaryButtonBg,
                          foregroundColor: ui.primaryButtonFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'confirm'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ui.textPrimary,
                          side: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        builder: (context) {
          final ui = _salonUi(context);
          return Center(
            child: CircularProgressIndicator(
              color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
            ),
          );
        },
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
      } else if (result['stripeAccountNotLinked'] == true) {
        await StripeLinkRequiredDialog.show(context);
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
    final ui = _salonUi(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'are_you_sure_refuse_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'no_going_back_warning',
                      ),
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _performRefuseCampaign();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(
                            sheetContext,
                            'yes_refuse',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ui.textPrimary,
                          side: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        builder: (context) {
          final ui = _salonUi(context);
          return Center(
            child: CircularProgressIndicator(
              color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
            ),
          );
        },
      );

      final result = await InfluencersService.refuseInfluencerInvite(
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

        // Refresh campaign data to show the message
        await _fetchFreshCampaignData();
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

  // ignore: unused_element
  void _showReplyDialog() {
    final ui = _salonUi(context);
    _replyMessageController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: ui.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: ui.sheetHeaderGradient,
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppTranslations.getString(sheetContext, 'reply'),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppTranslations.getString(
                            sheetContext,
                            'message_to_influencer',
                          ),
                          style: TextStyle(
                            color: ui.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: ui.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ui.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _replyMessageController,
                            maxLines: 5,
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: AppTranslations.getString(
                                sheetContext,
                                'write_message',
                              ),
                              hintStyle: TextStyle(
                                color: ui.textMuted,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppTranslations.getString(
                            sheetContext,
                            'single_message_allowed',
                          ),
                          style: TextStyle(
                            color: ui.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _performReply();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ui.primaryButtonBg,
                              foregroundColor: ui.primaryButtonFg,
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
                                      sheetContext,
                                      'send_reply',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.send,
                                  size: 20,
                                  color: ui.primaryButtonFg,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: ui.outlinedButtonBorder,
                                width: 1,
                              ),
                              foregroundColor: ui.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              AppTranslations.getString(
                                sheetContext,
                                'cancel',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performReply() async {
    final campaignId = widget.campaign['id']?.toString();
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

    final sent = await _chatSocket.sendMessage(campaignId, replyMessage);
    if (!sent || !mounted) return;

    _replyMessageController.clear();
  }

  Widget _buildProfilePicture(SalonUiTheme ui) {
    final profilePicture =
        campaignData['influencer']?['profile']?['profilePicture'] ??
            widget.campaign['influencer']?['profile']?['profilePicture'];

    Widget placeholder() {
      return ColoredBox(
        color: ui.bannerFill,
        child: Center(
          child: Icon(Icons.person, color: ui.textMuted, size: 22),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 44,
        height: 44,
        child: profilePicture != null && profilePicture.toString().isNotEmpty
            ? Image.network(
                profilePicture.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return placeholder();
                },
              )
            : placeholder(),
      ),
    );
  }

  Widget _buildShimmerContent(SalonUiTheme ui) {
    final shimmerBase =
        ui.isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final shimmerHighlight =
        ui.isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ui.bannerFill,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            // Campaign Information shimmer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campaign with section shimmer
                  _buildShimmerCampaignWithSection(ui),
                  const SizedBox(height: 24),

                  // Created at section shimmer
                  _buildShimmerCreatedAtSection(ui),
                  const SizedBox(height: 24),

                  // Promotion section shimmer
                  _buildShimmerPromotionSection(ui),
                  const SizedBox(height: 24),

                  // Clicks section shimmer
                  _buildShimmerClicksSection(ui),
                  const SizedBox(height: 24),

                  // Completed orders section shimmer
                  _buildShimmerCompletedOrdersSection(ui),
                  const SizedBox(height: 24),

                  // View orders button shimmer (only for finished/ongoing campaigns)
                  _buildShimmerViewOrdersButton(ui),
                  const SizedBox(height: 24),

                  // Total section shimmer
                  _buildShimmerTotalSection(ui),
                  const SizedBox(height: 20),

                  // Action buttons shimmer
                  _buildShimmerActionButtons(ui),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCampaignWithSection(SalonUiTheme ui) {
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
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              height: 24,
              width: 120,
              decoration: BoxDecoration(
                color: ui.bannerFill,
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
                color: ui.bannerFill,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: ui.bannerFill,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerCreatedAtSection(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 80,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 120,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerPromotionSection(SalonUiTheme ui) {
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
                  color: ui.bannerFill,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: ui.bannerFill,
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
                  color: ui.bannerFill,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: ui.bannerFill,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerClicksSection(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 60,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 100,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCompletedOrdersSection(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 120,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 80,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerViewOrdersButton(SalonUiTheme ui) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ui.bannerFill,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildShimmerTotalSection(SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 50,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: 120,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerActionButtons(SalonUiTheme ui) {
    return Column(
      children: [
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ui.bannerFill,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ui.bannerFill,
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
    final ui = _salonUi(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'finish_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'confirm_finish_campaign',
                      ),
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _finishCampaign();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ui.primaryButtonBg,
                          foregroundColor: ui.primaryButtonFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'confirm'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ui.textPrimary,
                          side: BorderSide(
                            color: ui.outlinedButtonBorder,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _CampaignDetailsUi.radius,
                            ),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        builder: (context) {
          final ui = _salonUi(context);
          return Center(
            child: CircularProgressIndicator(
              color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
            ),
          );
        },
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
        builder: (context) {
          final ui = _salonUi(context);
          return Center(
            child: CircularProgressIndicator(
              color: ui.isDark ? Colors.white : SalonUiTheme.blueUpper,
            ),
          );
        },
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
      builder: (context) {
        final ui = SalonUiTheme.from(context.read<ThemeBloc>().state.brightness);
        return _buildThankYouModal(ui);
      },
    );
  }

  Widget _buildThankYouModal(SalonUiTheme ui) {
    return Container(
      decoration: BoxDecoration(
        color: ui.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ui.sheetHeaderGradient,
                  stops: const [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppTranslations.getString(
                    context,
                    'thank_you_for_reviewing',
                  ),
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.getString(
                    context,
                    'thank_you_helping_message',
                  ),
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: ui.outlinedButtonBorder,
                        width: 1,
                      ),
                      foregroundColor: ui.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      AppTranslations.getString(context, 'close'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationLine {
  final String text;
  final bool isSalon;
  final DateTime? at;

  _ConversationLine({
    required this.text,
    required this.isSalon,
    this.at,
  });
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
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);

        return Container(
          decoration: BoxDecoration(
            color: ui.bg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
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
                    Text(
                      AppTranslations.getString(context, 'how_was_it'),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.getString(context, 'rate_review'),
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppTranslations.getString(context, 'rate'),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              index < selectedStars
                                  ? Icons.star
                                  : Icons.star_border,
                              color: SalonUiTheme.accentBlue,
                              size: 42,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppTranslations.getString(context, 'review'),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: ui.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ui.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: reviewController,
                        maxLines: 4,
                        style: TextStyle(
                          color: ui.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: AppTranslations.getString(
                            context,
                            'describe_your_review',
                          ),
                          hintStyle: TextStyle(
                            color: ui.textMuted,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: ui.outlinedButtonBorder,
                                width: 1,
                              ),
                              foregroundColor: ui.textPrimary,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedStars > 0
                                ? () {
                                    widget.onSubmitRating(
                                      selectedStars,
                                      reviewController.text,
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ui.primaryButtonBg,
                              foregroundColor: ui.primaryButtonFg,
                              disabledBackgroundColor:
                                  ui.primaryButtonBg.withValues(alpha: 0.5),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
