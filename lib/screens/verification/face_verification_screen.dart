import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import '../../services/face_detection_service.dart';
import '../../services/r2_storage_service.dart';
import '../../constants/app_colors.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({Key? key}) : super(key: key);

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> with AutomaticKeepAliveClientMixin {
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isProcessing = false;
  File? _selectedImage;
  ProfileVerificationResult? _verificationResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _faceDetectionService.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _verificationResult = null;
        });
        await _verifyFace(image.path);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _verificationResult = null;
        });
        await _verifyFace(image.path);
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _verifyFace(String imagePath) async {
    setState(() => _isProcessing = true);
    
    try {
      final result = await _faceDetectionService.validateProfileImage(imagePath);
      
      setState(() {
        _verificationResult = result;
        _isProcessing = false;
      });

      if (result.isValid) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Verification error: $e');
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedImage == null || _verificationResult == null || !_verificationResult!.isValid) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'User not logged in';

      // Upload verification photo to Cloudflare R2 (FREE downloads)
      final photoUrl = await R2StorageService.uploadImage(
        imageFile: _selectedImage!,
        folder: 'verification',
        userId: userId,
      );

      // Update user verification status in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isVerified': true,
        'verificationPhotoUrl': photoUrl,
        'verificationDate': Timestamp.now(),
        'verificationConfidence': _verificationResult!.confidence,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile verified successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error submitting verification: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Verified!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _verificationResult!.message,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _verificationResult!.confidence,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              'Confidence: ${(_verificationResult!.confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Verification'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.verified_user, size: 48, color: Colors.blue),
                    SizedBox(height: 12),
                    Text(
                      'Verify Your Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Take a clear photo of your face to verify your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            
            if (_selectedImage != null)
              FadeIn(
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _verificationResult?.isValid == true
                          ? Colors.green
                          : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            
            if (_verificationResult != null && !_verificationResult!.isValid)
              FadeInUp(
                child: Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _verificationResult!.message,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 30),
            
            if (_isProcessing)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing face...'),
                ],
              )
            else
              Column(
                children: [
                  FadeInUp(
                    delay: Duration(milliseconds: 200),
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FadeInUp(
                    delay: Duration(milliseconds: 400),
                    child: OutlinedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: Icon(Icons.photo_library),
                      label: Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 30),
            
            FadeInUp(
              delay: Duration(milliseconds: 600),
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
                      'Tips for best results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTip(Icons.face, 'Face the camera directly'),
                    _buildTip(Icons.wb_sunny, 'Use good lighting'),
                    _buildTip(Icons.remove_red_eye, 'Keep your eyes open'),
                    _buildTip(Icons.person, 'Only your face in frame'),
                    _buildTip(Icons.camera, 'Remove sunglasses/masks'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
