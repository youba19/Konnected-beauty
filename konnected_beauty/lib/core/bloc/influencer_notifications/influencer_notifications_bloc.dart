import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/influencer_notification_service.dart';

// Events
abstract class InfluencerNotificationsEvent {}

class LoadNotifications extends InfluencerNotificationsEvent {
  final int page;
  final int limit;

  LoadNotifications({this.page = 1, this.limit = 10});
}

class RefreshNotifications extends InfluencerNotificationsEvent {}

class MarkNotificationAsViewed extends InfluencerNotificationsEvent {
  final String notificationId;
  final String token;

  MarkNotificationAsViewed({
    required this.notificationId,
    required this.token,
  });
}

// States
abstract class InfluencerNotificationsState {}

class InfluencerNotificationsInitial extends InfluencerNotificationsState {}

class InfluencerNotificationsLoading extends InfluencerNotificationsState {}

class InfluencerNotificationsLoaded extends InfluencerNotificationsState {
  final List<Map<String, dynamic>> notifications;
  final int currentPage;
  final int totalPages;
  final int total;

  InfluencerNotificationsLoaded({
    required this.notifications,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });
}

class InfluencerNotificationsError extends InfluencerNotificationsState {
  final String message;

  InfluencerNotificationsError({required this.message});
}

// BLoC
class InfluencerNotificationsBloc
    extends Bloc<InfluencerNotificationsEvent, InfluencerNotificationsState> {
  InfluencerNotificationsBloc() : super(InfluencerNotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkNotificationAsViewed>(_onMarkNotificationAsViewed);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<InfluencerNotificationsState> emit,
  ) async {
    try {
      emit(InfluencerNotificationsLoading());

      print('🔔 === LOADING NOTIFICATIONS ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');

      final result = await InfluencerNotificationService.getNotifications(
        page: event.page,
        limit: event.limit,
      );

      print('🔔 === NOTIFICATIONS LOAD RESULT ===');
      print('🔔 Success: ${result['success']}');
      print('🔔 Message: ${result['message']}');
      print('🔔 Status Code: ${result['statusCode']}');
      print('🔔 Data Count: ${(result['data'] as List?)?.length ?? 0}');

      if (result['success'] == true) {
        final notifications = (result['data'] as List?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
            [];

        // Debug: Print full response structure
        print('🔔 === FULL API RESPONSE DEBUG ===');
        print('🔔 Complete result: $result');
        print('🔔 Data list: $notifications');
        if (notifications.isNotEmpty) {
          print('🔔 First notification: ${notifications[0]}');
          print(
              '🔔 First notification keys: ${notifications[0].keys.toList()}');
          print(
              '🔔 First notification operationId: ${notifications[0]['operationId']}');
        }
        print('🔔 === END FULL API RESPONSE DEBUG ===');

        emit(InfluencerNotificationsLoaded(
          notifications: notifications,
          currentPage: result['currentPage'] ?? 1,
          totalPages: result['totalPages'] ?? 1,
          total: result['total'] ?? 0,
        ));
      } else {
        print('❌ Failed to load notifications: ${result['message']}');
        emit(InfluencerNotificationsError(
            message: result['message'] ?? 'Failed to load notifications'));
      }
    } catch (e) {
      print('❌ Exception in _onLoadNotifications: $e');
      emit(InfluencerNotificationsError(
          message: 'Error loading notifications: $e'));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<InfluencerNotificationsState> emit,
  ) async {
    print('🔄 === REFRESHING NOTIFICATIONS ===');
    add(LoadNotifications(page: 1, limit: 10));
  }

  Future<void> _onMarkNotificationAsViewed(
    MarkNotificationAsViewed event,
    Emitter<InfluencerNotificationsState> emit,
  ) async {
    try {
      print('✅ === MARKING NOTIFICATION AS VIEWED ===');
      print('🆔 Notification ID: ${event.notificationId}');

      final result =
          await InfluencerNotificationService.markNotificationAsViewed(
        notificationId: event.notificationId,
        token: event.token,
      );

      if (result['success'] == true) {
        print('✅ Notification marked as viewed successfully');
        print('✅ API Response: ${result['message']}');
        // Update the notification in the current state if loaded
        if (state is InfluencerNotificationsLoaded) {
          final currentState = state as InfluencerNotificationsLoaded;
          print(
              '🔄 Current state has ${currentState.notifications.length} notifications');
          print('🔄 Looking for notification ID: ${event.notificationId}');

          final updatedNotifications =
              currentState.notifications.map((notification) {
            if (notification['id'] == event.notificationId) {
              print('✅ Found notification, updating isVued to true');
              print('📋 Before: isVued = ${notification['isVued']}');
              final updated = {...notification, 'isVued': true};
              print('📋 After: isVued = ${updated['isVued']}');
              return updated;
            }
            return notification;
          }).toList();

          print(
              '🔄 Emitting updated state with ${updatedNotifications.length} notifications');
          emit(InfluencerNotificationsLoaded(
            notifications: updatedNotifications,
            currentPage: currentState.currentPage,
            totalPages: currentState.totalPages,
            total: currentState.total,
          ));
          print('✅ State updated successfully');
        } else {
          print(
              '⚠️ Current state is not InfluencerNotificationsLoaded: ${state.runtimeType}');
        }
      } else {
        print('❌ Failed to mark notification as viewed: ${result['message']}');
        print('❌ Result: $result');
      }
    } catch (e) {
      print('❌ Exception in _onMarkNotificationAsViewed: $e');
    }
  }
}
