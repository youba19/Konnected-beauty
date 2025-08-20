# TopNotificationService - Reusable Notification Widget

A professional, reusable notification widget that displays top-center notifications matching the Konnected Beauty design system.

## 🎨 Features

- **Top-center positioning**: Notifications appear at the top-center of the screen
- **Pill-shaped design**: Rounded corners (25px radius) for modern appearance
- **Professional styling**: White text, shadows, Montserrat font
- **Multiple types**: Success, Error, Warning, Info, and Custom
- **Icon support**: Optional icons for better visual communication
- **Customizable duration**: Configurable display time
- **Callback support**: Execute actions when notifications dismiss

## 🚀 Quick Start

### 1. Import the service

```dart
import 'package:your_app/widgets/common/top_notification_banner.dart';
```

### 2. Basic Usage

```dart
// Success notification (green)
TopNotificationService.showSuccess(
  context: context,
  message: 'Operation completed successfully!',
);

// Error notification (red)
TopNotificationService.showError(
  context: context,
  message: 'Something went wrong. Please try again.',
);

// Warning notification (orange)
TopNotificationService.showWarning(
  context: context,
  message: 'Please check your input data',
);

// Info notification (blue)
TopNotificationService.showInfo(
  context: context,
  message: 'New feature available!',
);
```

## ⚙️ Advanced Usage

### Custom Notification

```dart
TopNotificationService.show(
  context: context,
  message: 'Custom notification with icon',
  backgroundColor: Colors.purple,
  icon: Icons.star,
  duration: const Duration(seconds: 5),
);
```

### Notification with Callback

```dart
TopNotificationService.showSuccess(
  context: context,
  message: 'Data saved! Tap to continue',
  duration: const Duration(seconds: 4),
  onDismiss: () {
    // This will be called when notification disappears
    Navigator.of(context).pushNamed('/next-screen');
  },
);
```

## 🎯 Use Cases

### 1. Form Submissions
```dart
// After successful form submission
TopNotificationService.showSuccess(
  context: context,
  message: 'Profile updated successfully!',
);
```

### 2. Error Handling
```dart
// When API call fails
TopNotificationService.showError(
  context: context,
  message: 'Network error. Please check your connection.',
);
```

### 3. User Feedback
```dart
// When user action is required
TopNotificationService.showWarning(
  context: context,
  message: 'Please fill in all required fields',
);
```

### 4. Information Display
```dart
// When showing important info
TopNotificationService.showInfo(
  context: context,
  message: 'New messages available',
);
```

## 🎨 Design Specifications

- **Position**: Top-center of screen
- **Shape**: Pill-shaped with 25px border radius
- **Colors**:
  - Success: `#4CAF50` (Bright green)
  - Error: `#D32F2F` (Muted red)
  - Warning: `#FF9800` (Orange)
  - Info: `#2196F3` (Blue)
- **Typography**: Montserrat, 16px, FontWeight.w500
- **Shadow**: Subtle black shadow with 8px blur
- **Padding**: 20px horizontal, 16px vertical
- **Margin**: 12px from top

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop

## 🔧 Customization

### Custom Colors
```dart
TopNotificationService.show(
  context: context,
  message: 'Custom colored notification',
  backgroundColor: Colors.deepPurple,
);
```

### Custom Duration
```dart
TopNotificationService.showSuccess(
  context: context,
  message: 'This will stay longer',
  duration: const Duration(seconds: 8),
);
```

### Custom Icon
```dart
TopNotificationService.show(
  context: context,
  message: 'Notification with custom icon',
  backgroundColor: Colors.teal,
  icon: Icons.favorite,
);
```

## 📋 Migration from Old System

If you were using the old notification methods, simply replace:

**Old:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Message'),
    backgroundColor: Colors.green,
  ),
);
```

**New:**
```dart
TopNotificationService.showSuccess(
  context: context,
  message: 'Message',
);
```

## 🎯 Best Practices

1. **Keep messages concise**: Notifications should be readable at a glance
2. **Use appropriate types**: Match notification type to message content
3. **Consistent timing**: Use standard 3-second duration for most messages
4. **Clear language**: Use simple, action-oriented language
5. **Icon consistency**: Use standard Material Icons for consistency

## 🐛 Troubleshooting

### Notification not appearing?
- Ensure `context` is valid and mounted
- Check that `Overlay.of(context)` is available
- Verify the widget tree is properly built

### Wrong positioning?
- The notification automatically uses `SafeArea`
- Position is always top-center regardless of screen size
- Works with different app bar heights

### Styling issues?
- Colors are predefined for consistency
- Font family defaults to Montserrat
- Shadow and border radius are fixed for design consistency

## 📚 Examples

See `notification_examples.dart` for complete usage examples and the `ExampleScreen` widget for a demo interface.
