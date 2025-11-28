import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/admin_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bulk_profile_creator_screen.dart';

class AdminProfileManagerScreen extends StatefulWidget {
  final String adminUserId;

  const AdminProfileManagerScreen({
    Key? key,
    required this.adminUserId,
  }) : super(key: key);

  @override
  State<AdminProfileManagerScreen> createState() => _AdminProfileManagerScreenState();
}

class _AdminProfileManagerScreenState extends State<AdminProfileManagerScreen> {
  final AdminProfileService _adminService = AdminProfileService();
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  List<String> _photoUrls = [];
  List<File> _newPhotos = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String _selectedGender = 'Female';
  DateTime? _dateOfBirth;
  List<String> _interests = [];

  final List<String> _availableInterests = [
    'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
    'Photography', 'Art', 'Dancing', 'Fitness', 'Gaming', 'Fashion'
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _adminService.getAdminProfile(widget.adminUserId);
      
      if (profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _phoneController.text = profile['phoneNumber'] ?? '';
          _photoUrls = List<String>.from(profile['photos'] ?? []);
          _selectedGender = profile['gender'] ?? 'Female';
          _interests = List<String>.from(profile['interests'] ?? []);
          
          if (profile['dateOfBirth'] != null) {
            _dateOfBirth = (profile['dateOfBirth'] as Timestamp).toDate();
          }
        });
      }
    } catch (e) {
      _showError('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Name is required');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('Phone number is required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new photos
      List<String> uploadedUrls = [];
      for (var photo in _newPhotos) {
        final url = await _adminService.uploadAdminPhoto(photo, widget.adminUserId);
        uploadedUrls.add(url);
      }

      // Combine with existing photos
      final allPhotos = [..._photoUrls, ...uploadedUrls];

      // Create or update admin profile
      await _adminService.createAdminUser(
        userId: widget.adminUserId,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrls: allPhotos,
        bio: _bioController.text.trim(),
        interests: _interests,
        dateOfBirth: _dateOfBirth,
        gender: _selectedGender,
      );

      _showSuccess('Profile saved successfully!');
      
      // Clear new photos
      setState(() {
        _newPhotos.clear();
        _photoUrls = allPhotos;
      });
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePhoto(String photoUrl) async {
    try {
      await _adminService.deleteAdminPhoto(photoUrl);
      setState(() {
        _photoUrls.remove(photoUrl);
      });
      _showSuccess('Photo deleted');
    } catch (e) {
      _showError('Error deleting photo: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BulkProfileCreatorScreen(),
                ),
              );
            },
            tooltip: 'Create Multiple Profiles',
          ),
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin ID Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin Profile',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                widget.adminUserId,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BYPASS ENABLED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photos Section
                  const Text(
                    'Profile Photos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload any photos without verification. No restrictions.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Existing photos
                        ..._photoUrls.map((url) => _buildPhotoCard(url, isUploaded: true)),
                        // New photos
                        ..._newPhotos.map((file) => _buildNewPhotoCard(file)),
                        // Add photo button
                        _buildAddPhotoButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Gender Selection
                  const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Female'),
                          value: 'Female',
                          groupValue: _selectedGender,
                          onChanged: (value) => setState(() => _selectedGender = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Male'),
                          value: 'Male',
                          groupValue: _selectedGender,
                          onChanged: (value) => setState(() => _selectedGender = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bio Field
                  TextField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.edit),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Interests
                  const Text('Interests', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _interests.contains(interest);
                        return FilterChip(
                          label: Text(
                            interest,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(interest);
                              } else {
                                _interests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoCard(String url, {required bool isUploaded}) {
    return Container(
      width: 100,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => _deletePhoto(url),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPhotoCard(File file) {
    return Container(
      width: 100,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _newPhotos.remove(file);
                });
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
