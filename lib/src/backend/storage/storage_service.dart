import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/supabase_database.dart';

/// Service for handling file uploads to Supabase Storage
class StorageService {
  final _client = SupabaseDatabase.instance.client;

  /// The name of the storage bucket for learning module images
  static const String bucketName = 'learning-module-images';

  /// Uploads an image file to Supabase Storage as WebP and returns the public URL
  ///
  /// [imageFile] - The image file picked by the user
  /// [folder] - Optional folder path within the bucket (e.g., 'concept-exploration')
  ///
  /// Returns the public URL of the uploaded image, or null if upload fails
  Future<String?> uploadImage(XFile imageFile, {String folder = ''}) async {
    try {
      // Generate a unique filename using timestamp and original filename (forced .webp)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final baseName = imageFile.name.split('.').first;
      final fileName = '${timestamp}_$baseName.webp';

      // Construct the full path in the bucket
      final filePath = folder.isEmpty ? fileName : '$folder/$fileName';

      // Read the file as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to WebP before upload
      final convertedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: 85,
      );

      // Upload to Supabase Storage
      await _client.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            convertedBytes,
            fileOptions: const FileOptions(
              contentType: 'image/webp',
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
}
