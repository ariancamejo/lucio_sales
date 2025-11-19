import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class StorageService {
  Future<String> uploadProductImage(String userId, Uint8List imageBytes, String fileName);
  Future<void> deleteProductImage(String imageUrl);
  String getPublicUrl(String path);
}

class StorageServiceImpl implements StorageService {
  final SupabaseClient client;
  static const String bucketName = 'product-images';

  StorageServiceImpl({required this.client});

  @override
  Future<String> uploadProductImage(String userId, Uint8List imageBytes, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();
    final uniqueName = '${const Uuid().v4()}.$extension';
    final path = '$userId/$uniqueName';

    await client.storage.from(bucketName).uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(
        contentType: _getContentType(extension),
        upsert: true,
      ),
    );

    return getPublicUrl(path);
  }

  @override
  Future<void> deleteProductImage(String imageUrl) async {
    // Extract path from URL
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;

    // Find the bucket name in the path and get everything after it
    final bucketIndex = pathSegments.indexOf(bucketName);
    if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
      return; // Invalid URL, skip deletion
    }

    final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

    await client.storage.from(bucketName).remove([filePath]);
  }

  @override
  String getPublicUrl(String path) {
    return client.storage.from(bucketName).getPublicUrl(path);
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
