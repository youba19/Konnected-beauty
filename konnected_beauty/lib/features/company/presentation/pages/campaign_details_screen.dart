import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../../../../core/models/campaign_chat_message.dart';
import '../../../../core/services/api/campaign_messages_service.dart';
import '../../../../core/services/api/influencers_service.dart';
import '../../../../core/services/campaign_chat_socket_service.dart';
import '../../../../widgets/common/campaign_conversation_tab.dart';
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

  Future<void> _showEditPromotionDialog() async {
    final promotionType = _currentPromotionType();
    final isPercentage = promotionType == 'percentage';
    final controller =
        TextEditingController(text: _currentPromotionValue().toString());
    var isSaving = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 0) {
                TopNotificationService.showError(
                  context: context,
                  message: 'Please enter a valid campaign value',
                );
                return;
              }
              if (isPercentage && value > 100) {
                TopNotificationService.showError(
                  context: context,
                  message: 'Percentage value must be between 0 and 100',
                );
                return;
              }

              setDialogState(() => isSaving = true);
              final result = await InfluencersService.updateCampaignPromotion(
                campaignId: campaignData['id']?.toString() ??
                    widget.campaign['id']?.toString() ??
                    '',
                promotion: value,
                promotionType: promotionType,
              );
              if (!mounted || !dialogContext.mounted) return;

              if (result['success'] == true) {
                setState(() {
                  widget.campaign['promotion'] = value;
                  widget.campaign['promotionType'] = promotionType;
                  _freshCampaignData ??= Map<String, dynamic>.from(
                    widget.campaign,
                  );
                  _freshCampaignData!['promotion'] = value;
                  _freshCampaignData!['promotionType'] = promotionType;
                });
                Navigator.of(dialogContext).pop();
                TopNotificationService.showSuccess(
                  context: context,
                  message: 'Campaign value updated',
                );
              } else {
                setDialogState(() => isSaving = false);
                TopNotificationService.showError(
                  context: context,
                  message:
                      result['message']?.toString() ?? 'Failed to update value',
                );
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF1F1D1D),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit campaign value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Update the terms of your collaboration.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        isPercentage
                            ? 'Followers promotion value'
                            : 'Promotion value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          suffixText: isPercentage ? '%' : 'EUR',
                          suffixStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Icon(LucideIcons.percent,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Commission influencer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '8%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Icon(LucideIcons.percent,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Commission Konnected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '3%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Offering a treatment or giving the ambassador a preferential rate is optional and can make collaboration easier.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white70,
                            foregroundColor: const Color(0xFF1F1D1D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1F1D1D),
                                  ),
                                )
                              : const Text(
                                  'Save changes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: Colors.white, width: 1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor:
                const Color(0xFF1F1E1E), // Set scaffold background color
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
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
                  ),
                ),
                SafeArea(
                  bottom: MediaQuery.viewInsetsOf(context).bottom == 0,
                  child: _isLoading
                      ? _buildShimmerContent()
                      : _selectedTabIndex == 0
                          ? SingleChildScrollView(
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(),
                                  _buildTabBar(),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _buildDetailsBody(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 24),
                                    child: _buildActionButtons(),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                _buildTabBar(),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _conversationScrollController,
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    child: _buildConversationScrollBody(),
                                  ),
                                ),
                                _buildConversationComposer(),
                              ],
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
            ));
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
              size: 28,
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
                child: _buildStatusButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTabLabel(
              index: 0,
              labelKey: 'tab_details',
            ),
          ),
          Expanded(
            child: CampaignConversationTabLabel(
              selected: _selectedTabIndex == 1,
              label: AppTranslations.getString(context, 'tab_conversation'),
              selectedColor: Colors.white,
              unselectedColor: Colors.white54,
              pulseColor: AppTheme.greenPrimary,
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

  Widget _buildTabLabel({required int index, required String labelKey}) {
    final selected = _selectedTabIndex == index;
    return InkWell(
      onTap: () async {
        if (index == 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        setState(() => _selectedTabIndex = index);
        // Keep the chat socket alive when switching to Details so the connection is not torn down
        // (reconnecting only when opening Conversation again caused flaky sends after short idle).
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
              color: selected ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBody() {
    return Column(
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
      ],
    );
  }

  Widget _buildConversationScrollBody() {
    if (_campaignMessagesLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white54,
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
          style: const TextStyle(
            color: Colors.white54,
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
              _buildNewMessageDivider(),
              const SizedBox(height: 16),
            ],
            _buildConversationBubble(lines[i]),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNewMessageDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppTranslations.getString(context, 'new_message'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildConversationBubble(_ConversationLine line) {
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
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  line.text,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildConversationComposer() {
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
                      style: const TextStyle(
                        color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _sendConversationMessage,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(
                          LucideIcons.send,
                          color: Colors.black,
                          size: 22,
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
                    color: Colors.white.withValues(alpha: 0.5),
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

  Widget _buildCampaignWithSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppTranslations.getString(context, 'campaign_with'),
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
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
                _formatPromotionValue(
                  campaignData['promotion'],
                  campaignData['promotionType'],
                ),
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
          children: [
            Flexible(
              child: Text(
                AppTranslations.getString(context, 'finished'),
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.done_all_outlined,
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
          children: [
            Flexible(
              child: Text(
                AppTranslations.getString(context, 'rejected'),
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
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
          children: [
            Flexible(
              child: Text(
                statusText,
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
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
          children: [
            Flexible(
              child: Text(
                AppTranslations.getString(context, 'on_going_status'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
        return Column(
          children: [
            if (_canEditCampaignValue) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showEditPromotionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.secondaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Edit campaign value',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.pencil, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
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
            ),
          ],
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
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Warning message
                Text(
                  AppTranslations.getString(context, 'no_going_back_warning'),
                  style: const TextStyle(
                    color: Colors.white,
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
                        side: const BorderSide(color: Colors.white, width: 1),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        AppTranslations.getString(context, 'cancel'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes, Refuse button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _performRefuseCampaign();
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
    _replyMessageController.clear(); // Clear previous message
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppTheme.secondaryColor,
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
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Message to influencer section
                  Text(
                    AppTranslations.getString(context, 'message_to_influencer'),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Text input field
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.border2,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _replyMessageController,
                      maxLines: 5,
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            AppTranslations.getString(context, 'write_message'),
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryColor.withOpacity(0.6),
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
                      color: AppTheme.textSecondaryColor.withOpacity(0.8),
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
                            backgroundColor: Colors.white,
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
                            side: const BorderSide(
                              color: AppTheme.textSecondaryColor,
                              width: 1,
                            ),
                            foregroundColor: AppTheme.textPrimaryColor,
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
                      color: Colors.grey[700],
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
