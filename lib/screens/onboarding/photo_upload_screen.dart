import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../../utils/constants.dart';
import '../../../widgets/custom_button.dart';
import '../../../firebase_services.dart';
import '../../constants/app_colors.dart';
import '../../services/r2_storage_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _uploadedUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PhotoUploadScreen] $message');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= AppConstants.maxPhotos) {
      _showSnackBar(
        'You can upload maximum ${AppConstants.maxPhotos} photos',
        Colors.orange,
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size
        final file = File(image.path);
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        if (fileSizeMB > AppConstants.maxPhotoSizeMB) {
          _showSnackBar(
            'Photo size must be less than ${AppConstants.maxPhotoSizeMB}MB',
            Colors.red,
          );
          return;
        }

        // If this is the first photo (main profile photo), validate face clarity
        if (_selectedImages.isEmpty) {
          final isValid = await _validateFaceClarity(image);
          if (!isValid) {
            return; // Don't add the image if face validation fails
          }
        }

        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _log('Error picking image: $e');
      _showSnackBar('Failed to pick image', Colors.red);
    }
  }

  Future<bool> _validateFaceClarity(XFile image) async {
    try {
      _log('Validating face clarity for main profile photo...');
      
      final inputImage = InputImage.fromFilePath(image.path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableClassification: true,
          minFaceSize: 0.10, // Face should be at least 10% of image (medium sensitivity)
          performanceMode: FaceDetectorMode.fast, // Fast mode for medium sensitivity
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      _log('Detected ${faces.length} face(s) in image');

      // No face detected
      if (faces.isEmpty) {
        _showFaceValidationDialog(
          title: '⚠️ No Face Detected',
          message: 'We couldn\'t detect a clear face in this photo.\n\n'
              'For verification purposes, your main profile photo must have:\n'
              '• A clear, visible face\n'
              '• Good lighting\n'
              '• Face looking at camera\n\n'
              'Please upload a different photo.',
          canProceed: false,
        );
        return false;
      }

      // Multiple faces detected
      if (faces.length > 1) {
        _showFaceValidationDialog(
          title: '⚠️ Multiple Faces Detected',
          message: 'Your main profile photo should only show your face.\n\n'
              'We detected ${faces.length} faces in this photo.\n\n'
              'Please upload a photo with only you in it for verification.',
          canProceed: false,
        );
        return false;
      }

      // Check face quality
      final face = faces.first;
      final boundingBox = face.boundingBox;
      
      // Calculate face size relative to image
      final imageFile = File(image.path);
      final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();
      
      final faceWidthRatio = boundingBox.width / imageWidth;
      final faceHeightRatio = boundingBox.height / imageHeight;
      final faceArea = faceWidthRatio * faceHeightRatio;

      _log('Face area ratio: ${(faceArea * 100).toStringAsFixed(1)}%');

      // Face too small (less than 5% of image) - Medium sensitivity
      if (faceArea < 0.05) {
        final shouldProceed = await _showFaceValidationDialog(
          title: '⚠️ Face Too Small',
          message: 'Your face appears too small in this photo.\n\n'
              'For better verification:\n'
              '• Move closer to the camera\n'
              '• Make sure your face fills more of the frame\n'
              '• Ensure good lighting\n\n'
              'You can proceed, but we recommend uploading a clearer photo.',
          canProceed: true,
        );
        return shouldProceed;
      }

      // Check head pose (if available) - Medium sensitivity
      if (face.headEulerAngleY != null && face.headEulerAngleZ != null) {
        final yaw = face.headEulerAngleY!.abs();
        final roll = face.headEulerAngleZ!.abs();
        
        _log('Head angles - Yaw: ${yaw.toStringAsFixed(1)}°, Roll: ${roll.toStringAsFixed(1)}°');

        // Face turned too much (more than 45 degrees) - Medium sensitivity
        if (yaw > 45 || roll > 45) {
          final shouldProceed = await _showFaceValidationDialog(
            title: '⚠️ Face Not Facing Camera',
            message: 'Your face should be looking directly at the camera.\n\n'
                'For best verification results:\n'
                '• Face the camera straight on\n'
                '• Keep your head level\n'
                '• Look directly at the lens\n\n'
                'You can proceed, but we recommend a clearer photo.',
            canProceed: true,
          );
          return shouldProceed;
        }
      }

      // All checks passed
      _log('✅ Face validation passed');
      _showSnackBar('✅ Great photo! Face detected clearly', Colors.green);
      return true;

    } catch (e) {
      _log('Error validating face: $e');
      // If face detection fails, allow user to proceed with warning
      final shouldProceed = await _showFaceValidationDialog(
        title: '⚠️ Unable to Validate Photo',
        message: 'We couldn\'t analyze this photo automatically.\n\n'
            'Please make sure:\n'
            '• Your face is clearly visible\n'
            '• Photo has good lighting\n'
            '• You\'re looking at the camera\n\n'
            'Do you want to use this photo?',
        canProceed: true,
      );
      return shouldProceed;
    }
  }

  Future<bool> _showFaceValidationDialog({
    required String title,
    required String message,
    required bool canProceed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (canProceed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Clear photos improve verification success',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (canProceed)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Use Anyway'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(canProceed ? 'Choose Different Photo' : 'OK, Choose Another'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadImageToStorage(XFile image, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user signed in');

    try {
      // Upload to Cloudflare R2 (FREE downloads, auto-compression)
      setState(() {
        _uploadProgress = (index / _selectedImages.length);
      });
      
      _log('Uploading image ${index + 1}/${_selectedImages.length}...');
      
      final downloadUrl = await R2StorageService.uploadImage(
        imageFile: File(image.path),
        folder: 'profiles',
        userId: user.uid,
      );
      
      setState(() {
        _uploadProgress = ((index + 1) / _selectedImages.length);
      });
      
      _log('✅ Uploaded image ${index + 1}: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _log('❌ Failed to upload image ${index + 1}: $e');
      rethrow;
    }
  }

  Future<void> _uploadPhotos() async {
    if (_selectedImages.length < AppConstants.minPhotos) {
      _showSnackBar(
        'Please select at least ${AppConstants.minPhotos} photos',
        Colors.orange,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');

      _uploadedUrls.clear();

      // Upload all images
      for (int i = 0; i < _selectedImages.length; i++) {
        final url = await _uploadImageToStorage(_selectedImages[i], i);
        _uploadedUrls.add(url);
      }

      // Save to Firestore
      await FirebaseServices.updateUserProfile(user.uid, {
        'photos': _uploadedUrls,
        'profilePhoto': _uploadedUrls.first, // First photo as profile photo
        'profileComplete': 50, // 50% complete
      });

      _log('Photos uploaded successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding/interests');
      }
    } catch (e) {
      _log('❌ Error uploading photos: $e');
      if (mounted) {
        _showSnackBar('Failed to upload photos: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress Bar & Back Button
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Add your photos',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload ${AppConstants.minPhotos}-${AppConstants.maxPhotos} photos to get more matches',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Photo Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Photo Tips',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._buildPhotoTips(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Photo Grid
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo count indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Photos',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedImages.length >= AppConstants.minPhotos
                                        ? AppConstants.successColor.withOpacity(0.1)
                                        : AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_selectedImages.length}/${AppConstants.maxPhotos}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedImages.length >= AppConstants.minPhotos
                                          ? AppConstants.successColor
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: AppConstants.maxPhotos,
                              itemBuilder: (context, index) {
                                if (index < _selectedImages.length) {
                                  return _buildPhotoCard(index);
                                } else {
                                  return _buildAddPhotoCard();
                                }
                              },
                            ),
                            
                            if (_isUploading) ...[
                              const SizedBox(height: 20),
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: AppConstants.backgroundColor,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                                style: AppConstants.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Use clear photos that show your face. First photo will be your profile picture.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Upload Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: CustomButton(
                  text: _selectedImages.length >= AppConstants.minPhotos 
                    ? 'Continue (${_selectedImages.length} photos)'
                    : 'Add ${AppConstants.minPhotos - _selectedImages.length} more photos',
                  onPressed: _isUploading ? null : (_selectedImages.length >= AppConstants.minPhotos ? _uploadPhotos : null),
                  isLoading: _isUploading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.5, // 50% - Step 5 of 10
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '5/10',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_selectedImages[index].path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (index == 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.textLight,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppConstants.textLight,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                color: AppConstants.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPhotoTips() {
    final tips = [
      '✨ Show your face clearly in the first photo',
      '📸 Use recent photos (within the last year)',
      '🌟 Smile and look approachable',
      '🚫 Avoid group photos as your main picture',
    ];

    return tips.map((tip) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        tip,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.9),
          height: 1.3,
        ),
      ),
    )).toList();
  }
}

