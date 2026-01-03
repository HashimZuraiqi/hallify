# Hallify - Wedding & Conference Hall Booking Platform

<p align="center">
  <img src="assets/images/logo.png" alt="Hallify Logo" width="200"/>
</p>

A comprehensive Flutter mobile application for booking wedding and conference halls with Firebase integration.

## 📱 Features

### For Customers
- **Browse Halls**: Search and filter halls by city, type, capacity, and price
- **Hall Details**: View comprehensive hall information including images, location on map, features, and pricing
- **Schedule Visits**: Request visits with calendar-based date selection and time slot picking
- **Visit Management**: Track visit requests (pending, approved, rejected, completed)
- **In-App Messaging**: Chat directly with hall organizers
- **Profile Management**: Update personal information and profile picture

### For Organizers
- **Dashboard**: Overview of halls, pending requests, and statistics
- **Hall Management**: Full CRUD operations for halls with image upload
- **Visit Requests**: Approve, reject, or mark visits as completed
- **Time Slot Management**: Automatic conflict checking for bookings
- **In-App Messaging**: Communicate with potential customers
- **Profile Management**: Manage organizer profile and settings

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.0+ with Material Design 3
- **State Management**: Provider
- **Backend Services**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging
  - Firebase Analytics
- **Maps**: Google Maps Flutter
- **Other Packages**:
  - Table Calendar for date picking
  - Cached Network Image for image caching
  - Image Picker for photo selection
  - Flutter Local Notifications
  - Geolocator for location services

## 📁 Project Structure

```
lib/
├── config/
│   ├── firebase_options.dart    # Firebase configuration
│   └── theme.dart               # App theming (colors, gradients, styles)
├── models/
│   ├── user_model.dart          # User data model
│   ├── hall_model.dart          # Hall data model
│   ├── visit_request_model.dart # Visit request model
│   └── message_model.dart       # Chat message models
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── firestore_service.dart   # Firestore CRUD operations
│   ├── storage_service.dart     # Firebase Storage operations
│   ├── notification_service.dart # FCM & local notifications
│   └── location_service.dart    # GPS & geocoding
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── hall_provider.dart       # Hall management state
│   ├── visit_provider.dart      # Visit requests state
│   └── chat_provider.dart       # Chat state
├── utils/
│   ├── validators.dart          # Form validation
│   ├── constants.dart           # App constants
│   └── helpers.dart             # Utility functions
├── widgets/
│   ├── custom_button.dart       # Custom button widgets
│   ├── custom_text_field.dart   # Custom text fields
│   ├── hall_card.dart           # Hall display cards
│   ├── visit_card.dart          # Visit request cards
│   ├── message_bubble.dart      # Chat message bubbles
│   ├── image_picker_widget.dart # Image picker
│   ├── map_picker_widget.dart   # Map location picker
│   └── loading_widget.dart      # Loading indicators
├── screens/
│   ├── splash_screen.dart       # App splash screen
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── customer/
│   │   ├── customer_home_screen.dart
│   │   ├── browse_halls_screen.dart
│   │   ├── hall_details_screen.dart
│   │   ├── visit_requests_screen.dart
│   │   └── customer_profile_screen.dart
│   ├── organizer/
│   │   ├── organizer_home_screen.dart
│   │   ├── my_halls_screen.dart
│   │   ├── add_edit_hall_screen.dart
│   │   ├── organizer_visits_screen.dart
│   │   └── organizer_profile_screen.dart
│   └── chat/
│       ├── conversations_screen.dart
│       └── chat_screen.dart
└── main.dart                    # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase project
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/hallify.git
   cd hallify
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create Cloud Firestore database
   - Enable Firebase Storage
   - Set up Firebase Cloud Messaging
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `lib/config/firebase_options.dart` with your configuration

4. **Google Maps Setup**
   - Get an API key from [Google Cloud Console](https://console.cloud.google.com)
   - Enable Maps SDK for Android and iOS
   - Add API key to:
     - Android: `android/app/src/main/AndroidManifest.xml`
     - iOS: `ios/Runner/AppDelegate.swift`

5. **Run the app**
   ```bash
   flutter run
   ```

## 📊 Firebase Database Structure

### Collections

```
users/
├── {userId}/
│   ├── id: string
│   ├── email: string
│   ├── name: string
│   ├── phone: string?
│   ├── role: 'customer' | 'organizer'
│   ├── profileImageUrl: string?
│   ├── fcmToken: string?
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

halls/
├── {hallId}/
│   ├── id: string
│   ├── organizerId: string
│   ├── name: string
│   ├── description: string
│   ├── type: 'wedding' | 'conference' | 'both'
│   ├── address: string
│   ├── city: string
│   ├── latitude: number
│   ├── longitude: number
│   ├── capacity: number
│   ├── pricePerHour: number
│   ├── features: string[]
│   ├── imageUrls: string[]
│   ├── rating: number
│   ├── reviewCount: number
│   ├── isActive: boolean
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

visitRequests/
├── {requestId}/
│   ├── id: string
│   ├── hallId: string
│   ├── hallName: string
│   ├── customerId: string
│   ├── customerName: string
│   ├── organizerId: string
│   ├── requestDate: timestamp
│   ├── timeSlot: string
│   ├── notes: string
│   ├── status: 'pending' | 'approved' | 'rejected' | 'completed' | 'cancelled'
│   ├── rejectionReason: string?
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

conversations/
├── {conversationId}/
│   ├── id: string
│   ├── participantIds: string[]
│   ├── participantNames: map<string, string>
│   ├── hallId: string?
│   ├── hallName: string?
│   ├── lastMessage: string?
│   ├── lastMessageSenderId: string
│   ├── lastMessageTime: timestamp
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp

messages/
├── {messageId}/
│   ├── id: string
│   ├── conversationId: string
│   ├── senderId: string
│   ├── senderName: string
│   ├── text: string
│   ├── imageUrl: string?
│   ├── timestamp: timestamp
│   └── isRead: boolean
```

## 🔐 Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Halls are readable by all, writable by organizers
    match /halls/{hallId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'organizer';
    }
    
    // Visit requests
    match /visitRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.customerId == request.auth.uid || 
         resource.data.organizerId == request.auth.uid);
    }
    
    // Conversations and messages
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🎨 Theming

The app uses a custom theme with:
- **Primary Color**: Deep Purple (#6366F1)
- **Secondary Color**: Pink (#EC4899)
- **Gradient**: Primary to Secondary
- **Font**: Poppins (Google Fonts)

## 📸 Screenshots

| Splash | Login | Signup |
|--------|-------|--------|
| ![Splash](screenshots/splash.png) | ![Login](screenshots/login.png) | ![Signup](screenshots/signup.png) |

| Customer Home | Hall Details | Schedule Visit |
|---------------|--------------|----------------|
| ![Home](screenshots/home.png) | ![Details](screenshots/details.png) | ![Schedule](screenshots/schedule.png) |

| Organizer Dashboard | My Halls | Visit Requests |
|---------------------|----------|----------------|
| ![Dashboard](screenshots/dashboard.png) | ![Halls](screenshots/halls.png) | ![Visits](screenshots/visits.png) |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Developer**: Your Name
- **Project**: Hallify - Wedding & Conference Hall Booking Platform

## 📞 Support

For support, email support@hallify.com or join our Slack channel.

---

<p align="center">
  Made with ❤️ using Flutter
</p>