import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service for handling Base64 image encoding/decoding for Firestore storage
/// This replaces Firebase Storage to keep the app completely free
class Base64ImageService {
  static const int maxImageSize = 800; // Max width/height
  static const int jpegQuality = 70; // Compression quality
  static const int maxImages = 5; // Max images per hall (Firestore limit)
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// Compress and convert image file to Base64 string
  Future<String?> encodeImageToBase64(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        throw Exception('Image file too large. Maximum size is 5MB.');
      }

      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      if (image.width > maxImageSize || image.height > maxImageSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxImageSize : null,
          height: image.height > image.width ? maxImageSize : null,
        );
      }

      // Compress as JPEG
      final compressedBytes = img.encodeJpg(image, quality: jpegQuality);

      // Convert to Base64
      final base64String = base64Encode(compressedBytes);

      // Check final size (Firestore has 1MB document limit)
      final estimatedSize = base64String.length;
      if (estimatedSize > 900000) { // ~900KB to be safe
        throw Exception('Compressed image still too large for Firestore');
      }

      print('Image compressed: ${fileSize} bytes → ${compressedBytes.length} bytes → ${estimatedSize} chars');
      
      return base64String;
    } catch (e) {
      print('Error encoding image: $e');
      return null;
    }
  }

  /// Encode multiple images to Base64
  Future<List<String>> encodeImagesToBase64(List<File> imageFiles) async {
    final List<String> base64Images = [];

    // Limit to max images
    final filesToProcess = imageFiles.take(maxImages).toList();
    
    for (int i = 0; i < filesToProcess.length; i++) {
      print('Processing image ${i + 1}/${filesToProcess.length}...');
      final base64 = await encodeImageToBase64(filesToProcess[i]);
      if (base64 != null) {
        base64Images.add(base64);
      } else {
        print('Warning: Failed to encode image ${i + 1}');
      }
    }

    return base64Images;
  }

  /// Decode Base64 string to image bytes
  Uint8List? decodeBase64ToBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decoding Base64: $e');
      return null;
    }
  }

  /// Get estimated size of Base64 string in KB
  double getBase64SizeKB(String base64String) {
    return base64String.length / 1024;
  }

  /// Get estimated total size of multiple Base64 strings in KB
  double getTotalBase64SizeKB(List<String> base64Strings) {
    return base64Strings.fold(0.0, (sum, str) => sum + getBase64SizeKB(str));
  }

  /// Validate if Base64 string is valid image data
  bool isValidBase64Image(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      final image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }
}
