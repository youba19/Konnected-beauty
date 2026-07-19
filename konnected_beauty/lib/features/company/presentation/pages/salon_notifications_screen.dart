import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_notifications/salon_notifications_bloc.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/services/firebase_notification_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'campaign_details_screen.dart';

abstract final class _SalonNotificationsUi {
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class SalonNotificationsScreen extends StatelessWidget {
  const SalonNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);
        final topInset = MediaQuery.paddingOf(context).top;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ui.systemOverlay,
          child: Scaffold(
            backgroundColor: ui.bg,
            resizeToAvoidBottomInset: false,
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
                  child: BlocProvider(
                    create: (context) => SalonNotificationsBloc()
                      ..add(LoadSalonNotifications()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: _buildHeader(context, ui),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildNotificationsList(context, ui),
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

  Widget _buildHeader(BuildContext context, SalonUiTheme ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: _SalonNotificationsUi.buttonSize,
            height: _SalonNotificationsUi.buttonSize,
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
                  BorderRadius.circular(_SalonNotificationsUi.buttonRadius),
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
        const SizedBox(height: 18),
        Text(
          AppTranslations.getString(context, 'notifications'),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(BuildContext context, SalonUiTheme ui) {
    return BlocBuilder<SalonNotificationsBloc, SalonNotificationsState>(
      builder: (context, state) {
        if (state is SalonNotificationsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.greenPrimary,
            ),
          );
        }

        if (state is SalonNotificationsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: ui.textPrimary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(
                    color: ui.textPrimary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<SalonNotificationsBloc>()
                        .add(RefreshSalonNotifications());
                  },
                  child: Text(AppTranslations.getString(context, 'retry')),
                ),
              ],
            ),
          );
        }

        if (state is SalonNotificationsLoaded) {
          if (state.notifications.isEmpty) {
            return _buildEmptyState(context, ui);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SalonNotificationsBloc>()
                  .add(RefreshSalonNotifications());
            },
            color: Colors.white,
            backgroundColor: SalonUiTheme.blueUpper,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: state.notifications.length,
              key: ValueKey(
                  'notifications_${state.notifications.length}_${state.notifications.map((n) => '${n['id']}_${n['isVued']}').join('_')}'),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _buildNotificationItem(context, notification, ui);
              },
            ),
          );
        }

        return _buildEmptyState(context, ui);
      },
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification, SalonUiTheme ui) {
    // Debug: Print full notification structure
    print('📋 === SALON NOTIFICATION ITEM DEBUG ===');
    print('📋 Full notification: $notification');
    print('📋 Notification keys: ${notification.keys.toList()}');
    print('📋 operationId: ${notification['operationId']}');
    print('📋 operationId type: ${notification['operationId']?.runtimeType}');
    print('📋 id: ${notification['id']}');
    print('📋 isVued: ${notification['isVued']}');
    print('📋 causer: ${notification['causer']}');
    print('📋 === END SALON NOTIFICATION ITEM DEBUG ===');

    // Get locale from context
    final locale = Localizations.localeOf(context);
    final isFrench = locale.languageCode == 'fr';

    // Get title and message based on locale
    final title = isFrench
        ? (notification['titleFr'] ?? notification['titleEn'] ?? '')
        : (notification['titleEn'] ?? notification['titleFr'] ?? '');
    final message = isFrench
        ? (notification['messageFr'] ?? notification['messageEn'] ?? '')
        : (notification['messageEn'] ?? notification['messageFr'] ?? '');

    // Check if notification is read
    // Handle both boolean true and string "true"
    final isVuedValue = notification['isVued'];
    final isRead =
        isVuedValue == true || isVuedValue == 'true' || isVuedValue == 1;

    // Debug log
    if (notification['id'] != null) {
      print(
          '🔍 Salon Notification ${notification['id']}: isVued = $isVuedValue, isRead = $isRead');
    }

    // Parse createdAt timestamp
    String timeAgo = '';
    try {
      final createdAt = notification['createdAt'];
      if (createdAt != null) {
        final dateTime = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(dateTime);

        if (difference.inMinutes < 1) {
          timeAgo = 'now';
        } else if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes}m';
        } else if (difference.inHours < 24) {
          timeAgo = '${difference.inHours}h';
        } else {
          timeAgo = '${difference.inDays}d';
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(context, notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          // Same color as background (no card background difference)
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: ui.cardBorder.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with timestamp
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Time - light gray
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: ui.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Message row with green dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: ui.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Unread indicator (green dot) - same row as description, under the time
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: const BoxDecoration(
                      color: AppTheme.greenPrimary, // Green circle
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
      BuildContext context, Map<String, dynamic> notification) async {
    try {
      // Debug: Print full notification structure
      print('🔔 === FULL SALON NOTIFICATION STRUCTURE ===');
      print('🔔 Complete notification: $notification');
      print('🔔 Notification keys: ${notification.keys.toList()}');
      print('🔔 Notification values: ${notification.values.toList()}');
      print('🔔 operationId value: ${notification['operationId']}');
      print('🔔 operationId type: ${notification['operationId']?.runtimeType}');
      print('🔔 operationId is null: ${notification['operationId'] == null}');
      print(
          '🔔 operationId is empty string: ${notification['operationId'] == ''}');
      print('🔔 id: ${notification['id']}');
      print('🔔 isVued: ${notification['isVued']}');
      print('🔔 causer: ${notification['causer']}');
      print('🔔 causer type: ${notification['causer']?.runtimeType}');
      if (notification['causer'] != null) {
        print(
            '🔔 causer keys: ${(notification['causer'] as Map).keys.toList()}');
      }
      print('🔔 === END FULL SALON NOTIFICATION STRUCTURE ===');

      final notificationId = notification['id'];
      final operationId = notification['operationId'];

      if (operationId == null || operationId.isEmpty) {
        print('❌ Operation ID is null or empty');
        print('❌ operationId value: $operationId');
        print('❌ operationId == null: ${operationId == null}');
        print('❌ operationId.isEmpty: ${operationId?.isEmpty ?? 'N/A'}');
        return;
      }

      print('🔔 === HANDLING SALON NOTIFICATION TAP ===');
      print('🆔 Notification ID: $notificationId');
      print('🎯 Operation ID (Campaign ID): $operationId');

      // Get FCM token (quick check first)
      final notificationService = FirebaseNotificationService();
      String? fcmToken = notificationService.fcmToken;
      final token = fcmToken ?? '';

      // Start marking notification as viewed IMMEDIATELY (non-blocking, in parallel)
      // This happens at the same time as fetching campaign details
      if (notificationId != null &&
          notificationId.isNotEmpty &&
          token.isNotEmpty) {
        // Don't await - run in parallel, don't block navigation
        context.read<SalonNotificationsBloc>().add(
              MarkSalonNotificationAsViewed(
                notificationId: notificationId,
                token: token,
              ),
            );
        print(
            '🔄 Marking salon notification as viewed (in parallel, non-blocking)...');
      } else {
        // If token is not available, try to get it in background
        if (fcmToken == null || fcmToken.isEmpty) {
          notificationService.retrieveFCMToken().then((retrievedToken) {
            if (retrievedToken != null &&
                retrievedToken.isNotEmpty &&
                notificationId != null &&
                notificationId.isNotEmpty) {
              context.read<SalonNotificationsBloc>().add(
                    MarkSalonNotificationAsViewed(
                      notificationId: notificationId,
                      token: retrievedToken,
                    ),
                  );
            }
          });
        }
      }

      // 2. Navigate IMMEDIATELY with minimal campaign data (screen will load details itself)
      // Create minimal campaign object with just the ID - the screen will fetch full details in initState()
      final minimalCampaign = {
        'id': operationId,
      };

      print('✅ Navigating IMMEDIATELY with campaign ID: $operationId');
      print('✅ Screen will load full details in initState() - no waiting!');

      // Navigate IMMEDIATELY - don't wait for anything, both actions happen in one click!
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CampaignDetailsScreen(
            campaign: minimalCampaign,
          ),
        ),
      );
      print(
          '✅ Navigation completed - both actions (mark as viewed + navigate) done in ONE CLICK!');
    } catch (e) {
      print('❌ Error handling salon notification tap: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, SalonUiTheme ui) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ui.textPrimary,
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.bell,
                  color: ui.textPrimary,
                  size: 40,
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    width: 20,
                    height: 2,
                    color: ui.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.getString(context, 'notifications_empty_state'),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
