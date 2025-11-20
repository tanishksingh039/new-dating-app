import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../config/r2_config.dart';

class R2StorageService {
  static Minio? _minio;
  
  // Configuration from r2_config.dart
  static String get _endpoint => R2Config.endpoint;
  static String get _accessKey => R2Config.accessKeyId;
  static String get _secretKey => R2Config.secretAccessKey;
  static String get _bucketName => R2Config.bucketName;
  static String get _region => R2Config.region;
  static String get _publicUrl => R2Config.publicUrl;
  
  /// Initialize Minio client for R2
  static Minio _getClient() {
    _minio ??= Minio(
      endPoint: _endpoint,
      accessKey: _accessKey,
      secretKey: _secretKey,
      useSSL: true,
      region: _region,
    );
    return _minio!;
  }
  
  /// Compress image to reduce size (500KB → 100KB)
  /// This saves bandwidth and improves app performance
  static Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75, // 75 = good balance between quality and size
        minWidth: 1080, // Max width for dating app photos
        minHeight: 1920, // Max height
        format: CompressFormat.jpeg,
      );
      
      if (result == null) {
        print('⚠️ Compression failed, using original file');
        return file;
      }
      
      final originalSize = await file.length();
      final compressedSize = await File(result.path).length();
      final reduction = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      
      print('✅ Image compressed: ${(originalSize / 1024).toStringAsFixed(0)}KB → ${(compressedSize / 1024).toStringAsFixed(0)}KB ($reduction% reduction)');
      
      return File(result.path);
    } catch (e) {
      print('⚠️ Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }
  
  /// Upload image to Cloudflare R2
  /// Returns the public URL of the uploaded image
  static Future<String> uploadImage({
    required File imageFile,
    required String folder, // e.g., 'profiles', 'reports', 'voice_notes'
    required String userId,
  }) async {
    try {
      print('📤 Starting upload to R2...');
      print('📋 Config: ${R2Config.getConfigStatus()}');
      
      // Validate configuration
      if (!R2Config.isConfigured()) {
        throw Exception('R2 is not configured. Please check lib/config/r2_config.dart');
      }
      
      // Step 1: Compress image
      final compressedFile = await _compressImage(imageFile);
      
      // Step 2: Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '$folder/$userId/$timestamp$extension';
      
      // Step 3: Upload to R2
      print('🔗 Connecting to R2...');
      print('📍 Endpoint: $_endpoint');
      print('📦 Bucket: $_bucketName');
      print('📄 File: $fileName');
      
      final client = _getClient();
      final fileBytes = await compressedFile.readAsBytes();
      final stream = Stream<Uint8List>.value(Uint8List.fromList(fileBytes));
      final fileSize = fileBytes.length;
      
      print('📤 Uploading ${(fileSize / 1024).toStringAsFixed(0)}KB...');
      
      await client.putObject(
        _bucketName,
        fileName,
        stream,
        size: fileSize,
        onProgress: (bytes) {
          final progress = (bytes / fileSize * 100).toStringAsFixed(1);
          print('📊 Upload progress: $progress%');
        },
      );
      
      // Step 4: Return public URL
      final publicUrl = '$_publicUrl/$fileName';
      
      print('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error uploading image to R2: $e');
      rethrow;
    }
  }
  
  /// Upload multiple images (for reports, profile galleries, etc.)
  static Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    required String userId,
  }) async {
    final List<String> urls = [];
    
    print('📤 Uploading ${imageFiles.length} images...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        print('Uploading image ${i + 1}/${imageFiles.length}...');
        final url = await uploadImage(
          imageFile: imageFiles[i],
          folder: folder,
          userId: userId,
        );
        urls.add(url);
      } catch (e) {
        print('❌ Failed to upload image ${i + 1}: $e');
        // Continue with other images
      }
    }
    
    print('✅ Uploaded ${urls.length}/${imageFiles.length} images successfully');
    return urls;
  }
  
  /// Delete image from R2
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.path.substring(1); // Remove leading '/'
      
      final client = _getClient();
      await client.removeObject(_bucketName, fileName);
      
      print('✅ Image deleted successfully: $fileName');
    } catch (e) {
      print('❌ Error deleting image from R2: $e');
      rethrow;
    }
  }
  
  /// Delete multiple images
  static Future<void> deleteMultipleImages(List<String> imageUrls) async {
    print('🗑️ Deleting ${imageUrls.length} images...');
    
    int deleted = 0;
    for (final url in imageUrls) {
      try {
        await deleteImage(url);
        deleted++;
      } catch (e) {
        print('❌ Failed to delete image: $e');
        // Continue with other images
      }
    }
    
    print('✅ Deleted $deleted/${imageUrls.length} images');
  }
  
  /// Get presigned URL for temporary access (optional, for private images)
  static Future<String> getPresignedUrl(String fileName, {int expirySeconds = 3600}) async {
    try {
      final client = _getClient();
      final url = await client.presignedGetObject(
        _bucketName,
        fileName,
        expires: expirySeconds,
      );
      return url;
    } catch (e) {
      print('❌ Error getting presigned URL: $e');
      rethrow;
    }
  }
  
  /// Check if bucket exists (for testing/debugging)
  static Future<bool> checkBucketExists() async {
    try {
      final client = _getClient();
      final exists = await client.bucketExists(_bucketName);
      print(exists ? '✅ Bucket exists' : '❌ Bucket not found');
      return exists;
    } catch (e) {
      print('❌ Error checking bucket: $e');
      return false;
    }
  }
  
  /// Test upload (for debugging)
  static Future<bool> testUpload() async {
    try {
      print('🧪 Testing R2 connection...');
      
      // Check if bucket exists
      final exists = await checkBucketExists();
      if (!exists) {
        print('❌ Bucket does not exist. Please create it in Cloudflare dashboard.');
        return false;
      }
      
      print('✅ R2 connection successful!');
      return true;
    } catch (e) {
      print('❌ R2 connection failed: $e');
      return false;
    }
  }
}
