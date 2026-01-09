/// Application constants
library;

class AppConstants {
  // App Info
  static const String appName = 'Hallify';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Find Your Perfect Hall';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String hallsCollection = 'halls';
  static const String visitRequestsCollection = 'visitRequests';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';

  // Storage Paths
  static const String hallsStoragePath = 'halls';
  static const String profilesStoragePath = 'profiles';
  static const String chatsStoragePath = 'chats';

  // Time Slots
  static const List<String> timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  // Hall Features
  static const List<String> hallFeatures = [
    'Air Conditioning',
    'WiFi',
    'Parking',
    'Catering',
    'Sound System',
    'Projector',
    'Stage',
    'Dance Floor',
    'Outdoor Area',
    'Wheelchair Accessible',
    'Security',
    'Valet Parking',
    'Bridal Suite',
    'Kitchen',
    'Generator Backup',
    'Restrooms',
  ];

  // Governorates/Cities of Jordan
  static const List<String> cities = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Mafraq',
    'Jerash',
    'Madaba',
    'Ajloun',
    'Karak',
    'Tafilah',
    'Ma\'an',
  ];

  // Capacity Options
  static const List<int> capacityOptions = [
    50,
    100,
    200,
    300,
    500,
    750,
    1000,
    1500,
    2000,
    5000,
  ];

  // Price Range
  static const double minPrice = 0;
  static const double maxPrice = 10000;

  // Image Settings
  static const int maxImagesPerHall = 10;
  static const int maxImageSizeInMB = 5;
  static const double imageQuality = 0.8;

  // Pagination
  static const int itemsPerPage = 10;

  // Map Settings - Amman, Jordan coordinates
  static const double defaultLatitude = 31.9454;
  static const double defaultLongitude = 35.9284;
  static const double defaultZoom = 12.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy - hh:mm a';

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String sessionExpired = 'Your session has expired. Please login again.';

  // Success Messages
  static const String hallCreated = 'Hall created successfully!';
  static const String hallUpdated = 'Hall updated successfully!';
  static const String hallDeleted = 'Hall deleted successfully!';
  static const String visitRequested = 'Visit request submitted successfully!';
  static const String visitApproved = 'Visit request approved!';
  static const String visitRejected = 'Visit request rejected.';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String passwordChanged = 'Password changed successfully!';
  static const String passwordResetSent = 'Password reset email sent!';
}
