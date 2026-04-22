import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konnected_beauty/core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_notifications/salon_notifications_bloc.dart';
import '../../../../core/services/firebase_notification_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'campaign_details_screen.dart';

class SalonNotificationsScreen extends StatelessWidget {
  const SalonNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: BlocProvider(
            create: (context) =>
                SalonNotificationsBloc()..add(LoadSalonNotifications()),
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
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: AppTheme.textPrimaryColor, // White
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppTranslations.getString(context, 'notifications'),
            style: const TextStyle(
              color: AppTheme.textPrimaryColor, // White
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, Brightness brightness) {
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
            return _buildEmptyState(context, brightness);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SalonNotificationsBloc>()
                  .add(RefreshSalonNotifications());
            },
            color: AppTheme.greenPrimary,
            backgroundColor: AppTheme.getScaffoldBackground(brightness),
            child: ListView.builder(
              padding: EdgeInsets.zero,
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
              color: brightness == Brightness.dark
                  ? AppTheme.borderColorGray.withOpacity(0.3)
                  : AppTheme.lightCardBorderColor.withOpacity(0.3),
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
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor, // White text
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
                    color: brightness == Brightness.dark
                        ? AppTheme
                            .textTertiaryColor // Light gray for timestamps
                        : AppTheme.lightTextSecondaryColor,
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
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor, // White text
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
