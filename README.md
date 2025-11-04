# Chat Application - Flutter

A professional chat application built with **Clean Architecture**, **BLoC** pattern, and **SOLID principles**.

## Architecture

This project follows **Clean Architecture** with clear separation of concerns:

```
lib/
├── core/                   # Core utilities and base classes
│   ├── constants/          # App-wide constants
│   ├── errors/             # Error handling (Failures & Exceptions)
│   ├── theme/              # Theme configuration
│   └── di/                 # Dependency injection setup
│
├── features/               # Feature modules
│   ├── auth/               # Authentication feature
│   │   ├── data/           # Data layer
│   │   │   ├── datasources/    # Remote data sources (Firebase)
│   │   │   ├── models/         # Data models
│   │   │   └── repositories/   # Repository implementations
│   │   ├── domain/         # Domain layer
│   │   │   ├── entities/       # Business entities
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Business logic use cases
│   │   └── presentation/   # Presentation layer
│   │       ├── bloc/           # BLoC state management
│   │       ├── pages/          # UI screens
│   │       └── widgets/        # Reusable widgets
│   │
│   └── chat/               # Chat feature 
│       ├── data/
│       ├── domain/
│       └── presentation/
```

## Features

### Authentication
- Email & Password authentication via **Firebase Auth**
- Form validation with error handling
- Secure session management
- Auto-login on app restart
- Sign out functionality

### Real-time Chat
- **Firebase Real Time Database** connection using Firabase
- Real-time message delivery
- Message status indicators (Sending, Sent, Delivered, Failed)
- Typing indicators
- Optimistic UI updates
- Message bubbles with timestamps
- Empty state handling
- Auto-scroll to latest message

### State Management
- **BLoC pattern** with clear event/state separation
- Immutable state using Equatable
- Stream-based reactive programming
- Error handling in BLoC layer

### Clean Code Practices
- **SOLID principles** implementation
- **Dependency Injection** with GetIt
- Repository pattern for data abstraction
- Use case pattern for business logic
- Clear separation of concerns
- Modular and testable code

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
```bash
git clone 
cd chat_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**

Create a Firebase project and add your app:

- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project
- Add an Android/iOS app
- Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
- Place them in the respective directories:
    - Android: `android/app/google-services.json`
    - iOS: `ios/Runner/GoogleService-Info.plist`

4. **Enable Firebase Authentication**
- In Firebase Console, go to Authentication
- Enable Email/Password sign-in method

5. **Run the app**
```bash
flutter run