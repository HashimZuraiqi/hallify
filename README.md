# 🏛️ Hallify - Wedding & Conference Hall Booking Platform

<p align="center">
  <img src="assets/images/logo.png" alt="Hallify Logo" width="200"/>
</p>

**Hallify** is a comprehensive Flutter mobile application that connects customers looking to book event venues with hall organizers. Whether you're planning a wedding, corporate conference, or any special event, Hallify makes it easy to discover, book, and manage beautiful event halls across multiple cities.

---

## ✨ Key Features

### 🎯 For Customers
- **🔍 Smart Hall Discovery**: Search and filter halls by city, type, capacity, and price range
- **📸 Hall Showcase**: View high-quality images, location on interactive maps, available features, and pricing details
- **📅 Easy Scheduling**: Request visits with intuitive calendar-based date selection and available time slot picking
- **📋 Request Tracking**: Monitor all visit requests with real-time status updates (pending, approved, rejected, completed)
- **💬 Direct Messaging**: Chat with hall organizers to ask questions and negotiate details
- **👤 Profile Management**: Manage personal information and profile picture
- **⭐ Ratings & Reviews**: View ratings and feedback from other customers

### 🏢 For Organizers
- **📊 Organizer Dashboard**: Get an overview of all your halls, pending requests, and key metrics
- **🏛️ Hall Management**: Create, update, and manage multiple halls with detailed information and images
- **📝 Visit Request Management**: Review, approve, reject, or mark visits as completed
- **🕐 Smart Time Slot Management**: Automatic conflict detection prevents double-booking
- **💬 Customer Communication**: Respond to customer inquiries via in-app messaging
- **⚙️ Profile Settings**: Customize your organizer profile and business information
- **📊 Analytics**: Track booking trends and performance metrics

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter 3.0+** | Cross-platform mobile development |
| **Firebase** | Backend services |
| **Provider** | State management |
| **Google Maps** | Location services & mapping |
| **Firestore** | Real-time database |
| **Firebase Auth** | User authentication |
| **Firebase Storage** | Image & file storage |
| **Firebase Cloud Messaging** | Push notifications |
| **Material Design 3** | Modern UI components |

### Key Dependencies

```yaml
# State Management & Provider
provider: ^6.1.1

# Firebase Services
firebase_core: ^3.8.1
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.0
firebase_storage: ^12.4.0
firebase_messaging: ^15.2.1
firebase_analytics: ^11.5.0

# Maps & Location
google_maps_flutter: ^2.5.3
geolocator: ^10.1.0
geocoding: ^2.1.1

# Image Handling
image_picker: ^1.0.7
cached_network_image: ^3.3.1

# UI Components
table_calendar: ^3.0.9
flutter_rating_bar: ^4.0.1
flutter_spinkit: ^5.2.0

# Utilities
shared_preferences: ^2.2.2
connectivity_plus: ^5.0.2
uuid: ^4.3.3
```

---

## 📁 Project Structure

```
hallify/
├── lib/
│   ├── config/
│   │   ├── firebase_options.dart      # Firebase configuration
│   │   └── theme.dart                 # App theming and styling
│   │
│   ├── models/
│   │   ├── user_model.dart            # User data structure
│   │   ├── hall_model.dart            # Hall information model
│   │   ├── visit_request_model.dart   # Visit request tracking
│   │   └── message_model.dart         # Chat message structure
│   │
│   ├── services/
│   │   ├── auth_service.dart          # Firebase Authentication
│   │   ├── firestore_service.dart     # Database operations
│   │   ├── storage_service.dart       # File storage management
│   │   ├── notification_service.dart  # Push notifications
│   │   └── location_service.dart      # GPS & geocoding
│   │
│   ├── providers/
│   │   ├── auth_provider.dart         # Auth state management
│   │   ├── hall_provider.dart         # Hall data state
│   │   ├── visit_provider.dart        # Visit requests state
│   │   └── chat_provider.dart         # Messaging state
│   │
│   ├── utils/
│   │   ├── validators.dart            # Form validation logic
│   │   ├── constants.dart             # App-wide constants
│   │   └── helpers.dart               # Utility functions
│   │
│   ├── widgets/
│   │   ├── custom_button.dart         # Reusable button components
│   │   ├── custom_text_field.dart     # Input field widgets
│   │   ├── hall_card.dart             # Hall display cards
│   │   ├── visit_card.dart            # Visit request cards
│   │   ├── message_bubble.dart        # Chat message bubbles
│   │   ├── image_picker_widget.dart   # Image selection
│   │   ├── map_picker_widget.dart     # Location picker
│   │   └── loading_widget.dart        # Loading indicators
│   │
│   ├── screens/
│   │   ├── splash_screen.dart         # App initialization screen
│   │   │
│   │   ├── auth/
│   │   │   ├── login_screen.dart      # User login
│   │   │   ├── signup_screen.dart     # User registration
│   │   │   └── forgot_password_screen.dart
│   │   │
│   │   ├── customer/
│   │   │   ├── customer_home_screen.dart      # Main customer dashboard
│   │   │   ├── browse_halls_screen.dart       # Hall discovery
│   │   │   ├── hall_details_screen.dart       # Individual hall view
│   │   │   ├── visit_requests_screen.dart     # Request management
│   │   │   └── customer_profile_screen.dart   # Profile settings
│   │   │
│   │   ├── organizer/
│   │   │   ├── organizer_home_screen.dart     # Organizer dashboard
│   │   │   ├── my_halls_screen.dart           # Hall list management
│   │   │   ├── add_edit_hall_screen.dart      # Hall creation/editing
│   │   │   ├── organizer_visits_screen.dart   # Request management
│   │   │   └── organizer_profile_screen.dart  # Profile settings
│   │   │
│   │   └── chat/
│   │       ├── conversations_screen.dart  # Message list
│   │       └── chat_screen.dart           # Individual chat view
│   │
│   ├── assets/
│   │   ├── images/                    # App images and logos
│   │   ├── icons/                     # Custom icon assets
│   │   └── fonts/                     # Custom fonts
│   │
│   └── main.dart                      # App entry point
│
├── android/                           # Android-specific config
├── ios/                               # iOS-specific config
├── web/                               # Web platform files
├── windows/                           # Windows platform files
├── linux/                             # Linux platform files
├── macos/                             # macOS platform files
│
├── pubspec.yaml                       # Package dependencies
├── analysis_options.yaml              # Linting rules
├── firebase.json                      # Firebase configuration
└── README.md                          # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (>=3.0.0) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (Comes with Flutter)
- **Android Studio** or **Xcode** for emulator/device
- **Firebase CLI** - [Install Firebase CLI](https://firebase.google.com/docs/cli)
- **Git** for version control

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/hallify.git
cd hallify
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Firebase Setup

#### Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a new project"
3. Follow the setup wizard and create your project

#### Enable Services

In your Firebase project console:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"

2. **Cloud Firestore**
   - Create a new database
   - Start in "test mode" (for development)
   - Select a region (closest to your users)

3. **Firebase Storage**
   - Create a storage bucket
   - Keep default settings

4. **Cloud Messaging (FCM)**
   - Go to Messaging tab
   - Configure for your platform

#### Get Configuration Files

**For Android:**
1. Go to Project Settings > Your apps > Android
2. Register your app: `com.yourcompany.hallify`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

**For iOS:**
1. Go to Project Settings > Your apps > iOS
2. Register your app
3. Download `GoogleService-Info.plist`
4. Add to Xcode: `ios/Runner/GoogleService-Info.plist`

#### Update Firebase Configuration

```bash
flutterfire configure
```

This will automatically update `lib/firebase_options.dart` with your Firebase credentials.

### Step 4: Google Maps Setup

#### Get API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API

4. Create an API key (Restrict to Android/iOS apps)

#### Configure Maps

**Android** - Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
</application>
```

**iOS** - Edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 5: Run the App

```bash
# Run on default device/emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release
```

---

## 📖 How to Use the App

### 👤 User Registration & Login

1. **Sign Up as Customer or Organizer**
   - Open the app and tap "Sign Up"
   - Enter your email and password
   - Choose your role: Customer or Organizer
   - Fill in your profile information

2. **Login**
   - Enter your registered email and password
   - Tap "Login"

### 🎯 Customer Workflow

#### 1. Browse Halls
- Go to "Browse Halls" tab
- Use filters to search by:
  - City (dropdown)
  - Hall Type (wedding, conference, multi-purpose)
  - Capacity
  - Price range
- Tap a hall to view details

#### 2. View Hall Details
- See photos, description, and features
- View location on map
- Check available time slots
- Read reviews and ratings

#### 3. Schedule a Visit
- Tap "Request Visit"
- Select your preferred date from calendar
- Choose an available time slot
- Add any special notes or requirements
- Submit your request

#### 4. Manage Visit Requests
- Go to "My Visits" tab
- View requests in different statuses:
  - **Pending**: Waiting for organizer approval
  - **Approved**: Hall organizer confirmed your visit
  - **Completed**: Visit has been completed
- Tap on a request to see full details

#### 5. Chat with Organizers
- Go to "Messages" tab
- Tap on a conversation or start a new one
- Send questions or arrange details
- Receive instant notifications

### 🏢 Organizer Workflow

#### 1. Create a Hall
- Go to "My Halls" tab
- Tap "Add Hall" button
- Fill in hall details:
  - Name and description
  - Hall type (wedding/conference)
  - Capacity and pricing
  - Location (optional - can be set later)
  
#### 2. Add Hall Images
- Tap "Add Images"
- Select photos from gallery or camera
- Add at least one image

#### 3. Set Features & Amenities
- Select available features (WiFi, parking, catering, etc.)
- Add location on map (optional)
- Save the hall

#### 4. Manage Visit Requests
- Go to "Visits" tab
- Review pending visit requests
- **Approve**: Accept the visit request
- **Reject**: Decline with optional reason
- **Complete**: Mark visit as finished

#### 5. Communicate with Customers
- Go to "Messages" tab
- Respond to customer inquiries
- Answer questions about your hall
- Discuss special arrangements

---

## 🔐 Security & Privacy

### Firestore Security Rules

The app uses the following security rules (configure in your Firebase console):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users - can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Halls - readable by all, writable by organizers
    match /halls/{hallId} {
      allow read: if true;
      allow create, update: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'organizer';
      allow delete: if request.auth != null && 
        resource.data.organizerId == request.auth.uid;
    }
    
    // Visit Requests - readable/writable by involved parties
    match /visitRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (resource.data.customerId == request.auth.uid || 
         resource.data.organizerId == request.auth.uid);
    }
    
    // Conversations - only participants can read/write
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### Data Privacy

- User passwords are securely hashed by Firebase
- Personal information is only shared with relevant parties
- Chat messages are stored in Firestore
- Profile images are stored in Firebase Storage

---

## 🎨 App Theming & UI

### Color Scheme

| Element | Color | Hex Code |
|---------|-------|----------|
| Primary | Deep Purple | #6366F1 |
| Secondary | Pink | #EC4899 |
| Success | Green | #10B981 |
| Warning | Orange | #F97316 |
| Error | Red | #EF4444 |
| Background | White | #FFFFFF |
| Surface | Light Gray | #F3F4F6 |
| Text Primary | Dark Gray | #1F2937 |
| Text Secondary | Medium Gray | #6B7280 |

### Design Principles

- **Material Design 3**: Modern, clean UI components
- **Responsive Layout**: Works on phones and tablets
- **Dark Mode Ready**: Full dark theme support
- **Accessibility**: Proper contrast and touch targets

---

## 📊 Database Schema

### Users Collection

```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "phone": "+1-234-567-8900",
  "role": "customer",
  "profileImageUrl": "https://...",
  "fcmToken": "push_notification_token",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z"
}
```

### Halls Collection

```json
{
  "id": "hall_123",
  "organizerId": "user_123",
  "organizerName": "Jane's Events",
  "name": "Grandeur Hall",
  "description": "Spacious wedding venue with modern amenities",
  "type": "wedding",
  "address": "123 Main Street, New York",
  "city": "New York",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "capacity": 500,
  "pricePerHour": 150.00,
  "pricePerDay": 1200.00,
  "features": ["WiFi", "Parking", "Catering", "DJ Room"],
  "imageUrls": ["https://..."],
  "rating": 4.5,
  "totalReviews": 12,
  "isAvailable": true,
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z"
}
```

### Visit Requests Collection

```json
{
  "id": "visit_123",
  "hallId": "hall_123",
  "hallName": "Grandeur Hall",
  "hallImageUrl": "https://...",
  "customerId": "user_456",
  "customerName": "John Doe",
  "customerEmail": "john@example.com",
  "customerPhone": "+1-234-567-8900",
  "organizerId": "user_123",
  "organizerName": "Jane's Events",
  "visitDate": "2024-02-15T00:00:00Z",
  "visitTime": "3:00 PM - 4:00 PM",
  "message": "Interested in booking for wedding",
  "status": "pending",
  "rejectionReason": null,
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-01T10:00:00Z"
}
```

### Conversations Collection

```json
{
  "id": "conv_123",
  "participants": ["user_123", "user_456"],
  "participantNames": {
    "user_123": "Jane's Events",
    "user_456": "John Doe"
  },
  "lastMessage": "Thanks for your interest!",
  "lastSenderId": "user_123",
  "lastMessageTime": "2024-01-01T15:30:00Z",
  "unreadCount": {
    "user_123": 0,
    "user_456": 1
  },
  "hallId": "hall_123",
  "hallName": "Grandeur Hall",
  "createdAt": "2024-01-01T10:00:00Z"
}
```

---

## 🐛 Troubleshooting

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **Firebase initialization error** | Ensure `google-services.json` is in `android/app/` and configuration is correct |
| **Maps not showing** | Verify Google Maps API key is correct and APIs are enabled |
| **Images not loading** | Check Firebase Storage bucket permissions and image URLs |
| **Messages not appearing** | Ensure Firestore security rules are configured correctly |
| **App crashes on startup** | Run `flutter clean` then `flutter pub get` |
| **Location permission denied** | Grant location permission in app settings |

### Getting Help

If you encounter issues:

1. Check the [Flutter documentation](https://flutter.dev/docs)
2. Review [Firebase setup guide](https://firebase.google.com/docs/flutter/setup)
3. Check app logs: `flutter logs`
4. Open an issue on GitHub with details

---

## 🚀 Deployment

### Android Build

```bash
# Build APK for testing
flutter build apk --release

# Build App Bundle for Google Play
flutter build appbundle --release
```

### iOS Build

```bash
# Build IPA for testing
flutter build ios --release

# Archive and export
cd ios
xcode-build-settings.json
```

---

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/hallify.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/AmazingFeature
   ```

3. **Commit your changes**
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```

4. **Push to the branch**
   ```bash
   git push origin feature/AmazingFeature
   ```

5. **Open a Pull Request**

### Code Guidelines

- Follow Flutter best practices
- Use meaningful variable names
- Add comments for complex logic
- Test your changes before submitting
- Keep commits atomic and descriptive

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team & Support

- **Developer**: Your Team
- **Project**: Hallify - Wedding & Conference Hall Booking Platform
- **Support Email**: support@hallify.com

---

## 🔄 Future Roadmap

- [ ] Payment integration (Stripe, PayPal)
- [ ] Advanced analytics dashboard
- [ ] Reviews and rating system
- [ ] Email notifications
- [ ] SMS notifications
- [ ] Wishlist functionality
- [ ] Video hall tours
- [ ] 3D virtual tours
- [ ] Price negotiation feature
- [ ] Event planning tools

---

<p align="center">
  <strong>Made with ❤️ using Flutter</strong>
  <br/>
  <a href="https://github.com/yourusername/hallify">GitHub</a> • 
  <a href="https://twitter.com/hallifyapp">Twitter</a> • 
  <a href="https://hallify.com">Website</a>
</p>
