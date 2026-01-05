import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload a single image for a hall
  Future<String> uploadHallImage({
    required File imageFile,
    required String hallId,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('halls/$hallId/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images for a hall
  Future<List<String>> uploadHallImages({
    required List<File> imageFiles,
    required String hallId,
  }) async {
    try {
      final List<String> downloadUrls = [];

      for (final imageFile in imageFiles) {
        final String url = await uploadHallImage(
          imageFile: imageFile,
          hallId: hallId,
        );
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  /// Upload user profile image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final Reference ref = _storage.ref().child('profiles/$userId/profile.jpg');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Upload chat image
  Future<String> uploadChatImage({
    required File imageFile,
    required String conversationId,
  }) async {
    try {
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('chats/$conversationId/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload chat image: $e');
    }
  }

  /// Delete a single image
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail if image doesn't exist
    }
  }

  /// Delete all images for a hall
  Future<void> deleteHallImages(String hallId) async {
    try {
      final Reference ref = _storage.ref().child('halls/$hallId');
      final ListResult result = await ref.listAll();

      for (final Reference item in result.items) {
        await item.delete();
      }
    } catch (e) {
      // Silently fail if folder doesn't exist
    }
  }

  /// Delete user profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      final Reference ref = _storage.ref().child('profiles/$userId/profile.jpg');
      await ref.delete();
    } catch (e) {
      // Silently fail if image doesn't exist
    }
  }

  /// Get download URL from storage path
  Future<String> getDownloadUrl(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}
