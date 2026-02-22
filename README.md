# Pocket Health

A comprehensive healthcare management and community support application built with Flutter and Firebase. Pocket Health empowers users to track their health conditions, manage personal health data, and connect with others facing similar health challenges in a safe, anonymous community environment.

## Features

### 🏥 Health Tracking
- **Personal Health Profile**: Comprehensive user profiles with health conditions, metrics, and GP details
- **Condition Management**: Track multiple health conditions with severity levels and categories
- **Health Metrics**: Log and monitor vital signs, symptoms, and health entries
- **Onboarding Flow**: Guided setup process for new users

### 👥 Community Support
- **Anonymous Forums**: Safe, moderated discussion groups based on health conditions
- **Peer Support**: Connect with others facing similar health challenges
- **Thread Discussions**: Create and participate in topic-based conversations
- **Like/Dislike System**: Community feedback on helpful content
- **Content Moderation**: Professional moderation with healthcare-specific guidelines

### 🔐 Privacy & Security
- **Anonymous Participation**: SHA-256 hashed display names protect user identities
- **Access Control**: Users can only access groups related to their own conditions
- **Role-Based Permissions**: User, Moderator, and Admin roles with appropriate access levels
- **Data Encryption**: Secure storage and transmission of sensitive health information

### 👨‍⚕️ Healthcare Professional Features
- **Moderator Tools**: Content moderation and community management
- **Admin Dashboard**: User role management and system oversight
- **Audit Logging**: Complete tracking of moderation and administrative actions
- **Escalation System**: Automatic handling of critical content reports

## Architecture

### Tech Stack
- **Frontend**: Flutter (iOS/Android/Web)
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **State Management**: Provider pattern
- **UI Framework**: Material Design with custom healthcare theme

### Project Structure
```
lib/
├── models/          # Data models (UserProfile, HealthCondition, etc.)
├── providers/       # State management (Auth, User, Health, Community)
├── screens/         # UI screens and navigation
├── widgets/         # Reusable UI components
├── utils/           # Utilities and constants
└── services/        # Firebase and external service integrations
```

### Database Schema
- **Users Collection**: User profiles with roles and health conditions
- **Groups Collection**: Auto-generated from health condition categories
- **Threads Collection**: Discussion topics within groups
- **Comments Collection**: Thread replies with voting
- **Reports Collection**: Content moderation queue

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase CLI
- Android Studio / Xcode for mobile development
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/pocket-health.git
   cd pocket-health
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Initialize Firebase in the project
   firebase init
   ```

4. **Configure Firebase**
   - Create a new Firebase project
   - Enable Authentication and Firestore
   - Add your app to Firebase project
   - Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

5. **Environment Configuration**
   ```bash
   # Copy environment template
   cp .env.example .env

   # Configure your Firebase and other environment variables
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

1. **Code Generation**
   ```bash
   flutter pub run build_runner build
   ```

2. **Testing**
   ```bash
   flutter test
   ```

3. **Code Analysis**
   ```bash
   flutter analyze
   ```

## Usage

### For Users
1. **Sign Up**: Create account with email and password
2. **Complete Onboarding**: Set up health profile and conditions
3. **Access Community**: Join groups related to your health conditions
4. **Participate**: Create threads, comment, and engage with community

### For Moderators
1. **Access Dashboard**: Use moderator tools in the app
2. **Review Reports**: Handle user-reported content
3. **Moderate Content**: Approve, edit, or remove inappropriate content
4. **Community Management**: Monitor group health and engagement

### For Administrators
1. **User Management**: Assign and revoke user roles
2. **System Oversight**: Monitor platform usage and health
3. **Content Policy**: Set community guidelines and moderation rules

## Security & Privacy

### Data Protection
- All user data encrypted at rest and in transit
- Anonymous participation in community features
- Strict access controls based on user roles
- Regular security audits and updates

### Compliance
- GDPR compliant data handling
- Healthcare privacy standards
- User consent for data collection
- Right to data deletion and portability

## Contributing

We welcome contributions to Pocket Health! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style
- Follow Flutter's effective Dart guidelines
- Use the provided analysis options
- Write comprehensive documentation
- Include unit and integration tests

## Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Test Structure
- **Unit Tests**: Individual functions and classes
- **Widget Tests**: UI component testing
- **Integration Tests**: Full user flows
- **E2E Tests**: Complete application testing

## Documentation

- [Architecture Decision Records](docs/adr/) - Major technical decisions
- [API Documentation](docs/api/) - Service integrations
- [User Guide](docs/user-guide/) - Application usage
- [Moderator Guide](docs/moderator-guide/) - Content moderation

## Deployment

### Firebase Hosting (Web)
```bash
flutter build web
firebase deploy --only hosting
```

### Mobile App Stores
- **Android**: Build APK/AAB and submit to Google Play
- **iOS**: Build IPA and submit to App Store

## Support

- **Issues**: [GitHub Issues](https://github.com/your-org/pocket-health/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/pocket-health/discussions)
- **Email**: support@pockethealth.app

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for robust backend services
- Healthcare professionals for domain expertise
- Open source community for invaluable tools and libraries
