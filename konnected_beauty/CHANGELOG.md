# Changelog

## Version 1.0.3+13

### 🎉 New Features

#### Onboarding Experience
- **First-time user onboarding screen**
  - Beautiful onboarding screen with background image
  - Language selector with glassmorphism effect (blur and opacity)
  - "Get started" button to begin the app journey
  - Onboarding screen now appears only on first app launch
  - Automatic navigation to welcome screen after onboarding completion

#### Salon Reports & Analytics
- **Comprehensive reports screen**
  - View detailed metrics: Total orders, pending withdrawals, total influencers collaborated with
  - Interactive charts showing orders and revenue trends
  - Date range filtering (defaults to last 3 months)
  - Filter by specific influencers (only those the salon has collaborated with)
  - Back navigation arrow for easy navigation
  - Fully translated interface

#### Campaign Management Improvements
- **Enhanced campaigns screen**
  - Larger influencer profile images for better visibility
  - Improved campaign card layout
  - Better visual hierarchy and spacing

### 🔧 Improvements

#### User Experience
- Language dropdown moved from welcome screen to onboarding screen
- Improved navigation flow between screens
- Better visual consistency across the app

#### Technical Improvements
- Enhanced API request logging for debugging
- Improved filter functionality with proper date formatting
- Better error handling and user feedback
- Optimized influencer list loading (only collaborated influencers shown in filters)

### 🐛 Bug Fixes
- Fixed filter not applying correctly in reports screen
- Fixed influencer ID extraction from campaign data
- Improved date formatting for API requests (end-of-day handling)
- Fixed onboarding screen persistence logic

### 🌐 Localization
- Added new translation keys:
  - `reports` (for reports screen)
  - `since`
  - `number_orders`
  - `pending_withdraw`
  - `total_influencers_worked_with`
  - `orders`
  - `filter_from`
  - `filter_to`
  - `unknown`
  - `get_started`
  - `welcome_title`

### 📱 Platform-Specific
- iOS notification configuration improvements
- Firebase integration enhancements
- Better handling of push notifications

---

## Previous Versions

### Version 1.0.2
- Initial release with core features
- Salon and influencer authentication
- Campaign creation and management
- Basic wallet functionality
- Profile management

### Version 1.0.1
- Early beta release
- Basic UI implementation
- API integration foundation

### Version 1.0.0
- Initial app release


