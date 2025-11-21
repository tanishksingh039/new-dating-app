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
import '../../constants/app_colors.dart';

class LivenessVerificationScreen extends StatefulWidget {
  const LivenessVerificationScreen({Key? key}) : super(key: key);

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
    
    setState(() => _isProcessing = true);
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera, // CAMERA ONLY - no gallery
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        // Verify it's a recent photo (anti-spoofing)
        final file = File(image.path);
        final fileStats = await file.stat();
        final now = DateTime.now();
        final timeDiff = now.difference(fileStats.modified).inSeconds;
        
        // Photo must be taken within last 10 seconds
        if (timeDiff > 10) {
          _showError('Please take a fresh photo, not from gallery!');
          setState(() => _isProcessing = false);
          return;
        }
        
        // Verify face
        final result = await _faceDetectionService.validateProfileImage(image.path);
        
        if (!result.isValid) {
          _showError(result.message);
          setState(() => _isProcessing = false);
          return;
        }
        
        // Store the image and result
        _capturedImages.add(file);
        _verificationResults.add(result);
        
        // Move to next challenge
        if (_currentStep < _challenges.length - 1) {
          setState(() {
            _currentStep++;
            _isProcessing = false;
          });
        } else {
          // All challenges completed - verify liveness
          await _verifyLiveness();
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error: $e');
    }
  }

  Future<void> _verifyLiveness() async {
    setState(() => _isProcessing = true);
    
    try {
      // Check 1: All photos must have valid faces
      if (_verificationResults.any((r) => !r.isValid)) {
        _showError('Some photos failed validation. Please try again.');
        _resetVerification();
        return;
      }
      
      // Check 2: Verify face matches profile photo
      bool matchesProfile = await _verifyProfilePhotoMatch();
      if (!matchesProfile) {
        _showError('Face doesn\'t match your profile photo. Please use the same person.');
        _resetVerification();
        return;
      }
      
      // Check 3: Verify face consistency across images
      bool facesMatch = await _verifyFaceConsistency();
      if (!facesMatch) {
        _showError('Faces don\'t match across photos. Please ensure it\'s the same person.');
        _resetVerification();
        return;
      }
      
      // Check 4: Verify different expressions/poses (anti-spoofing)
      bool hasVariation = _verifyExpressionVariation();
      if (!hasVariation) {
        _showError('Photos appear too similar. Please follow the challenges.');
        _resetVerification();
        return;
      }
      
      // All checks passed - submit verification
      await _submitVerification();
      
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Verification error: $e');
    }
  }

  Future<bool> _verifyProfilePhotoMatch() async {
    // Compare first liveness photo (straight face) with profile photo
    if (_capturedImages.isEmpty) return false;
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;
      
      // Get user's profile photo URL from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      final List<dynamic>? photos = userData?['photos'] as List<dynamic>?;
      
      if (photos == null || photos.isEmpty) {
        _showError('Please upload a profile photo first before verification.');
        return false;
      }
      
      // Get the first profile photo URL
      final profilePhotoUrl = photos.first as String;
      
      // Download profile photo to temp file for comparison
      final tempDir = await Directory.systemTemp.createTemp();
      final profilePhotoFile = File('${tempDir.path}/profile_photo.jpg');
      
      final response = await HttpClient().getUrl(Uri.parse(profilePhotoUrl));
      final bytes = await consolidateHttpClientResponseBytes(await response.close());
      await profilePhotoFile.writeAsBytes(bytes);
      
      // Compare first liveness photo (straight face) with profile photo
      final result = await _faceDetectionService.compareFaces(
        _capturedImages.first.path,  // First photo is always "Look straight at camera"
        profilePhotoFile.path,
      );
      
      // Clean up temp file
      await profilePhotoFile.delete();
      await tempDir.delete();
      
      // Require 70% similarity with profile photo
      return result.similarity > 0.7;
      
    } catch (e) {
      print('Error comparing with profile photo: $e');
      return false;
    }
  }

  Future<bool> _verifyFaceConsistency() async {
    // Compare first and last image to ensure same person
    if (_capturedImages.length < 2) return true;
    
    try {
      final result = await _faceDetectionService.compareFaces(
        _capturedImages.first.path,
        _capturedImages.last.path,
      );
      
      return result.similarity > 0.6; // 60% similarity threshold
    } catch (e) {
      return false;
    }
  }

  bool _verifyExpressionVariation() {
    // Check if there's variation in head angles or expressions
    if (_verificationResults.length < 2) return false;
    
    // Get head angles from each result
    List<double> angles = [];
    for (var result in _verificationResults) {
      if (result.face != null) {
        final angleY = result.face!.headEulerAngleY ?? 0;
        angles.add(angleY.abs());
      }
    }
    
    if (angles.isEmpty) return false;
    
    // Check if there's at least 10 degrees variation
    final maxAngle = angles.reduce((a, b) => a > b ? a : b);
    final minAngle = angles.reduce((a, b) => a < b ? a : b);
    final variation = maxAngle - minAngle;
    
    return variation > 10; // At least 10 degrees difference
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
              'Your profile has been verified with liveness detection!',
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
              Navigator.of(context).pop(true); // Return to settings with success
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
        if (_currentStep > 0) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cancel Verification?'),
              content: Text('Your progress will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Continue'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
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
          title: Text('Liveness Verification'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
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
                    SizedBox(height: 8),
                    Text(
                      'Step ${_currentStep + 1} of ${_challenges.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
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
