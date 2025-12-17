import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Face Recognition Service using FaceNet-like embeddings
/// This service generates 128-dimensional face embeddings and compares them
/// to determine if two faces belong to the same person
class FaceRecognitionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  
  static const int INPUT_SIZE = 112; // MobileFaceNet input size
  static const int EMBEDDING_SIZE = 192; // MobileFaceNet embedding size
  static const double SIMILARITY_THRESHOLD = 0.6; // Cosine similarity threshold
  
  /// Initialize the face recognition model
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('[FaceRecognition] 🔧 Initializing face recognition model...');
      
      // Load the MobileFaceNet model
      // Note: You'll need to add mobile_face_net.tflite to assets/models/
      _interpreter = await Interpreter.fromAsset('assets/models/mobile_face_net.tflite');
      
      print('[FaceRecognition] ✅ Model loaded successfully');
      print('[FaceRecognition] Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('[FaceRecognition] Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      
      _isInitialized = true;
    } catch (e) {
      print('[FaceRecognition] ❌ Error initializing model: $e');
      print('[FaceRecognition] ⚠️ Falling back to geometric comparison');
      _isInitialized = false;
    }
  }
  
  /// Generate face embedding from image
  Future<List<double>?> generateEmbedding(String imagePath, Face face) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isInitialized || _interpreter == null) {
        print('[FaceRecognition] ⚠️ Model not initialized, cannot generate embedding');
        return null;
      }
      
      print('[FaceRecognition] 📸 Generating embedding for: $imagePath');
      
      // Load and decode image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('[FaceRecognition] ❌ Failed to decode image');
        return null;
      }
      
      // Crop face region with padding
      final boundingBox = face.boundingBox;
      final padding = 20;
      
      final left = max(0, boundingBox.left.toInt() - padding);
      final top = max(0, boundingBox.top.toInt() - padding);
      final right = min(image.width, boundingBox.right.toInt() + padding);
      final bottom = min(image.height, boundingBox.bottom.toInt() + padding);
      
      final width = right - left;
      final height = bottom - top;
      
      print('[FaceRecognition] ✂️ Cropping face: left=$left, top=$top, width=$width, height=$height');
      
      img.Image croppedFace = img.copyCrop(
        image,
        x: left,
        y: top,
        width: width,
        height: height,
      );
      
      // Resize to model input size
      img.Image resizedFace = img.copyResize(
        croppedFace,
        width: INPUT_SIZE,
        height: INPUT_SIZE,
      );
      
      // Normalize pixel values to [-1, 1]
      final input = _imageToByteListFloat32(resizedFace);
      
      // Run inference
      final output = List.filled(EMBEDDING_SIZE, 0.0).reshape([1, EMBEDDING_SIZE]);
      
      print('[FaceRecognition] 🧠 Running inference...');
      _interpreter!.run(input, output);
      
      final embedding = List<double>.from(output[0]);
      
      // Normalize embedding (L2 normalization)
      final normalizedEmbedding = _normalizeEmbedding(embedding);
      
      print('[FaceRecognition] ✅ Embedding generated (${normalizedEmbedding.length} dimensions)');
      
      return normalizedEmbedding;
      
    } catch (e, stackTrace) {
      print('[FaceRecognition] ❌ Error generating embedding: $e');
      print('[FaceRecognition] Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Compare two face embeddings using cosine similarity
  double compareEmbeddings(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      print('[FaceRecognition] ❌ Embedding dimensions mismatch');
      return 0.0;
    }
    
    // Calculate cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }
    
    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));
    
    print('[FaceRecognition] 📊 Cosine similarity: ${(similarity * 100).toStringAsFixed(2)}%');
    
    return similarity;
  }
  
  /// Convert image to normalized float32 byte list
  Float32List _imageToByteListFloat32(img.Image image) {
    final convertedBytes = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    
    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        final pixel = image.getPixel(x, y);
        
        // Normalize to [-1, 1] range
        buffer[pixelIndex++] = (pixel.r / 127.5) - 1.0;
        buffer[pixelIndex++] = (pixel.g / 127.5) - 1.0;
        buffer[pixelIndex++] = (pixel.b / 127.5) - 1.0;
      }
    }
    
    return convertedBytes.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);
  }
  
  /// Normalize embedding using L2 normalization
  List<double> _normalizeEmbedding(List<double> embedding) {
    double sum = 0.0;
    for (final value in embedding) {
      sum += value * value;
    }
    
    final norm = sqrt(sum);
    if (norm == 0.0) return embedding;
    
    return embedding.map((value) => value / norm).toList();
  }
  
  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
