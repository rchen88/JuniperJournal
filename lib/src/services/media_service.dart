import 'package:image_picker/image_picker.dart';
import '../backend/storage/storage_service.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = StorageService();

  /// Handles picking and uploading in one flow
  Future<String?> pickAndUploadImage(
    ImageSource source, {
    String folder = 'journal-log',
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Upload to Supabase Storage
      return await _storage.uploadImage(
        image,
        bucketName: 'images',
        folder: folder,
      );
    } catch (e) {
      print('MediaService Error: $e');
      return null;
    }
  }
}