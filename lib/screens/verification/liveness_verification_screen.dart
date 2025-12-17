import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'dart:math';
import '../../services/face_detection_service.dart';
import '../../services/r2_storage_service.dart';
import '../../services/profile_picture_verification_service.dart';
import '../../constants/app_colors.dart';

class LivenessVerificationScreen extends StatefulWidget {
  // Optional: Pass context to indicate this is for profile picture verification
  final bool isProfilePictureVerification;
  
  const LivenessVerificationScreen({
    Key? key,
    this.isProfilePictureVerification = false,
  }) : super(key: key);

  @override
  State<LivenessVerificationScreen> createState() => _LivenessVerificationScreenState();
}

class _LivenessVerificationScreenState extends State<LivenessVerificationScreen> {
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final ImagePicker _imagePicker = ImagePicker();
  final Random _random = Random();
  
  bool _isProcessing = false;
  int _currentStep = 0;
  List<String> _challenges = [];
  List<File> _capturedImages = [];
  List<ProfileVerificationResult> _verificationResults = [];
  
  final List<String> _allChallenges = [
    'Smile naturally',
    'Turn your head slightly left',
    'Turn your head slightly right',
    'Look straight at camera',
    'Raise your eyebrows',
  ];

  @override
  void initState() {
    super.initState();
    _generateChallenges();
  }

  @override
  void dispose() {
    _faceDetectionService.dispose();
    super.dispose();
  }

  void _generateChallenges() {
    // Generate 3 random challenges
    final shuffled = List<String>.from(_allChallenges)..shuffle(_random);
    _challenges = shuffled.take(3).toList();
    // Always start with neutral face
    _challenges.insert(0, 'Look straight at camera');
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
    
    print('═══════════════════════════════════════════════════════════');
    print('[LivenessVerification] 📸 _capturePhoto STARTED');
    print('[LivenessVerification] Current step: $_currentStep/${_challenges.length}');
    print('[LivenessVerification] Current challenge: ${_challenges[_currentStep]}');
    print('═══════════════════════════════════════════════════════════');
    
    setState(() => _isProcessing = true);
    
    try {
      print('[LivenessVerification] 📷 Opening camera...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera, // CAMERA ONLY - no gallery
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        print('[LivenessVerification] ✅ Photo captured: ${image.path}');
        
        // Verify it's a recent photo (anti-spoofing)
        final file = File(image.path);
        final fileStats = await file.stat();
        final now = DateTime.now();
        final timeDiff = now.difference(fileStats.modified).inSeconds;
        
        print('[LivenessVerification] ⏱️ Photo timestamp check:');
        print('[LivenessVerification]    Modified: ${fileStats.modified}');
        print('[LivenessVerification]    Now: $now');
        print('[LivenessVerification]    Time diff: ${timeDiff}s (max: 10s)');
        
        // Photo must be taken within last 10 seconds
        if (timeDiff > 10) {
          print('[LivenessVerification] ❌ ANTI-SPOOFING FAILED: Photo too old (${timeDiff}s > 10s)');
          _showError('Please take a fresh photo, not from gallery!');
          setState(() => _isProcessing = false);
          return;
        }
        print('[LivenessVerification] ✅ Anti-spoofing check passed');
        
        // Verify face
        print('[LivenessVerification] 🔍 Validating face in photo...');
        final result = await _faceDetectionService.validateProfileImage(image.path);
        
        print('[LivenessVerification] 📊 Validation result:');
        print('[LivenessVerification]    Valid: ${result.isValid}');
        print('[LivenessVerification]    Message: ${result.message}');
        print('[LivenessVerification]    Confidence: ${result.confidence}');
        
        if (!result.isValid) {
          print('[LivenessVerification] ❌ FACE VALIDATION FAILED: ${result.message}');
          _showError(result.message);
          setState(() => _isProcessing = false);
          return;
        }
        
        print('[LivenessVerification] ✅ Face validation passed');
        
        // Store the image and result
        _capturedImages.add(file);
        _verificationResults.add(result);
        
        print('[LivenessVerification] 💾 Stored image and result');
        print('[LivenessVerification] 📊 Progress: ${_capturedImages.length}/${_challenges.length} photos captured');
        
        // Move to next challenge
        if (_currentStep < _challenges.length - 1) {
          print('[LivenessVerification] ➡️ Moving to next challenge');
          setState(() {
            _currentStep++;
            _isProcessing = false;
          });
          print('[LivenessVerification] ✅ _capturePhoto COMPLETED - Next challenge');
          print('═══════════════════════════════════════════════════════════');
        } else {
          print('[LivenessVerification] 🎯 All challenges completed - starting liveness verification');
          print('═══════════════════════════════════════════════════════════');
          // All challenges completed - verify liveness
          await _verifyLiveness();
        }
      } else {
        print('[LivenessVerification] ⚠️ No photo captured (user cancelled)');
        setState(() => _isProcessing = false);
        print('═══════════════════════════════════════════════════════════');
      }
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[LivenessVerification] ❌ EXCEPTION in _capturePhoto');
      print('[LivenessVerification] Error: $e');
      print('[LivenessVerification] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      setState(() => _isProcessing = false);
      _showError('Error: $e');
    }
  }

  Future<void> _verifyLiveness() async {
    print('═══════════════════════════════════════════════════════════');
    print('[LivenessVerification] 🔐 _verifyLiveness STARTED');
    print('[LivenessVerification] Total photos captured: ${_capturedImages.length}');
    print('[LivenessVerification] Total verification results: ${_verificationResults.length}');
    print('═══════════════════════════════════════════════════════════');
    
    setState(() => _isProcessing = true);
    
    try {
      // Check 1: All photos must have valid faces
      print('[LivenessVerification] ✅ CHECK 1: Validating all photos...');
      final invalidResults = _verificationResults.where((r) => !r.isValid).toList();
      print('[LivenessVerification]    Valid photos: ${_verificationResults.length - invalidResults.length}/${_verificationResults.length}');
      
      if (_verificationResults.any((r) => !r.isValid)) {
        print('[LivenessVerification] ❌ CHECK 1 FAILED: Some photos have invalid faces');
        for (int i = 0; i < _verificationResults.length; i++) {
          if (!_verificationResults[i].isValid) {
            print('[LivenessVerification]    Photo ${i + 1}: INVALID - ${_verificationResults[i].message}');
          }
        }
        _showError('Some photos failed validation. Please try again.');
        _resetVerification();
        return;
      }
      print('[LivenessVerification] ✅ CHECK 1 PASSED: All photos have valid faces');
      
      // Check 2: Verify face matches profile photo
      print('[LivenessVerification] ✅ CHECK 2: Verifying profile photo match...');
      bool matchesProfile = await _verifyProfilePhotoMatch();
      print('[LivenessVerification]    Profile match result: $matchesProfile');
      
      if (!matchesProfile) {
        print('[LivenessVerification] ❌ CHECK 2 FAILED: Face does not match profile photo');
        _showError('Face doesn\'t match your profile photo. Please use the same person.');
        _resetVerification();
        return;
      }
      print('[LivenessVerification] ✅ CHECK 2 PASSED: Face matches profile photo');
      
      // Check 3: Verify face consistency across images
      print('[LivenessVerification] ✅ CHECK 3: Verifying face consistency...');
      bool facesMatch = await _verifyFaceConsistency();
      print('[LivenessVerification]    Face consistency result: $facesMatch');
      
      if (!facesMatch) {
        print('[LivenessVerification] ❌ CHECK 3 FAILED: Faces do not match across photos');
        _showError('Faces don\'t match across photos. Please ensure it\'s the same person.');
        _resetVerification();
        return;
      }
      print('[LivenessVerification] ✅ CHECK 3 PASSED: Faces consistent across photos');
      
      // Check 4: Verify different expressions/poses (anti-spoofing)
      print('[LivenessVerification] ✅ CHECK 4: Verifying expression variation...');
      bool hasVariation = _verifyExpressionVariation();
      print('[LivenessVerification]    Expression variation result: $hasVariation');
      
      if (!hasVariation) {
        print('[LivenessVerification] ❌ CHECK 4 FAILED: Photos appear too similar');
        _showError('Photos appear too similar. Please follow the challenges.');
        _resetVerification();
        return;
      }
      print('[LivenessVerification] ✅ CHECK 4 PASSED: Expression variation detected');
      
      // All checks passed - submit verification
      print('[LivenessVerification] 🎉 ALL CHECKS PASSED - Submitting verification');
      print('═══════════════════════════════════════════════════════════');
      await _submitVerification();
      
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[LivenessVerification] ❌ EXCEPTION in _verifyLiveness');
      print('[LivenessVerification] Error: $e');
      print('[LivenessVerification] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      setState(() => _isProcessing = false);
      _showError('Verification error: $e');
    }
  }

  Future<bool> _verifyProfilePhotoMatch() async {
    print('═══════════════════════════════════════════════════════════');
    print('[LivenessVerification] 🔍 _verifyProfilePhotoMatch STARTED');
    print('═══════════════════════════════════════════════════════════');
    
    // Compare first liveness photo (straight face) with profile photo
    if (_capturedImages.isEmpty) {
      print('[LivenessVerification] ❌ No captured images available');
      return false;
    }
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('[LivenessVerification] 👤 User ID: $userId');
      
      if (userId == null) {
        print('[LivenessVerification] ❌ No user logged in');
        return false;
      }
      
      // Get user's profile photo URL from Firestore
      print('[LivenessVerification] 📡 Fetching user profile from Firestore...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        print('[LivenessVerification] ❌ User document does not exist');
        return false;
      }
      
      final userData = userDoc.data();
      
      // CRITICAL: If this is profile picture verification, use the PENDING photo
      // Otherwise, use the current profile photo
      String? profilePhotoUrl;
      
      if (widget.isProfilePictureVerification) {
        // Get the pending profile picture URL (the NEW photo being verified)
        profilePhotoUrl = userData?['pendingProfilePictureUrl'] as String?;
        print('[LivenessVerification] 🔄 Profile picture verification mode');
        print('[LivenessVerification] 📸 Using PENDING profile photo URL: $profilePhotoUrl');
        
        if (profilePhotoUrl == null || profilePhotoUrl.isEmpty) {
          print('[LivenessVerification] ❌ No pending profile photo found');
          _showError('No pending profile photo found. Please upload a photo first.');
          return false;
        }
      } else {
        // Regular verification - use current profile photo
        final List<dynamic>? photos = userData?['photos'] as List<dynamic>?;
        
        print('[LivenessVerification] 📸 Regular verification mode');
        print('[LivenessVerification] 📸 Profile photos count: ${photos?.length ?? 0}');
        
        if (photos == null || photos.isEmpty) {
          print('[LivenessVerification] ❌ No profile photos found');
          _showError('Please upload a profile photo first before verification.');
          return false;
        }
        
        // Get the first profile photo URL
        profilePhotoUrl = photos.first as String;
        print('[LivenessVerification] 🖼️ Using CURRENT profile photo URL: $profilePhotoUrl');
      }
      
      // Download profile photo to temp file for comparison
      print('[LivenessVerification] ⬇️ Downloading profile photo...');
      final tempDir = await Directory.systemTemp.createTemp();
      final profilePhotoFile = File('${tempDir.path}/profile_photo.jpg');
      
      final response = await HttpClient().getUrl(Uri.parse(profilePhotoUrl));
      final bytes = await consolidateHttpClientResponseBytes(await response.close());
      await profilePhotoFile.writeAsBytes(bytes);
      
      final downloadedSize = await profilePhotoFile.length();
      print('[LivenessVerification] ✅ Profile photo downloaded: ${downloadedSize} bytes');
      
      // Compare first liveness photo (straight face) with profile photo
      print('[LivenessVerification] 🔄 Comparing liveness photo with profile photo...');
      print('[LivenessVerification]    Liveness photo: ${_capturedImages.first.path}');
      print('[LivenessVerification]    Profile photo: ${profilePhotoFile.path}');
      
      final result = await _faceDetectionService.compareFaces(
        _capturedImages.first.path,  // First photo is always "Look straight at camera"
        profilePhotoFile.path,
      );
      
      print('[LivenessVerification] 📊 Comparison result:');
      print('[LivenessVerification]    Similarity: ${(result.similarity * 100).toStringAsFixed(2)}%');
      print('[LivenessVerification]    Threshold: 60% (MEDIUM strictness)');
      print('[LivenessVerification]    Match: ${result.similarity > 0.6 ? 'YES ✅' : 'NO ❌'}');
      
      // Clean up temp file
      print('[LivenessVerification] 🧹 Cleaning up temp files...');
      await profilePhotoFile.delete();
      await tempDir.delete();
      print('[LivenessVerification] ✅ Temp files cleaned');
      
      // MEDIUM strictness: Require 60% similarity with profile photo
      // This balances security with user experience
      final matches = result.similarity > 0.6;
      print('[LivenessVerification] ${matches ? '✅' : '❌'} Profile photo match: $matches');
      print('═══════════════════════════════════════════════════════════');
      return matches;
      
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[LivenessVerification] ❌ EXCEPTION in _verifyProfilePhotoMatch');
      print('[LivenessVerification] Error: $e');
      print('[LivenessVerification] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      return false;
    }
  }

  Future<bool> _verifyFaceConsistency() async {
    print('═══════════════════════════════════════════════════════════');
    print('[LivenessVerification] 🔍 _verifyFaceConsistency STARTED');
    print('[LivenessVerification] Total images: ${_capturedImages.length}');
    print('═══════════════════════════════════════════════════════════');
    
    // Compare first and last image to ensure same person
    if (_capturedImages.length < 2) {
      print('[LivenessVerification] ⚠️ Less than 2 images - skipping consistency check');
      print('═══════════════════════════════════════════════════════════');
      return true;
    }
    
    try {
      print('[LivenessVerification] 🔄 Comparing first and last images...');
      print('[LivenessVerification]    First image: ${_capturedImages.first.path}');
      print('[LivenessVerification]    Last image: ${_capturedImages.last.path}');
      
      final result = await _faceDetectionService.compareFaces(
        _capturedImages.first.path,
        _capturedImages.last.path,
      );
      
      print('[LivenessVerification] 📊 Consistency result:');
      print('[LivenessVerification]    Similarity: ${(result.similarity * 100).toStringAsFixed(2)}%');
      print('[LivenessVerification]    Threshold: 55% (MEDIUM strictness)');
      print('[LivenessVerification]    Consistent: ${result.similarity > 0.55 ? 'YES ✅' : 'NO ❌'}');
      
      // MEDIUM strictness: 55% similarity threshold for face consistency
      // Allows for different angles/expressions while ensuring same person
      final isConsistent = result.similarity > 0.55;
      print('[LivenessVerification] ${isConsistent ? '✅' : '❌'} Face consistency: $isConsistent');
      print('═══════════════════════════════════════════════════════════');
      return isConsistent;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('[LivenessVerification] ❌ EXCEPTION in _verifyFaceConsistency');
      print('[LivenessVerification] Error: $e');
      print('[LivenessVerification] Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════════');
      return false;
    }
  }

  bool _verifyExpressionVariation() {
    print('═══════════════════════════════════════════════════════════');
    print('[LivenessVerification] 🔍 _verifyExpressionVariation STARTED');
    print('[LivenessVerification] Verification results: ${_verificationResults.length}');
    print('═══════════════════════════════════════════════════════════');
    
    // Check if there's variation in head angles or expressions
    if (_verificationResults.length < 2) {
      print('[LivenessVerification] ❌ Less than 2 results - cannot check variation');
      print('═══════════════════════════════════════════════════════════');
      return false;
    }
    
    // Get head angles from each result
    List<double> angles = [];
    for (int i = 0; i < _verificationResults.length; i++) {
      final result = _verificationResults[i];
      if (result.face != null) {
        final angleY = result.face!.headEulerAngleY ?? 0;
        angles.add(angleY.abs());
        print('[LivenessVerification] Photo ${i + 1} - Head Euler Angle Y: ${angleY.toStringAsFixed(2)}° (abs: ${angleY.abs().toStringAsFixed(2)}°)');
      } else {
        print('[LivenessVerification] Photo ${i + 1} - No face data available');
      }
    }
    
    if (angles.isEmpty) {
      print('[LivenessVerification] ❌ No angle data available');
      print('═══════════════════════════════════════════════════════════');
      return false;
    }
    
    // Check if there's at least 1 degree variation (MEDIUM strictness)
    // Lowered from 10° → 5° → 2° → 1° to accommodate extremely subtle movements
    // At MEDIUM strictness, we prioritize user experience over strict anti-spoofing
    // The profile match (60%) and face consistency (55%) checks are the primary security
    // This threshold mainly prevents completely static photos (0° variation)
    final maxAngle = angles.reduce((a, b) => a > b ? a : b);
    final minAngle = angles.reduce((a, b) => a < b ? a : b);
    final variation = maxAngle - minAngle;
    
    print('[LivenessVerification] 📐 Angle variation analysis:');
    print('[LivenessVerification]    Min angle: ${minAngle.toStringAsFixed(2)}°');
    print('[LivenessVerification]    Max angle: ${maxAngle.toStringAsFixed(2)}°');
    print('[LivenessVerification]    Variation: ${variation.toStringAsFixed(2)}° (minimum required: 1°)');
    
    final hasVariation = variation > 1; // MEDIUM: At least 1 degree difference (extremely lenient)
    print('[LivenessVerification] ${hasVariation ? '✅' : '❌'} Expression variation: $hasVariation');
    print('═══════════════════════════════════════════════════════════');
    return hasVariation;
  }

  Future<void> _submitVerification() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      // Upload all verification photos to Cloudflare R2 (FREE downloads)
      final photoUrls = await R2StorageService.uploadMultipleImages(
        imageFiles: _capturedImages,
        folder: 'verification',
        userId: userId,
      );

      // Calculate average confidence
      final avgConfidence = _verificationResults
          .map((r) => r.confidence)
          .reduce((a, b) => a + b) / _verificationResults.length;

      // Update Firestore with liveness verification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isVerified': true,
        'verificationPhotoUrls': photoUrls,
        'verificationDate': Timestamp.now(),
        'verificationConfidence': avgConfidence,
        'livenessVerified': true,
        'verificationMethod': 'liveness_detection',
        'challengesCompleted': _challenges,
      });

      // If this is for profile picture verification, complete that process
      if (widget.isProfilePictureVerification) {
        await ProfilePictureVerificationService.completeProfilePictureVerification();
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error submitting verification: $e');
    }
  }

  void _resetVerification() {
    setState(() {
      _currentStep = 0;
      _capturedImages.clear();
      _verificationResults.clear();
      _isProcessing = false;
      _generateChallenges();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Verified!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              widget.isProfilePictureVerification
                  ? 'Your profile picture has been verified and updated!'
                  : 'Your profile has been verified with liveness detection!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'You now have a verified badge ✓',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              
              // If this is profile picture verification, return to profile page
              // by popping back to the root and letting ProfilePictureVerificationDialog handle it
              if (widget.isProfilePictureVerification) {
                // Pop back to the screen that opened the liveness verification
                // This will trigger the onVerificationComplete callback in ProfilePictureVerificationDialog
                Navigator.of(context).pop(true);
              } else {
                // Regular verification - return to previous screen (settings)
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _challenges.length;
    
    return WillPopScope(
      onWillPop: () async {
        // If this is profile picture verification, prevent back button entirely
        if (widget.isProfilePictureVerification) {
          print('🔴 [LivenessVerificationScreen] Back button pressed during profile picture verification');
          print('🔴 [LivenessVerificationScreen] Back button is BLOCKED - verification is mandatory');
          
          // Show a message that verification is mandatory
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification is mandatory to change your profile picture'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Return false to prevent back navigation
          return false;
        }
        
        // For regular verification, show cancel confirmation
        if (_currentStep > 0) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Verification?'),
              content: const Text('Your progress will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Liveness Verification'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // Hide back button during profile picture verification
          automaticallyImplyLeading: !widget.isProfilePictureVerification,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Mandatory verification warning for profile picture
              if (widget.isProfilePictureVerification)
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verification Required',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You must complete verification to change your profile picture',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (widget.isProfilePictureVerification)
                const SizedBox(height: 20),
              
              // Progress indicator
              FadeInDown(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentStep + 1} of ${_challenges.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Security info
              FadeInDown(
                delay: Duration(milliseconds: 200),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.orange, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anti-Spoofing Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Live camera only. No photos accepted.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Current challenge
              FadeIn(
                key: ValueKey(_currentStep),
                child: Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.face,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 20),
                      Text(
                        _challenges[_currentStep],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Follow the instruction and take a photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Capture button
              if (_isProcessing)
                Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Verifying...'),
                  ],
                )
              else
                FadeInUp(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: Icon(Icons.camera_alt, size: 28),
                    label: Text(
                      'Take Photo',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              
              SizedBox(height: 30),
              
              // Completed steps
              if (_currentStep > 0)
                FadeInUp(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 12),
                        Text(
                          '$_currentStep/${_challenges.length} challenges completed',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: 30),
              
              // Instructions
              FadeInUp(
                delay: Duration(milliseconds: 400),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildTip(Icons.camera, 'Use live camera only'),
                      _buildTip(Icons.block, 'Gallery photos will be rejected'),
                      _buildTip(Icons.wb_sunny, 'Ensure good lighting'),
                      _buildTip(Icons.face, 'Follow each challenge carefully'),
                      _buildTip(Icons.timer, 'Photos must be fresh (< 10 sec)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
