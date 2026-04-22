import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/salon_notification_service.dart';

// Events
abstract class SalonNotificationsEvent {}

class LoadSalonNotifications extends SalonNotificationsEvent {
  final int page;
  final int limit;

  LoadSalonNotifications({this.page = 1, this.limit = 10});
}

class RefreshSalonNotifications extends SalonNotificationsEvent {}

class MarkSalonNotificationAsViewed extends SalonNotificationsEvent {
  final String notificationId;
  final String token;

  MarkSalonNotificationAsViewed({
    required this.notificationId,
    required this.token,
  });
}

// States
abstract class SalonNotificationsState {}

class SalonNotificationsInitial extends SalonNotificationsState {}

class SalonNotificationsLoading extends SalonNotificationsState {}

class SalonNotificationsLoaded extends SalonNotificationsState {
  final List<Map<String, dynamic>> notifications;
  final int currentPage;
  final int totalPages;
  final int total;

  SalonNotificationsLoaded({
    required this.notifications,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });
}

class SalonNotificationsError extends SalonNotificationsState {
  final String message;

  SalonNotificationsError({required this.message});
}

// BLoC
class SalonNotificationsBloc
    extends Bloc<SalonNotificationsEvent, SalonNotificationsState> {
  SalonNotificationsBloc() : super(SalonNotificationsInitial()) {
    on<LoadSalonNotifications>(_onLoadNotifications);
    on<RefreshSalonNotifications>(_onRefreshNotifications);
    on<MarkSalonNotificationAsViewed>(_onMarkNotificationAsViewed);
  }

  Future<void> _onLoadNotifications(
    LoadSalonNotifications event,
    Emitter<SalonNotificationsState> emit,
  ) async {
    try {
      emit(SalonNotificationsLoading());

      print('🔔 === LOADING SALON NOTIFICATIONS ===');
      print('📄 Page: ${event.page}');
      print('📏 Limit: ${event.limit}');

      final result = await SalonNotificationService.getNotifications(
        page: event.page,
        limit: event.limit,
      );

      print('🔔 === SALON NOTIFICATIONS LOAD RESULT ===');
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

        emit(SalonNotificationsLoaded(
          notifications: notifications,
          currentPage: result['currentPage'] ?? 1,
          totalPages: result['totalPages'] ?? 1,
          total: result['total'] ?? 0,
        ));
      } else {
        print('❌ Failed to load salon notifications: ${result['message']}');
        emit(SalonNotificationsError(
            message: result['message'] ?? 'Failed to load notifications'));
      }
    } catch (e) {
      print('❌ Exception in _onLoadNotifications: $e');
      emit(SalonNotificationsError(message: 'Error loading notifications: $e'));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshSalonNotifications event,
    Emitter<SalonNotificationsState> emit,
  ) async {
    print('🔄 === REFRESHING SALON NOTIFICATIONS ===');
    add(LoadSalonNotifications(page: 1, limit: 10));
  }

  Future<void> _onMarkNotificationAsViewed(
    MarkSalonNotificationAsViewed event,
    Emitter<SalonNotificationsState> emit,
  ) async {
    try {
      print('✅ === MARKING SALON NOTIFICATION AS VIEWED ===');
      print('🆔 Notification ID: ${event.notificationId}');

      final result = await SalonNotificationService.markNotificationAsViewed(
        notificationId: event.notificationId,
        token: event.token,
      );

      if (result['success'] == true) {
        print('✅ Salon notification marked as viewed successfully');
        print('✅ API Response: ${result['message']}');
        // Update the notification in the current state if loaded
        if (state is SalonNotificationsLoaded) {
          final currentState = state as SalonNotificationsLoaded;
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
          emit(SalonNotificationsLoaded(
            notifications: updatedNotifications,
            currentPage: currentState.currentPage,
            totalPages: currentState.totalPages,
            total: currentState.total,
          ));
          print('✅ State updated successfully');
        } else {
          print(
              '⚠️ Current state is not SalonNotificationsLoaded: ${state.runtimeType}');
        }
      } else {
        print(
            '❌ Failed to mark salon notification as viewed: ${result['message']}');
        print('❌ Result: $result');
      }
    } catch (e) {
      print('❌ Exception in _onMarkNotificationAsViewed: $e');
    }
  }
}
