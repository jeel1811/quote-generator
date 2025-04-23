# Quote App

A Flutter-based quote generation app with MongoDB user authentication, quote browsing, favorites, and sharing capabilities.

## Features

- **User Authentication**: Secure login/registration with Firebase Authentication and MongoDB backend.
- **Daily Quote**: Get a new inspirational quote each day.
- **Category-based Browsing**: Browse quotes by categories like Motivation, Love, Success, etc.
- **Favorites**: Save and manage your favorite quotes.
- **User-generated Quotes**: Submit your own quotes for moderation.
- **Social Sharing**: Share quotes on social media platforms.
- **Dark Mode**: Toggle between light and dark themes.
- **Daily Notifications**: Receive daily quote notifications.
- **Animated UI**: Enjoy smooth, engaging animations.

## Getting Started

### Prerequisites

- Flutter (latest version)
- Firebase project
- MongoDB database

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Set up Cloud Firestore
4. Download and replace the Firebase configuration in `lib/firebase_options.dart`

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/quote_app.git
cd quote_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Update Firebase configuration
   - Replace the placeholder values in `lib/firebase_options.dart` with your Firebase project details

4. Run the app
```bash
flutter run
```

## Project Structure

- `lib/models/`: Data models (Quote, User)
- `lib/providers/`: State management with Provider
- `lib/screens/`: UI screens
- `lib/services/`: API and backend services
- `lib/widgets/`: Reusable UI components
- `lib/utils/`: Utility classes and functions

## API Integration

This app uses the [Quotable.io](https://api.quotable.io/) API for fetching quotes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Quotable.io](https://github.com/lukePeavey/quotable) for providing the free quotes API
- Flutter and Firebase teams for their amazing frameworks
- Provider package for state management
