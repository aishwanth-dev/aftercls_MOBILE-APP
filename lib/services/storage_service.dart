import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'insforge_client.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static StorageService get instance => _instance;

  final InsforgeClient _client = InsforgeClient.instance;

  // Upload profile image
  Future<String?> uploadProfileImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await _client.uploadFile(
        bucket: 'profile-images',
        fileName: fileName,
        bytes: imageBytes,
      );

      if (result != null) {
        // According to API reference, response contains url field
        return result['url'] as String?;
      }
      return null;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload post image
  Future<String?> uploadPostImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    try {
      final fileName =
          'post_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await _client.uploadFile(
        bucket: 'post-images',
        fileName: fileName,
        bytes: imageBytes,
      );

      if (result != null) {
        // According to API reference, response contains url field
        return result['url'] as String?;
      }
      return null;
    } catch (e) {
      print('Error uploading post image: $e');
      return null;
    }
  }

  // Upload message image
  Future<String?> uploadMessageImage({
    required Uint8List imageBytes,
    required String userId,
    required String matchId,
  }) async {
    try {
      final fileName =
          'message_${matchId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await _client.uploadFile(
        bucket: 'message-images',
        fileName: fileName,
        bytes: imageBytes,
      );

      if (result != null) {
        // According to API reference, response contains url field
        return result['url'] as String?;
      }
      return null;
    } catch (e) {
      print('Error uploading message image: $e');
      return null;
    }
  }

  // Get file URL
  Future<String?> getFileUrl({
    required String bucket,
    required String fileName,
  }) async {
    try {
      return await _client.getFileUrl(
        bucket: bucket,
        fileName: fileName,
      );
    } catch (e) {
      print('Error getting file URL: $e');
      return null;
    }
  }

  // Delete file (placeholder - would need delete endpoint)
  Future<bool> deleteFile({
    required String bucket,
    required String fileName,
  }) async {
    try {
      // This would require a delete endpoint in the storage API
      // For now, just return true as a placeholder
      print('Deleting file: $bucket/$fileName');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get file info (placeholder - would need info endpoint)
  Future<Map<String, dynamic>?> getFileInfo({
    required String bucket,
    required String fileName,
  }) async {
    try {
      // This would require an info endpoint in the storage API
      // For now, just return basic info
      return {
        'bucket': bucket,
        'fileName': fileName,
        'url': await getFileUrl(bucket: bucket, fileName: fileName),
      };
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }

  // List files in bucket (placeholder - would need list endpoint)
  Future<List<String>> listFiles({
    required String bucket,
    String? prefix,
  }) async {
    try {
      // This would require a list endpoint in the storage API
      // For now, return empty list
      print('Listing files in bucket: $bucket with prefix: $prefix');
      return [];
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  // Get storage usage (placeholder - would need usage endpoint)
  Future<Map<String, dynamic>?> getStorageUsage() async {
    try {
      // This would require a usage endpoint in the storage API
      // For now, return placeholder data
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'buckets': {
          'profile-images': {'files': 0, 'size': 0},
          'post-images': {'files': 0, 'size': 0},
          'message-images': {'files': 0, 'size': 0},
        },
      };
    } catch (e) {
      print('Error getting storage usage: $e');
      return null;
    }
  }

  // Upload user profile image (alias for uploadProfileImage)
  Future<String?> uploadUserProfileImage({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    return await uploadProfileImage(
      imageBytes: imageBytes,
      userId: userId,
    );
  }
}
