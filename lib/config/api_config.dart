/// API Configuration
/// Load sensitive configuration from environment variables
class ApiConfig {
  // Cloudinary Configuration
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '', // Empty default for security
  );
  
  static const String cloudinaryApiKey = String.fromEnvironment(
    'CLOUDINARY_API_KEY',
    defaultValue: '',
  );
  
  static const String cloudinaryApiSecret = String.fromEnvironment(
    'CLOUDINARY_API_SECRET',
    defaultValue: '',
  );
  
  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'hallify_unsigned',
  );

  // Google Maps API Keys
  static const String googleMapsApiKeyAndroid = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_ANDROID',
    defaultValue: '',
  );

  static const String googleMapsApiKeyIos = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY_IOS',
    defaultValue: '',
  );

  /// Check if all required API keys are configured
  static bool get isConfigured {
    return cloudinaryCloudName.isNotEmpty &&
           cloudinaryApiKey.isNotEmpty &&
           cloudinaryApiSecret.isNotEmpty;
  }

  /// Get configuration status message
  static String get configurationStatus {
    if (isConfigured) {
      return 'All API keys configured';
    }
    
    final missing = <String>[];
    if (cloudinaryCloudName.isEmpty) missing.add('CLOUDINARY_CLOUD_NAME');
    if (cloudinaryApiKey.isEmpty) missing.add('CLOUDINARY_API_KEY');
    if (cloudinaryApiSecret.isEmpty) missing.add('CLOUDINARY_API_SECRET');
    
    return 'Missing: ${missing.join(', ')}';
  }
}
