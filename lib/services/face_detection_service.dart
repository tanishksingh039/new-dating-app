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
  // CRITICAL: This must verify SAME PERSON, not just similar angles
  double _calculateFaceSimilarity(Face face1, Face face2) {
    print('[FaceDetection] 🧮 _calculateFaceSimilarity STARTED');
    print('[FaceDetection] ═══════════════════════════════════════════════════════════');
    
    double totalScore = 0.0;
    int criticalChecks = 0;
    
    // CRITICAL CHECK 1: Landmark-based identity verification (MOST IMPORTANT)
    // Landmarks are unique to each person's facial structure
    if (face1.landmarks.isNotEmpty && face2.landmarks.isNotEmpty) {
      print('[FaceDetection] ✅ CHECK 1: Comparing facial landmarks (CRITICAL)');
      double landmarkSimilarity = _compareLandmarksStrict(face1, face2);
      print('[FaceDetection]    Landmark similarity: ${(landmarkSimilarity * 100).toStringAsFixed(2)}%');
      
      // Landmarks are the PRIMARY identity check - weight heavily
      totalScore += landmarkSimilarity * 3.0; // Triple weight
      criticalChecks += 3;
      
      // If landmarks don't match well, it's likely different people
      if (landmarkSimilarity < 0.5) {
        print('[FaceDetection] ❌ LANDMARK MISMATCH: ${(landmarkSimilarity * 100).toStringAsFixed(2)}% < 50%');
        print('[FaceDetection]    This indicates DIFFERENT PEOPLE');
        print('[FaceDetection] ═══════════════════════════════════════════════════════════');
        return 0.0; // Immediate fail - different people
      }
    } else {
      print('[FaceDetection] ⚠️ WARNING: No landmarks available - cannot verify identity properly');
      print('[FaceDetection]    This is a security risk - verification may be unreliable');
      // Without landmarks, we cannot reliably verify identity
      // Return low score to fail verification
      return 0.3; // Not enough data to verify same person
    }
    
    // CRITICAL CHECK 2: Eye distance ratio (unique to facial structure)
    print('[FaceDetection] ✅ CHECK 2: Comparing eye distance ratio');
    double eyeDistanceScore = _compareEyeDistance(face1, face2);
    print('[FaceDetection]    Eye distance similarity: ${(eyeDistanceScore * 100).toStringAsFixed(2)}%');
    
    if (eyeDistanceScore > 0) {
      totalScore += eyeDistanceScore * 2.0; // Double weight
      criticalChecks += 2;
    }
    
    // CRITICAL CHECK 3: Nose-to-mouth ratio (unique to facial structure)
    print('[FaceDetection] ✅ CHECK 3: Comparing nose-to-mouth ratio');
    double noseToMouthScore = _compareNoseToMouth(face1, face2);
    print('[FaceDetection]    Nose-to-mouth similarity: ${(noseToMouthScore * 100).toStringAsFixed(2)}%');
    
    if (noseToMouthScore > 0) {
      totalScore += noseToMouthScore * 2.0; // Double weight
      criticalChecks += 2;
    }
    
    // SUPPLEMENTARY CHECK 4: Face aspect ratio
    print('[FaceDetection] ✅ CHECK 4: Comparing face aspect ratio');
    final width1 = face1.boundingBox.width;
    final width2 = face2.boundingBox.width;
    final height1 = face1.boundingBox.height;
    final height2 = face2.boundingBox.height;
    
    final ratio1 = width1 / height1;
    final ratio2 = width2 / height2;
    final ratioDiff = (ratio1 - ratio2).abs();
    
    double ratioSimilarity = (1.0 - (ratioDiff * 2.0)).clamp(0.0, 1.0);
    print('[FaceDetection]    Aspect ratio similarity: ${(ratioSimilarity * 100).toStringAsFixed(2)}%');
    
    totalScore += ratioSimilarity;
    criticalChecks += 1;
    
    // Calculate weighted average
    final finalScore = criticalChecks > 0 ? (totalScore / criticalChecks) : 0.0;
    
    print('[FaceDetection] 📊 FINAL SIMILARITY BREAKDOWN:');
    print('[FaceDetection]    Total score: ${totalScore.toStringAsFixed(3)}');
    print('[FaceDetection]    Critical checks: $criticalChecks');
    print('[FaceDetection]    Final similarity: ${(finalScore * 100).toStringAsFixed(2)}%');
    print('[FaceDetection]    Threshold: 80% (HIGH strictness)');
    print('[FaceDetection]    Result: ${finalScore > 0.8 ? 'MATCH ✅' : 'NO MATCH ❌'}');
    print('[FaceDetection] ═══════════════════════════════════════════════════════════');
    
    return finalScore.clamp(0.0, 1.0);
  }
  
  // Strict landmark comparison for identity verification
  double _compareLandmarksStrict(Face face1, Face face2) {
    if (face1.landmarks.isEmpty || face2.landmarks.isEmpty) {
      return 0.0; // Cannot verify without landmarks
    }
    
    // Key landmarks for identity: eyes, nose, mouth
    final keyLandmarkTypes = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
    ];
    
    double totalSimilarity = 0.0;
    int matchedLandmarks = 0;
    
    for (final landmarkType in keyLandmarkTypes) {
      final landmark1 = face1.landmarks[landmarkType];
      final landmark2 = face2.landmarks[landmarkType];
      
      if (landmark1 == null || landmark2 == null) continue;
      
      // Calculate relative position (normalized by face size)
      final relX1 = (landmark1.position.x - face1.boundingBox.left) / face1.boundingBox.width;
      final relY1 = (landmark1.position.y - face1.boundingBox.top) / face1.boundingBox.height;
      
      final relX2 = (landmark2.position.x - face2.boundingBox.left) / face2.boundingBox.width;
      final relY2 = (landmark2.position.y - face2.boundingBox.top) / face2.boundingBox.height;
      
      // Calculate normalized distance
      final dx = (relX1 - relX2).abs();
      final dy = (relY1 - relY2).abs();
      final distance = sqrt(dx * dx + dy * dy);
      
      // Convert distance to similarity (closer = more similar)
      // Use MEDIUM threshold: 0.1 normalized distance = 0% similarity
      final similarity = (1.0 - (distance / 0.1)).clamp(0.0, 1.0);
      
      totalSimilarity += similarity;
      matchedLandmarks++;
      
      print('[FaceDetection]      ${landmarkType.toString().split('.').last}: ${(similarity * 100).toStringAsFixed(1)}%');
    }
    
    if (matchedLandmarks == 0) return 0.0;
    
    return totalSimilarity / matchedLandmarks;
  }
  
  // Compare eye distance (unique to facial structure)
  double _compareEyeDistance(Face face1, Face face2) {
    final leftEye1 = face1.landmarks[FaceLandmarkType.leftEye];
    final rightEye1 = face1.landmarks[FaceLandmarkType.rightEye];
    final leftEye2 = face2.landmarks[FaceLandmarkType.leftEye];
    final rightEye2 = face2.landmarks[FaceLandmarkType.rightEye];
    
    if (leftEye1 == null || rightEye1 == null || leftEye2 == null || rightEye2 == null) {
      return 0.0;
    }
    
    // Calculate eye distance normalized by face width
    final eyeDist1 = (rightEye1.position.x - leftEye1.position.x) / face1.boundingBox.width;
    final eyeDist2 = (rightEye2.position.x - leftEye2.position.x) / face2.boundingBox.width;
    
    final diff = (eyeDist1 - eyeDist2).abs();
    
    // Stricter threshold: 5% difference = 0% similarity
    return (1.0 - (diff / 0.05)).clamp(0.0, 1.0);
  }
  
  // Compare nose-to-mouth distance (unique to facial structure)
  double _compareNoseToMouth(Face face1, Face face2) {
    final nose1 = face1.landmarks[FaceLandmarkType.noseBase];
    final mouth1 = face1.landmarks[FaceLandmarkType.bottomMouth];
    final nose2 = face2.landmarks[FaceLandmarkType.noseBase];
    final mouth2 = face2.landmarks[FaceLandmarkType.bottomMouth];
    
    if (nose1 == null || mouth1 == null || nose2 == null || mouth2 == null) {
      return 0.0;
    }
    
    // Calculate nose-to-mouth distance normalized by face height
    final noseMouthDist1 = (mouth1.position.y - nose1.position.y) / face1.boundingBox.height;
    final noseMouthDist2 = (mouth2.position.y - nose2.position.y) / face2.boundingBox.height;
    
    final diff = (noseMouthDist1 - noseMouthDist2).abs();
    
    // Stricter threshold: 5% difference = 0% similarity
    return (1.0 - (diff / 0.05)).clamp(0.0, 1.0);
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
