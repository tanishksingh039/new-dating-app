import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;
  
  FaceDetectionService() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      minFaceSize: 0.10, // Lowered from 0.15 to allow smaller faces
      performanceMode: FaceDetectorMode.fast, // Changed from accurate to fast for better detection
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<FaceDetectionResult> detectFacesInImage(String imagePath) async {
    print('═══════════════════════════════════════════════════════════');
    print('[FaceDetection] 🔍 detectFacesInImage STARTED');
    print('[FaceDetection] Image path: $imagePath');
    print('═══════════════════════════════════════════════════════════');
    
    try {
      // Check if file exists
      final file = File(imagePath);
      final exists = await file.exists();
      print('[FaceDetection] 📁 File exists: $exists');
      
      if (!exists) {
        print('[FaceDetection] ❌ ERROR: Image file does not exist!');
        return FaceDetectionResult(
          success: false,
          faceCount: 0,
          faces: [],
          message: 'Image file not found',
        );
      }
      
      // Get file size
      final fileSize = await file.length();
      print('[FaceDetection] 📊 File size: ${fileSize} bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
      
      print('[FaceDetection] 🖼️ Creating InputImage from file path...');
      final inputImage = InputImage.fromFilePath(imagePath);
      print('[FaceDetection] ✅ InputImage created successfully');
      
      print('[FaceDetection] 🔍 Processing image with ML Kit Face Detector...');
      final startTime = DateTime.now();
      final faces = await _faceDetector.processImage(inputImage);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      print('[FaceDetection] ⏱️ Face detection completed in ${duration}ms');
      print('[FaceDetection] 👤 Faces detected: ${faces.length}');
      
      if (faces.isEmpty) {
        print('[FaceDetection] ⚠️ NO FACES DETECTED in image');
      } else {
        for (int i = 0; i < faces.length; i++) {
          final face = faces[i];
          print('[FaceDetection] 👤 Face ${i + 1}:');
          print('[FaceDetection]    Bounding box: ${face.boundingBox}');
          print('[FaceDetection]    Width: ${face.boundingBox.width}, Height: ${face.boundingBox.height}');
          print('[FaceDetection]    Area: ${face.boundingBox.width * face.boundingBox.height}');
          print('[FaceDetection]    Head Euler Angle X: ${face.headEulerAngleX}');
          print('[FaceDetection]    Head Euler Angle Y: ${face.headEulerAngleY}');
          print('[FaceDetection]    Head Euler Angle Z: ${face.headEulerAngleZ}');
          print('[FaceDetection]    Smiling probability: ${face.smilingProbability}');
          print('[FaceDetection]    Left eye open probability: ${face.leftEyeOpenProbability}');
          print('[FaceDetection]    Right eye open probability: ${face.rightEyeOpenProbability}');
        }
      }
      
      print('[FaceDetection] ✅ detectFacesInImage COMPLETED');
      print('═══════════════════════════════════════════════════════════');
      
      return FaceDetectionResult(
        success: true,
        faceCount: faces.length,
        faces: faces,
        message: _getResultMessage(faces.length),
      );
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[FaceDetection] ❌ EXCEPTION in detectFacesInImage');
      print('[FaceDetection] Error: $e');
      print('[FaceDetection] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      debugPrint('Error detecting faces: $e');
      return FaceDetectionResult(
        success: false,
        faceCount: 0,
        faces: [],
        message: 'Error: $e',
      );
    }
  }

  Future<FaceDetectionResult> detectFacesFromXFile(XFile imageFile) async {
    return await detectFacesInImage(imageFile.path);
  }

  Future<ProfileVerificationResult> validateProfileImage(String imagePath) async {
    print('═══════════════════════════════════════════════════════════');
    print('[FaceDetection] 🔍 validateProfileImage STARTED');
    print('[FaceDetection] Image path: $imagePath');
    print('═══════════════════════════════════════════════════════════');
    
    final result = await detectFacesInImage(imagePath);
    
    print('[FaceDetection] 📊 Detection result:');
    print('[FaceDetection]    Success: ${result.success}');
    print('[FaceDetection]    Face count: ${result.faceCount}');
    print('[FaceDetection]    Message: ${result.message}');
    
    if (!result.success) {
      print('[FaceDetection] ❌ VALIDATION FAILED: Detection not successful');
      print('═══════════════════════════════════════════════════════════');
      return ProfileVerificationResult(
        isValid: false,
        message: result.message,
        confidence: 0.0,
      );
    }

    if (result.faceCount == 0) {
      print('[FaceDetection] ❌ VALIDATION FAILED: No face detected');
      print('═══════════════════════════════════════════════════════════');
      return ProfileVerificationResult(
        isValid: false,
        message: 'No face detected. Please ensure your face is clearly visible.',
        confidence: 0.0,
      );
    }

    if (result.faceCount > 1) {
      print('[FaceDetection] ❌ VALIDATION FAILED: Multiple faces detected (${result.faceCount})');
      print('═══════════════════════════════════════════════════════════');
      return ProfileVerificationResult(
        isValid: false,
        message: 'Multiple faces detected. Please take a photo with only your face.',
        confidence: 0.0,
      );
    }

    final face = result.faces.first;
    final boundingBox = face.boundingBox;
    final faceArea = boundingBox.width * boundingBox.height;
    
    print('[FaceDetection] 📏 Face measurements:');
    print('[FaceDetection]    Bounding box: ${boundingBox}');
    print('[FaceDetection]    Width: ${boundingBox.width}');
    print('[FaceDetection]    Height: ${boundingBox.height}');
    print('[FaceDetection]    Area: $faceArea (minimum required: 5000)');
    
    // Lowered from 10000 to 5000 to allow smaller faces
    if (faceArea < 5000) {
      print('[FaceDetection] ❌ VALIDATION FAILED: Face too small ($faceArea < 5000)');
      print('═══════════════════════════════════════════════════════════');
      return ProfileVerificationResult(
        isValid: false,
        message: 'Face is too small. Please move closer.',
        confidence: 0.0,
      );
    }

    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    
    print('[FaceDetection] 📐 Head angles:');
    print('[FaceDetection]    Euler Angle Y: $headEulerAngleY (max: ±45°)');
    print('[FaceDetection]    Euler Angle Z: $headEulerAngleZ (max: ±45°)');
    
    // Increased from 30 to 45 degrees to allow more angled faces
    if (headEulerAngleY.abs() > 45 || headEulerAngleZ.abs() > 45) {
      print('[FaceDetection] ❌ VALIDATION FAILED: Head angle too extreme');
      print('[FaceDetection]    Y angle: ${headEulerAngleY.abs()} > 45°');
      print('[FaceDetection]    Z angle: ${headEulerAngleZ.abs()} > 45°');
      print('═══════════════════════════════════════════════════════════');
      return ProfileVerificationResult(
        isValid: false,
        message: 'Please face the camera directly.',
        confidence: 0.0,
      );
    }

    // Removed strict eye open requirement - too restrictive
    // Users can have eyes partially closed, squinting, etc.

    double confidence = 1.0;
    confidence -= (headEulerAngleY.abs() / 100);
    confidence -= (headEulerAngleZ.abs() / 100);
    
    if (face.smilingProbability != null && face.smilingProbability! > 0.5) {
      confidence += 0.1;
    }
    
    confidence = confidence.clamp(0.0, 1.0);
    
    print('[FaceDetection] 💯 Confidence calculation:');
    print('[FaceDetection]    Base confidence: 1.0');
    print('[FaceDetection]    Y angle penalty: -${(headEulerAngleY.abs() / 100).toStringAsFixed(3)}');
    print('[FaceDetection]    Z angle penalty: -${(headEulerAngleZ.abs() / 100).toStringAsFixed(3)}');
    print('[FaceDetection]    Smiling bonus: ${face.smilingProbability != null && face.smilingProbability! > 0.5 ? '+0.1' : '0.0'}');
    print('[FaceDetection]    Final confidence: ${confidence.toStringAsFixed(3)}');
    
    print('[FaceDetection] ✅ VALIDATION PASSED');
    print('═══════════════════════════════════════════════════════════');

    return ProfileVerificationResult(
      isValid: true,
      message: 'Face verified successfully!',
      confidence: confidence,
      face: face,
    );
  }

  // Compare two faces for similarity (basic implementation)
  Future<FaceComparisonResult> compareFaces(String imagePath1, String imagePath2) async {
    print('═══════════════════════════════════════════════════════════');
    print('[FaceDetection] 🔄 compareFaces STARTED');
    print('[FaceDetection] Image 1: $imagePath1');
    print('[FaceDetection] Image 2: $imagePath2');
    print('═══════════════════════════════════════════════════════════');
    
    print('[FaceDetection] 🔍 Detecting faces in image 1...');
    final result1 = await detectFacesInImage(imagePath1);
    print('[FaceDetection] 🔍 Detecting faces in image 2...');
    final result2 = await detectFacesInImage(imagePath2);

    print('[FaceDetection] 📊 Comparison results:');
    print('[FaceDetection]    Image 1 - Success: ${result1.success}, Faces: ${result1.faceCount}');
    print('[FaceDetection]    Image 2 - Success: ${result2.success}, Faces: ${result2.faceCount}');

    if (!result1.success || !result2.success) {
      print('[FaceDetection] ❌ COMPARISON FAILED: Detection error');
      print('═══════════════════════════════════════════════════════════');
      return FaceComparisonResult(
        isMatch: false,
        similarity: 0.0,
        message: 'Error detecting faces in one or both images',
      );
    }

    if (result1.faceCount != 1 || result2.faceCount != 1) {
      print('[FaceDetection] ❌ COMPARISON FAILED: Invalid face count');
      print('[FaceDetection]    Image 1 faces: ${result1.faceCount} (expected: 1)');
      print('[FaceDetection]    Image 2 faces: ${result2.faceCount} (expected: 1)');
      print('═══════════════════════════════════════════════════════════');
      return FaceComparisonResult(
        isMatch: false,
        similarity: 0.0,
        message: 'Each image must contain exactly one face',
      );
    }

    final face1 = result1.faces.first;
    final face2 = result2.faces.first;

    print('[FaceDetection] 🧮 Calculating face similarity...');
    // Basic similarity check using face landmarks and angles
    double similarity = _calculateFaceSimilarity(face1, face2);
    
    print('[FaceDetection] 📊 Similarity score: ${(similarity * 100).toStringAsFixed(2)}%');
    print('[FaceDetection] 🎯 Threshold: 60% (MEDIUM strictness)');
    print('[FaceDetection] 🔍 Match result: ${similarity > 0.6 ? 'MATCH ✅' : 'NO MATCH ❌'}');

    // MEDIUM strictness: 60% similarity for face comparison
    final result = FaceComparisonResult(
      isMatch: similarity > 0.6,
      similarity: similarity,
      message: similarity > 0.6 ? 'Faces match!' : 'Faces do not match',
    );
    
    print('[FaceDetection] ✅ compareFaces COMPLETED');
    print('═══════════════════════════════════════════════════════════');
    
    return result;
  }

  // Calculate face similarity using multiple facial features
  double _calculateFaceSimilarity(Face face1, Face face2) {
    double similarity = 0.0;
    int featureCount = 0;

    // 1. Compare head angles (Euler angles)
    final angleY1 = face1.headEulerAngleY ?? 0;
    final angleY2 = face2.headEulerAngleY ?? 0;
    final angleZ1 = face1.headEulerAngleZ ?? 0;
    final angleZ2 = face2.headEulerAngleZ ?? 0;
    final angleX1 = face1.headEulerAngleX ?? 0;
    final angleX2 = face2.headEulerAngleX ?? 0;

    final angleDiffY = (angleY1 - angleY2).abs();
    final angleDiffZ = (angleZ1 - angleZ2).abs();
    final angleDiffX = (angleX1 - angleX2).abs();

    // Angle similarity (lower diff = higher similarity)
    double angleSimilarity = 1.0 - ((angleDiffY + angleDiffZ + angleDiffX) / 300);
    similarity += angleSimilarity;
    featureCount++;

    // 2. Compare bounding box dimensions (FIXED: scale-invariant)
    // Don't compare absolute sizes - photos can be different resolutions
    // Instead, we'll rely on aspect ratio which is scale-invariant
    // This prevents negative similarity when one photo is compressed
    
    // REMOVED: Size comparison is unreliable for different image resolutions
    // Profile photos are often compressed (WebP, smaller resolution)
    // Liveness photos are high-res from camera
    // Comparing absolute sizes would penalize legitimate matches

    // 3. Compare bounding box aspect ratio (scale-invariant)
    final width1 = face1.boundingBox.width;
    final width2 = face2.boundingBox.width;
    final height1 = face1.boundingBox.height;
    final height2 = face2.boundingBox.height;
    
    final ratio1 = width1 / height1;
    final ratio2 = width2 / height2;
    final ratioDiff = (ratio1 - ratio2).abs();

    // Aspect ratio similarity (clamped to prevent negative values)
    double ratioSimilarity = (1.0 - (ratioDiff * 0.5)).clamp(0.0, 1.0);
    similarity += ratioSimilarity;
    featureCount++;

    // 4. Compare face landmarks if available
    if (face1.landmarks.isNotEmpty && face2.landmarks.isNotEmpty) {
      double landmarkSimilarity = _compareLandmarks(face1, face2);
      similarity += landmarkSimilarity;
      featureCount++;
    }

    // 5. Compare smiling probability
    final smilingProb1 = face1.smilingProbability ?? 0.5;
    final smilingProb2 = face2.smilingProbability ?? 0.5;
    final smilingDiff = (smilingProb1 - smilingProb2).abs();

    double smilingSimilarity = 1.0 - smilingDiff;
    similarity += smilingSimilarity;
    featureCount++;

    // Calculate average similarity
    final averageSimilarity = similarity / featureCount;
    
    debugPrint('[FaceDetectionService] Face Similarity Breakdown:');
    debugPrint('  Angle Similarity: ${(angleSimilarity * 100).toStringAsFixed(1)}%');
    debugPrint('  Ratio Similarity: ${(ratioSimilarity * 100).toStringAsFixed(1)}%');
    if (face1.landmarks.isNotEmpty && face2.landmarks.isNotEmpty) {
      final landmarkSim = _compareLandmarks(face1, face2);
      debugPrint('  Landmark Similarity: ${(landmarkSim * 100).toStringAsFixed(1)}%');
    }
    debugPrint('  Smiling Similarity: ${(smilingSimilarity * 100).toStringAsFixed(1)}%');
    debugPrint('  Average Similarity: ${(averageSimilarity * 100).toStringAsFixed(1)}%');
    debugPrint('  Feature Count: $featureCount');

    return averageSimilarity.clamp(0.0, 1.0);
  }

  // Compare face landmarks
  double _compareLandmarks(Face face1, Face face2) {
    if (face1.landmarks.isEmpty || face2.landmarks.isEmpty) {
      return 0.5; // Neutral if landmarks not available
    }

    double totalDiff = 0.0;
    int comparedLandmarks = 0;

    // Iterate over landmarks map entries
    for (var entry1 in face1.landmarks.entries) {
      final landmark1 = entry1.value;
      if (landmark1 == null) continue;

      // Find corresponding landmark in face2
      final landmark2 = face2.landmarks[entry1.key];
      if (landmark2 == null) continue;

      final dx = (landmark1.position.x - landmark2.position.x).abs();
      final dy = (landmark1.position.y - landmark2.position.y).abs();
      final distance = sqrt(dx * dx + dy * dy);
      totalDiff += distance;
      comparedLandmarks++;
    }

    if (comparedLandmarks == 0) return 0.5;

    final avgDiff = totalDiff / comparedLandmarks;
    // Normalize distance difference (lower is better)
    double landmarkSimilarity = 1.0 - (avgDiff / 200).clamp(0.0, 1.0);
    
    debugPrint('  Landmark Similarity: ${(landmarkSimilarity * 100).toStringAsFixed(1)}%');
    
    return landmarkSimilarity;
  }

  String _getResultMessage(int faceCount) {
    if (faceCount == 0) return 'No faces detected';
    if (faceCount == 1) return '1 face detected';
    return '$faceCount faces detected';
  }

  void dispose() {
    _faceDetector.close();
  }
}

class FaceDetectionResult {
  final bool success;
  final int faceCount;
  final List<Face> faces;
  final String message;

  FaceDetectionResult({
    required this.success,
    required this.faceCount,
    required this.faces,
    required this.message,
  });
}

class ProfileVerificationResult {
  final bool isValid;
  final String message;
  final double confidence;
  final Face? face;

  ProfileVerificationResult({
    required this.isValid,
    required this.message,
    required this.confidence,
    this.face,
  });
}

class FaceComparisonResult {
  final bool isMatch;
  final double similarity;
  final String message;

  FaceComparisonResult({
    required this.isMatch,
    required this.similarity,
    required this.message,
  });
}
