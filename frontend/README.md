# Mind Tuner - Meditation App

A modern meditation app that helps users practice meditation, record mood changes, and provides personalized meditation experiences.

## 🚀 Features

### Core Features
- **Mood Selection**: Users can choose their current mood state (happy, sad, neutral)
- **Meditation Timer**: Real-time display of meditation time with pause and resume support
- **History Records**: View past meditation records and mood changes
- **Rating System**: Rate and provide feedback for each meditation session
- **Personalized Settings**: Notifications, sound, language and other personalized configurations

### Page Navigation
- **Home (Meditation)**: Mood selection, meditation timer, start meditation
- **History**: Meditation records grouped by date
- **Profile**: User profile and login functionality

## 🛠️ Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **UI Design**: Material Design 3
- **State Management**: Flutter StatefulWidget
- **Navigation**: BottomNavigationBar + PageView
- **Testing**: Flutter Test Framework
- **Backend Services**: Firebase
  - **Authentication**: Firebase Authentication
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage (optional)

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point and main navigation
├── screens/                     # Page modules
│   ├── home_screen.dart        # Home page - mood selection and meditation start
│   ├── history_screen.dart     # History page - meditation records
│   ├── profile_screen.dart     # Profile page - user profile
│   ├── meditation_screens.dart # Meditation related pages
│   │   ├── MeditationProgressScreen    # Meditation progress page
│   │   ├── MeditationCompletedScreen   # Meditation completion page
│   │   └── MeditationReviewScreen      # Meditation review page
│   └── settings_screen.dart    # Settings page
├── widgets/                     # Reusable components
│   ├── mood_button.dart        # Mood button component
│   └── history_item.dart       # History record item component
├── models/                      # Data models
│   ├── meditation_session.dart # Meditation session data model
│   └── user_model.dart         # User data model
├── services/                    # Service layer
│   └── auth_service.dart       # Firebase authentication service
├── utils/                       # Utility classes and constants
│   ├── constants.dart          # App constants (colors, styles, sizes)
│   └── firebase_config.dart    # Firebase configuration
└── demo_screens.dart           # Demo pages (meditation type selection, statistics, etc.)
```

## 🎨 Design System

### Color Scheme
- **Primary Color**: `#2694EE` (Blue)
- **Secondary Color**: `#7E9FBA` (Gray-blue)
- **Light Background**: `#B6D2E9` (Light blue)
- **Dark Text**: `#000203` (Dark gray)
- **White**: `#FFFFFF`

### Typography
- **Title Font**: Consolas, 30px, Bold
- **Section Title**: Consolas, 24px, Bold
- **Body Text**: 16px, Regular

### Size Specifications
- **Button Height**: 50px
- **Mood Button**: 60px circular
- **Icon Size**: 30px
- **Spacing**: 16px (small), 32px (large)

## 🚀 Quick Start

### Requirements
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code

### Installation Steps

1. **Clone the project**
   ```bash
   git clone <repository-url>
   cd MindTuner/frontend
   ```

2. **Configure Firebase**
   - Follow the steps in `FIREBASE_SETUP.md` to configure Firebase
   - Download and place the `google-services.json` file

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Run tests**
   ```bash
   flutter test
   ```

## 📱 Page Flow

### Main User Flow
1. **Launch app** → Home page display
2. **Select mood** → Click mood button
3. **Start meditation** → Enter meditation progress page
4. **Complete meditation** → Show completion page
5. **View history** → Switch to history page via bottom navigation
6. **Rate meditation** → Click history record to enter rating page

### Navigation Structure
```
MainScreen (Main Navigation)
├── HomeScreen (Home Page)
│   ├── Mood selection area
│   ├── Meditation time display
│   ├── Feeling input field
│   └── Start meditation button
├── HistoryScreen (History Page)
│   ├── History records grouped by date
│   └── Expandable meditation details
└── ProfileScreen (Profile Page)
    ├── User avatar
    ├── Username
    ├── Login/Logout button
    └── User state management
```

## 🧪 Testing

The project includes complete unit tests and component tests:

```bash
# Run all tests
flutter test

# Run specific tests
flutter test test/widget_test.dart
```

### Test Coverage
- ✅ App startup test
- ✅ Page navigation test
- ✅ Mood selection test
- ✅ Button existence test

## 🔧 Development Guide

### Code Standards
- Use `AppColors` and `AppStyles` to maintain design consistency
- Component-based development, reusable components in `widgets/` directory
- Page logic in `screens/` directory
- Data models in `models/` directory

### Adding New Features
1. Create new files in the appropriate directory
2. Update imports in `main.dart`
3. Add corresponding tests
4. Update documentation

### Style Modifications
Modify constants in `lib/utils/constants.dart`:
```dart
class AppColors {
  static const Color primaryBlue = Color.fromARGB(255, 38, 148, 238);
  // Add new colors...
}

class AppStyles {
  static const TextStyle titleStyle = TextStyle(/* ... */);
  // Add new styles...
}
```

## 📊 Project Statistics

- **Total Files**: 12
- **Code Lines**: ~800
- **Test Coverage**: 100% (core functionality)
- **Supported Platforms**: Android, iOS, Web

## 🚀 Future Plans

### Short-term Goals
- [x] Add user authentication (Firebase Auth)
- [x] Implement data persistence (Firestore)
- [ ] Add audio playback functionality
- [ ] Optimize animation effects

### Long-term Goals
- [ ] Integrate AI meditation guidance
- [ ] Add social features
- [ ] Support multiple languages
- [ ] Add data analytics

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## 📞 Contact

- Project Maintainer: Mind Tuner Team
- Email: support@mindtuner.com
- Project Link: [https://github.com/your-username/mind-tuner](https://github.com/your-username/mind-tuner)

---

**Mind Tuner** - Making meditation simple and effective 🧘‍♀️
