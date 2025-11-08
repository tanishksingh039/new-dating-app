import 'dart:io';
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
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<FaceDetectionResult> detectFacesInImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      
      return FaceDetectionResult(
        success: true,
        faceCount: faces.length,
        faces: faces,
        message: _getResultMessage(faces.length),
      );
    } catch (e) {
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
    final result = await detectFacesInImage(imagePath);
    
    if (!result.success) {
      return ProfileVerificationResult(
        isValid: false,
        message: result.message,
        confidence: 0.0,
      );
    }

    if (result.faceCount == 0) {
      return ProfileVerificationResult(
        isValid: false,
        message: 'No face detected. Please ensure your face is clearly visible.',
        confidence: 0.0,
      );
    }

    if (result.faceCount > 1) {
      return ProfileVerificationResult(
        isValid: false,
        message: 'Multiple faces detected. Please take a photo with only your face.',
        confidence: 0.0,
      );
    }

    final face = result.faces.first;
    final boundingBox = face.boundingBox;
    final faceArea = boundingBox.width * boundingBox.height;
    
    if (faceArea < 10000) {
      return ProfileVerificationResult(
        isValid: false,
        message: 'Face is too small. Please move closer.',
        confidence: 0.0,
      );
    }

    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    
    if (headEulerAngleY.abs() > 30 || headEulerAngleZ.abs() > 30) {
      return ProfileVerificationResult(
        isValid: false,
        message: 'Please face the camera directly.',
        confidence: 0.0,
      );
    }

    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final leftEyeOpen = face.leftEyeOpenProbability! > 0.5;
      final rightEyeOpen = face.rightEyeOpenProbability! > 0.5;
      
      if (!leftEyeOpen || !rightEyeOpen) {
        return ProfileVerificationResult(
          isValid: false,
          message: 'Please keep your eyes open.',
          confidence: 0.0,
        );
      }
    }

    double confidence = 1.0;
    confidence -= (headEulerAngleY.abs() / 100);
    confidence -= (headEulerAngleZ.abs() / 100);
    
    if (face.smilingProbability != null && face.smilingProbability! > 0.5) {
      confidence += 0.1;
    }
    
    confidence = confidence.clamp(0.0, 1.0);

    return ProfileVerificationResult(
      isValid: true,
      message: 'Face verified successfully!',
      confidence: confidence,
      face: face,
    );
  }

  // Compare two faces for similarity (basic implementation)
  Future<FaceComparisonResult> compareFaces(String imagePath1, String imagePath2) async {
    final result1 = await detectFacesInImage(imagePath1);
    final result2 = await detectFacesInImage(imagePath2);

    if (!result1.success || !result2.success) {
      return FaceComparisonResult(
        isMatch: false,
        similarity: 0.0,
        message: 'Error detecting faces in one or both images',
      );
    }

    if (result1.faceCount != 1 || result2.faceCount != 1) {
      return FaceComparisonResult(
        isMatch: false,
        similarity: 0.0,
        message: 'Each image must contain exactly one face',
      );
    }

    final face1 = result1.faces.first;
    final face2 = result2.faces.first;

    // Basic similarity check using face landmarks and angles
    double similarity = _calculateFaceSimilarity(face1, face2);

    return FaceComparisonResult(
      isMatch: similarity > 0.7,
      similarity: similarity,
      message: similarity > 0.7 ? 'Faces match!' : 'Faces do not match',
    );
  }

  // Calculate basic face similarity
  double _calculateFaceSimilarity(Face face1, Face face2) {
    double similarity = 1.0;

    // Compare head angles
    final angleY1 = face1.headEulerAngleY ?? 0;
    final angleY2 = face2.headEulerAngleY ?? 0;
    final angleZ1 = face1.headEulerAngleZ ?? 0;
    final angleZ2 = face2.headEulerAngleZ ?? 0;

    final angleDiffY = (angleY1 - angleY2).abs();
    final angleDiffZ = (angleZ1 - angleZ2).abs();

    similarity -= (angleDiffY / 100);
    similarity -= (angleDiffZ / 100);

    // Compare bounding box aspect ratios
    final ratio1 = face1.boundingBox.width / face1.boundingBox.height;
    final ratio2 = face2.boundingBox.width / face2.boundingBox.height;
    final ratioDiff = (ratio1 - ratio2).abs();
    
    similarity -= (ratioDiff * 0.5);

    return similarity.clamp(0.0, 1.0);
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
