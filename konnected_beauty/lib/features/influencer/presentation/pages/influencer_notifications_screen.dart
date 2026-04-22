import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/influencer_notifications/influencer_notifications_bloc.dart';
import '../../../../core/services/firebase_notification_service.dart';
import '../../../../core/bloc/delete_campaign/delete_campaign_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'campaign_details_screen.dart';

class InfluencerNotificationsScreen extends StatelessWidget {
  const InfluencerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      resizeToAvoidBottomInset: false,
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

          // CONTENT
          SafeArea(
            child: BlocProvider(
              create: (context) =>
                  InfluencerNotificationsBloc()..add(LoadNotifications()),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, brightness),
                  Expanded(
                    child: _buildNotificationsList(context, brightness),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.getTextPrimaryColor(brightness),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'notifications'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(brightness),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, Brightness brightness) {
    return BlocBuilder<InfluencerNotificationsBloc,
        InfluencerNotificationsState>(
      builder: (context, state) {
        if (state is InfluencerNotificationsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.greenPrimary,
            ),
          );
        }

        if (state is InfluencerNotificationsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: AppTheme.getTextPrimaryColor(brightness),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: TextStyle(
                    color: AppTheme.getTextPrimaryColor(brightness),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<InfluencerNotificationsBloc>()
                        .add(RefreshNotifications());
                  },
                  child: Text(AppTranslations.getString(context, 'retry')),
                ),
              ],
            ),
          );
        }

        if (state is InfluencerNotificationsLoaded) {
          if (state.notifications.isEmpty) {
            return _buildEmptyState(context, brightness);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<InfluencerNotificationsBloc>()
                  .add(RefreshNotifications());
            },
            color: AppTheme.greenPrimary,
            backgroundColor: AppTheme.getScaffoldBackground(brightness),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.notifications.length,
              key: ValueKey(
                  'notifications_${state.notifications.length}_${state.notifications.map((n) => '${n['id']}_${n['isVued']}').join('_')}'),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _buildNotificationItem(
                    context, notification, brightness);
              },
            ),
          );
        }

        return _buildEmptyState(context, brightness);
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context,
      Map<String, dynamic> notification, Brightness brightness) {
    // Debug: Print full notification structure
    print('📋 === NOTIFICATION ITEM DEBUG ===');
    print('📋 Full notification: $notification');
    print('📋 Notification keys: ${notification.keys.toList()}');
    print('📋 operationId: ${notification['operationId']}');
    print('📋 operationId type: ${notification['operationId'].runtimeType}');
    print('📋 id: ${notification['id']}');
    print('📋 isVued: ${notification['isVued']}');
    print('📋 causer: ${notification['causer']}');
    print('📋 === END NOTIFICATION ITEM DEBUG ===');

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
          '🔍 Notification ${notification['id']}: isVued = $isVuedValue, isRead = $isRead');
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppTheme.cardBackgroundDark
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                            color: AppTheme.getTextPrimaryColor(brightness),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Time
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(brightness),
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
                            color: AppTheme.getTextPrimaryColor(brightness),
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
                          decoration: BoxDecoration(
                            color: AppTheme.greenPrimary,
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
      BuildContext context, Map<String, dynamic> notification) async {
    try {
      // Debug: Print full notification structure
      print('🔔 === FULL NOTIFICATION STRUCTURE ===');
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
      print('🔔 === END FULL NOTIFICATION STRUCTURE ===');

      final notificationId = notification['id'];
      final operationId = notification['operationId'];

      if (operationId == null || operationId.isEmpty) {
        print('❌ Operation ID is null or empty');
        print('❌ operationId value: $operationId');
        print('❌ operationId == null: ${operationId == null}');
        print('❌ operationId.isEmpty: ${operationId?.isEmpty ?? 'N/A'}');
        return;
      }

      print('🔔 === HANDLING NOTIFICATION TAP ===');
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
        context.read<InfluencerNotificationsBloc>().add(
              MarkNotificationAsViewed(
                notificationId: notificationId,
                token: token,
              ),
            );
        print(
            '🔄 Marking notification as viewed (in parallel, non-blocking)...');
      } else {
        // If token is not available, try to get it in background
        if (fcmToken == null || fcmToken.isEmpty) {
          notificationService.retrieveFCMToken().then((retrievedToken) {
            if (retrievedToken != null &&
                retrievedToken.isNotEmpty &&
                notificationId != null &&
                notificationId.isNotEmpty) {
              context.read<InfluencerNotificationsBloc>().add(
                    MarkNotificationAsViewed(
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
          builder: (context) => BlocProvider(
            create: (context) => DeleteCampaignBloc(),
            child: CampaignDetailsScreen(
              campaign: minimalCampaign,
              onCampaignDeleted: () {
                // Refresh notifications when returning
                if (context.mounted) {
                  context
                      .read<InfluencerNotificationsBloc>()
                      .add(RefreshNotifications());
                }
              },
            ),
          ),
        ),
      );
      print(
          '✅ Navigation completed - both actions (mark as viewed + navigate) done in ONE CLICK!');
    } catch (e) {
      print('❌ Error handling notification tap: $e');
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

  Widget _buildEmptyState(BuildContext context, Brightness brightness) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bell icon with minus sign (no notifications symbol)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.getTextPrimaryColor(brightness),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.bell,
                  color: AppTheme.getTextPrimaryColor(brightness),
                  size: 40,
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    width: 20,
                    height: 2,
                    color: AppTheme.getTextPrimaryColor(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppTranslations.getString(context, 'notifications_empty_state'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(brightness),
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
