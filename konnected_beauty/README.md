# Konnected Beauty

A Flutter application that connects beauty companies with influencers for marketing campaigns.

## Features

### For Companies
- Create and manage company profiles
- Upload business details, services, and photos
- Create and manage marketing campaigns
- Track campaign performance and analytics
- Generate voucher codes for promotions
- Payment management and tracking

### For Influencers/Ambassadors
- Create influencer profiles with social media links
- Browse and apply for campaigns
- Generate unique tracking links
- Track performance metrics (clicks, conversions, earnings)
- Manage campaign history and earnings

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   ├── company/
│   ├── influencer/
│   └── shared/
└── widgets/
    ├── common/
    ├── forms/
    └── loading/
```

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/youba19/Konnected-beauty.git
cd konnected_beauty
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Architecture

This project follows Clean Architecture principles with:
- **Presentation Layer**: UI components and state management
- **Domain Layer**: Business logic and entities
- **Data Layer**: API calls and local storage

## Dependencies

- Flutter SDK
- HTTP for API communication
- Shared Preferences for local storage
- Image picker for photo uploads
- Provider for state management

## API Integration

The app integrates with a REST API for:
- User authentication
- Profile management
- Campaign creation and tracking
- Analytics and reporting

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
