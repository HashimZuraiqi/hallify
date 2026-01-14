import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../config/api_config.dart';

/// Service for uploading images to Cloudinary
/// Free tier: 25GB storage, 25GB bandwidth/month
/// 
/// ⚠️ SECURITY: API credentials are loaded from environment variables
/// See SECURITY.md for setup instructions
class CloudinaryService {
  // Cloudinary credentials from environment variables
  static String get _cloudName => ApiConfig.cloudinaryCloudName;
  static String get _apiKey => ApiConfig.cloudinaryApiKey;
  static String get _apiSecret => ApiConfig.cloudinaryApiSecret;
  static String get _uploadPreset => ApiConfig.cloudinaryUploadPreset;
  
  final Uuid _uuid = const Uuid();

  /// Upload a single image to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    String? folder,
    String? publicId,
  }) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', uri);
      
      // Add the image file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ));
      
      // Add upload parameters
      request.fields['api_key'] = _apiKey;
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      request.fields['timestamp'] = timestamp;
      
      // Build parameters map for signature (only non-empty optional params)
      final Map<String, String> paramsToSign = {
        'timestamp': timestamp,
      };
      
      // Add optional parameters if provided
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
        paramsToSign['folder'] = folder;
      }
      
      if (publicId != null && publicId.isNotEmpty) {
        request.fields['public_id'] = publicId;
        paramsToSign['public_id'] = publicId;
      }
      
      // Generate signature: sort params alphabetically and concatenate
      final sortedKeys = paramsToSign.keys.toList()..sort();
      final signatureString = sortedKeys
          .map((key) => '$key=${paramsToSign[key]}')
          .join('&') + _apiSecret;
      
      print('🔐 Signature string: $signatureString');
      final signature = _generateSha1(signatureString);
      request.fields['signature'] = signature;
      
      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['secure_url'] as String;
      } else {
        print('Cloudinary error: $responseBody');
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a hall image
  Future<String> uploadHallImage({
    required File imageFile,
    required String hallId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      folder: 'halls/$hallId',
      publicId: _uuid.v4(),
    );
  }

  /// Upload multiple hall images
  Future<List<String>> uploadHallImages({
    required List<File> imageFiles,
    required String hallId,
  }) async {
    final List<String> urls = [];
    
    print('☁️ Uploading ${imageFiles.length} images to Cloudinary for hall $hallId');
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      print('  📤 Uploading image ${i + 1}/${imageFiles.length}: ${file.path}');
      try {
        final url = await uploadHallImage(imageFile: file, hallId: hallId);
        urls.add(url);
        print('  ✅ Image ${i + 1} uploaded: $url');
      } catch (e) {
        print('  ❌ Failed to upload image ${i + 1}: $e');
        rethrow;
      }
    }
    
    print('✅ All images uploaded successfully!');
    return urls;
  }

  /// Upload a profile image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      folder: 'profiles',
      publicId: userId,
    );
  }

  /// Upload a chat image
  Future<String> uploadChatImage({
    required File imageFile,
    required String conversationId,
  }) async {
    return uploadImage(
      imageFile: imageFile,
      folder: 'chats/$conversationId',
      publicId: _uuid.v4(),
    );
  }

  /// Generate SHA1 hash for Cloudinary signature
  String _generateSha1(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
