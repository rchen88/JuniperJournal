import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/supabase_database.dart';

/// Service for handling file uploads to Supabase Storage
class StorageService {
  final _client = SupabaseDatabase.instance.client;

  /// The name of the storage bucket for learning module images
  static const String bucketName = 'learning-module-images';

  /// Uploads an image file to Supabase Storage and returns the public URL
  ///
  /// [imageFile] - The image file picked by the user
  /// [folder] - Optional folder path within the bucket (e.g., 'concept-exploration')
  ///
  /// Returns the public URL of the uploaded image, or null if upload fails
  Future<String?> uploadImage(XFile imageFile, {String folder = ''}) async {
    try {
      // Generate a unique filename using timestamp and original filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.name.split('.').last;
      final fileName = '${timestamp}_${imageFile.name}';

      // Construct the full path in the bucket
      final filePath = folder.isEmpty ? fileName : '$folder/$fileName';

      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      // Get the public URL
      final publicUrl = _client.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Deletes an image from Supabase Storage
  ///
  /// [imageUrl] - The public URL of the image to delete
  ///
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract the file path from the public URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and file path in the URL
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1) {
        debugPrint('Invalid image URL - bucket not found');
        return false;
      }

      // Get the file path after the bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete from Supabase Storage
      await _client.storage
          .from(bucketName)
          .remove([filePath]);

      debugPrint('Image deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Gets the MIME type for a file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
