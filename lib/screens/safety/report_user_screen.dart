import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/user_safety_service.dart';
import '../../services/r2_storage_service.dart';
import '../../widgets/custom_button.dart';

class ReportUserScreen extends StatefulWidget {
  final UserModel reportedUser;

  const ReportUserScreen({
    Key? key,
    required this.reportedUser,
  }) : super(key: key);

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  ReportReason? _selectedReason;
  bool _isSubmitting = false;
  bool _alsoBlock = false;
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );
      
      if (images.isNotEmpty && images.length + _selectedImages.length <= 5) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      } else if (images.length + _selectedImages.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 images allowed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() => _isUploadingImages = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'User not logged in';
      
      // Upload to Cloudflare R2 (FREE downloads, auto-compression)
      final uploadedUrls = await R2StorageService.uploadMultipleImages(
        imageFiles: _selectedImages,
        folder: 'reports',
        userId: currentUser.uid,
      );
      
      return uploadedUrls;
    } catch (e) {
      print('Error uploading images: $e');
      return [];
    } finally {
      setState(() => _isUploadingImages = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason and provide details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Upload evidence images first
      final List<String> evidenceUrls = await _uploadImages();

      // Submit report with evidence
      await UserSafetyService.reportUser(
        reporterId: currentUserId,
        reportedUserId: widget.reportedUser.uid,
        reportedUserName: widget.reportedUser.name,
        reportedUserPhoto: widget.reportedUser.photos.isNotEmpty ? widget.reportedUser.photos[0] : null,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
        evidenceImages: evidenceUrls,
      );

      // Also block user if requested
      if (_alsoBlock) {
        await UserSafetyService.blockUser(
          blockerId: currentUserId,
          blockedUserId: widget.reportedUser.uid,
          reason: 'Reported for ${_selectedReason!.displayName}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_alsoBlock 
                ? 'Report submitted and user blocked' 
                : 'Report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Report User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.reportedUser.photos.isNotEmpty
                        ? NetworkImage(widget.reportedUser.photos[0])
                        : null,
                    child: widget.reportedUser.photos.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporting ${widget.reportedUser.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us keep shooLuv safe',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reason selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s wrong?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...ReportReason.values.map((reason) => _buildReasonTile(reason)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide more information about this issue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.pink),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide details about the issue';
                      }
                      if (value.trim().length < 10) {
                        return 'Please provide more details (at least 10 characters)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Evidence Images
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Evidence (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectedImages.length < 5 ? _pickImages : null,
                        icon: const Icon(Icons.add_photo_alternate, size: 20),
                        label: const Text('Add Photos'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add screenshots or photos as evidence (max 5)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
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
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_isUploadingImages)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Block option
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CheckboxListTile(
                title: const Text('Also block this user'),
                subtitle: Text(
                  'You won\'t see each other on shooLuv',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _alsoBlock,
                onChanged: (value) {
                  setState(() => _alsoBlock = value ?? false);
                },
                activeColor: Colors.pink,
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            CustomButton(
              text: 'Submit Report',
              onPressed: _isSubmitting ? null : _submitReport,
              isLoading: _isSubmitting,
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Report Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Reports are reviewed by our moderation team\n'
                    '• False reports may result in account restrictions\n'
                    'Your report helps keep shooLuv safe for everyone. We take all reports seriously and will review this matter promptly.\n'
                    '• Your report is anonymous to the reported user',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonTile(ReportReason reason) {
    return RadioListTile<ReportReason>(
      title: Text(reason.displayName),
      subtitle: Text(
        reason.description,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      value: reason,
      groupValue: _selectedReason,
      onChanged: (value) {
        setState(() => _selectedReason = value);
      },
      activeColor: Colors.pink,
      contentPadding: EdgeInsets.zero,
    );
  }
}
