import 'package:flutter/material.dart';
import 'top_notification_banner.dart';

/// Example usage of TopNotificationService in different screens
/// This file demonstrates how to use the reusable notification widget
class NotificationExamples {
  /// Example 1: Basic success notification
  static void showBasicSuccess(BuildContext context) {
    TopNotificationService.showSuccess(
      context: context,
      message: 'Operation completed successfully!',
    );
  }

  /// Example 2: Basic error notification
  static void showBasicError(BuildContext context) {
    TopNotificationService.showError(
      context: context,
      message: 'Something went wrong. Please try again.',
    );
  }

  /// Example 3: Custom notification with icon
  static void showCustomNotification(BuildContext context) {
    TopNotificationService.show(
      context: context,
      message: 'Custom notification with icon',
      backgroundColor: Colors.purple,
      icon: Icons.star,
      duration: const Duration(seconds: 5),
    );
  }

  /// Example 4: Warning notification
  static void showWarning(BuildContext context) {
    TopNotificationService.showWarning(
      context: context,
      message: 'Please check your input data',
    );
  }

  /// Example 5: Info notification
  static void showInfo(BuildContext context) {
    TopNotificationService.showInfo(
      context: context,
      message: 'New feature available!',
    );
  }

  /// Example 6: Notification with callback
  static void showNotificationWithCallback(BuildContext context) {
    TopNotificationService.showSuccess(
      context: context,
      message: 'Data saved! Tap to continue',
      duration: const Duration(seconds: 4),
      onDismiss: () {
        // This will be called when notification disappears
        print('Notification dismissed');
        // You can navigate to another screen or perform any action
        // Navigator.of(context).pushNamed('/next-screen');
      },
    );
  }

  /// Example 7: Long duration notification
  static void showLongNotification(BuildContext context) {
    TopNotificationService.show(
      context: context,
      message: 'This notification will stay longer for important messages',
      backgroundColor: Colors.orange,
      duration: const Duration(seconds: 8),
    );
  }
}

/// Example widget showing how to use notifications in a screen
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Examples'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => NotificationExamples.showBasicSuccess(context),
              child: const Text('Show Success'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationExamples.showBasicError(context),
              child: const Text('Show Error'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationExamples.showWarning(context),
              child: const Text('Show Warning'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationExamples.showInfo(context),
              child: const Text('Show Info'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  NotificationExamples.showCustomNotification(context),
              child: const Text('Show Custom'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  NotificationExamples.showNotificationWithCallback(context),
              child: const Text('With Callback'),
            ),
          ],
        ),
      ),
    );
  }
}
