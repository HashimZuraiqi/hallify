import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Service for uploading images to Cloudinary
/// Free tier: 25GB storage, 25GB bandwidth/month
class CloudinaryService {
  // Your Cloudinary credentials
  static const String _cloudName = 'dqerxkqrp';
  static const String _apiKey = '235122485665848';
  static const String _apiSecret = 'c4KI4dsYP7xtNGx4OoWqrlxjuNY';
  
  // Upload presets (create one in Cloudinary Dashboard → Settings → Upload → Add upload preset)
  static const String _uploadPreset = 'hallify_unsigned'; // We'll create this
  
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
      request.fields['timestamp'] = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      
      // Generate signature for authenticated upload
      final timestamp = request.fields['timestamp']!;
      final paramsToSign = 'timestamp=$timestamp$_apiSecret';
      final signature = _generateSha1(paramsToSign);
      request.fields['signature'] = signature;
      
      // Optional: folder for organization
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      
      // Optional: custom public ID
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }
      
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
    
    for (final file in imageFiles) {
      final url = await uploadHallImage(imageFile: file, hallId: hallId);
      urls.add(url);
    }
    
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
    
    // SHA1 implementation
    final sha1 = _Sha1();
    sha1.update(bytes);
    final digest = sha1.digest();
    
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// Simple SHA1 implementation for Cloudinary signature
class _Sha1 {
  final List<int> _buffer = [];
  final List<int> _h = [
    0x67452301,
    0xEFCDAB89,
    0x98BADCFE,
    0x10325476,
    0xC3D2E1F0,
  ];
  int _length = 0;

  void update(List<int> data) {
    _buffer.addAll(data);
    _length += data.length;
  }

  List<int> digest() {
    // Padding
    final bitLength = _length * 8;
    _buffer.add(0x80);
    while ((_buffer.length % 64) != 56) {
      _buffer.add(0);
    }
    
    // Append length
    for (int i = 7; i >= 0; i--) {
      _buffer.add((bitLength >> (i * 8)) & 0xFF);
    }

    // Process blocks
    for (int i = 0; i < _buffer.length; i += 64) {
      _processBlock(_buffer.sublist(i, i + 64));
    }

    // Convert to bytes
    final result = <int>[];
    for (final h in _h) {
      result.add((h >> 24) & 0xFF);
      result.add((h >> 16) & 0xFF);
      result.add((h >> 8) & 0xFF);
      result.add(h & 0xFF);
    }
    return result;
  }

  void _processBlock(List<int> block) {
    final w = List<int>.filled(80, 0);
    
    for (int i = 0; i < 16; i++) {
      w[i] = (block[i * 4] << 24) |
             (block[i * 4 + 1] << 16) |
             (block[i * 4 + 2] << 8) |
             block[i * 4 + 3];
    }
    
    for (int i = 16; i < 80; i++) {
      w[i] = _rotateLeft(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
    }

    var a = _h[0], b = _h[1], c = _h[2], d = _h[3], e = _h[4];

    for (int i = 0; i < 80; i++) {
      int f, k;
      if (i < 20) {
        f = (b & c) | ((~b) & d);
        k = 0x5A827999;
      } else if (i < 40) {
        f = b ^ c ^ d;
        k = 0x6ED9EBA1;
      } else if (i < 60) {
        f = (b & c) | (b & d) | (c & d);
        k = 0x8F1BBCDC;
      } else {
        f = b ^ c ^ d;
        k = 0xCA62C1D6;
      }

      final temp = (_rotateLeft(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
      e = d;
      d = c;
      c = _rotateLeft(b, 30);
      b = a;
      a = temp;
    }

    _h[0] = (_h[0] + a) & 0xFFFFFFFF;
    _h[1] = (_h[1] + b) & 0xFFFFFFFF;
    _h[2] = (_h[2] + c) & 0xFFFFFFFF;
    _h[3] = (_h[3] + d) & 0xFFFFFFFF;
    _h[4] = (_h[4] + e) & 0xFFFFFFFF;
  }

  int _rotateLeft(int x, int n) {
    return ((x << n) | (x >> (32 - n))) & 0xFFFFFFFF;
  }
}
