import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/select_main_profile_picture_dialog.dart';
import '../../services/r2_storage_service.dart';
import '../../services/profile_picture_verification_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  late List<String> _photos;
  late List<String> _selectedInterests;
  late String _selectedGender;
  late DateTime _selectedDate;
  late Map<String, dynamic> _preferences;
  
  bool _isSaving = false;
  List<File> _newPhotos = [];
  String? _originalMainPhoto; // Track original main photo

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _bioController.text = widget.user.bio;
    _photos = List.from(widget.user.photos);
    _selectedInterests = List.from(widget.user.interests);
    _selectedGender = _normalizeGender(widget.user.gender);
    _selectedDate = widget.user.dateOfBirth ?? DateTime.now();
    _preferences = Map.from(widget.user.preferences);
    
    // Store the original main photo (first photo in the array)
    _originalMainPhoto = _photos.isNotEmpty ? _photos.first : null;
  }

  String _normalizeGender(String gender) {
    if (gender.isEmpty) return 'Male';
    final normalized = gender.toLowerCase();
    if (normalized == 'male') return 'Male';
    if (normalized == 'female') return 'Female';
    if (normalized == 'other') return 'Other';
    return 'Male'; // Default fallback
  }
  
  // Helper to normalize preference values
  String _normalizePreference(String key, String? value) {
    if (value == null || value.isEmpty) {
      if (key == 'interestedIn') return 'Male';
      if (key == 'lookingFor') return 'Long-term relationship';
      return '';
    }
    
    // For interestedIn field
    if (key == 'interestedIn') {
      final normalized = value.toLowerCase();
      if (normalized == 'male') return 'Male';
      if (normalized == 'female') return 'Female';
      return 'Male';
    }
    
    // For lookingFor field - normalize common variations
    final lookingForOptions = [
      'Long-term relationship',
      'Short-term relationship',
      'Friendship',
      'Not sure yet'
    ];
    
    // Check if value matches any option (case-insensitive)
    for (var option in lookingForOptions) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    
    return 'Long-term relationship'; // Default
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_photos.length + _newPhotos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 photos allowed')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _newPhotos.add(File(pickedFile.path));
      });
    }
  }

  Future<String> _uploadPhoto(File photo) async {
    // Upload to Cloudflare R2 (FREE downloads, auto-compression)
    final url = await R2StorageService.uploadImage(
      imageFile: photo,
      folder: 'profiles',
      userId: widget.user.uid,
    );
    return url;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty && _newPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new photos
      List<String> uploadedUrls = [];
      for (var photo in _newPhotos) {
        final url = await _uploadPhoto(photo);
        uploadedUrls.add(url);
      }

      // Combine existing and new photos
      final allPhotos = [..._photos, ...uploadedUrls];

      // Check if new photos were added - if yes, show main picture selection
      if (_newPhotos.isNotEmpty && uploadedUrls.isNotEmpty) {
        print('🔴 [EditProfileScreen] NEW PHOTOS DETECTED');
        print('🔴 [EditProfileScreen] New photos count: ${_newPhotos.length}');
        print('🔴 [EditProfileScreen] Uploaded URLs: ${uploadedUrls.length}');
        
        if (mounted) {
          setState(() => _isSaving = false);
          
          // Show main picture selection dialog
          final selectedMainIndex = await showDialog<int>(
            context: context,
            barrierDismissible: false,
            builder: (context) => SelectMainProfilePictureDialog(
              allPhotos: allPhotos,
              currentMainIndex: 0,
            ),
          );
          
          // If user cancelled, don't save
          if (selectedMainIndex == null) {
            print('🔴 [EditProfileScreen] User cancelled main picture selection');
            return;
          }
          
          print('🔴 [EditProfileScreen] Selected main picture index: $selectedMainIndex');
          
          // Reorder photos so selected one is first
          final reorderedPhotos = <String>[];
          reorderedPhotos.add(allPhotos[selectedMainIndex]);
          for (int i = 0; i < allPhotos.length; i++) {
            if (i != selectedMainIndex) {
              reorderedPhotos.add(allPhotos[i]);
            }
          }
          
          print('🔴 [EditProfileScreen] Reordered photos - main: ${reorderedPhotos.first}');
          print('🔴 [EditProfileScreen] Original main photo: $_originalMainPhoto');
          
          setState(() => _isSaving = true);
          
          // The new main picture is now at index 0
          final newMainPhotoUrl = reorderedPhotos.first;
          
          // Update Firestore with reordered photos
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .update({
            'name': _nameController.text.trim(),
            'bio': _bioController.text.trim(),
            'photos': reorderedPhotos,
            'interests': _selectedInterests,
            'gender': _selectedGender,
            'dateOfBirth': _selectedDate.toIso8601String(),
            'preferences': _preferences,
          });

          print('🔴 [EditProfileScreen] Profile updated in Firestore with reordered photos');

          // ONLY mark for verification if the main photo actually changed
          final mainPhotoChanged = newMainPhotoUrl != _originalMainPhoto;
          print('🔴 [EditProfileScreen] Main photo changed: $mainPhotoChanged');
          
          if (mainPhotoChanged) {
            // Mark the new main picture as pending verification
            await ProfilePictureVerificationService.markProfilePictureAsPending(newMainPhotoUrl);
            print('🔴 [EditProfileScreen] Picture marked as pending verification');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated! Verification required for new main photo.')),
              );
              print('🔴 [EditProfileScreen] Popping with true flag (verification needed)');
              // Return with true to indicate verification is needed
              Navigator.pop(context, true);
            }
          } else {
            // Main photo didn't change, just added photos
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
              print('🔴 [EditProfileScreen] Popping without verification (main photo unchanged)');
              Navigator.pop(context);
            }
          }
        }
      } else {
        // No new photos, just update profile normally
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'photos': allPhotos,
          'interests': _selectedInterests,
          'gender': _selectedGender,
          'dateOfBirth': _selectedDate.toIso8601String(),
          'preferences': _preferences,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotosSection(),
            const SizedBox(height: 20),
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
            _buildInterestsSection(),
            const SizedBox(height: 20),
            _buildPreferencesSection(),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Save Changes',
              onPressed: _isSaving ? null : _saveProfile,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add 2-6 photos. First photo will be your main profile picture.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _photos.length + _newPhotos.length + 1,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return _buildPhotoTile(_photos[index], index, false);
              } else if (index < _photos.length + _newPhotos.length) {
                final newPhotoIndex = index - _photos.length;
                return _buildPhotoTile(
                  _newPhotos[newPhotoIndex].path,
                  index,
                  true,
                );
              } else {
                return _buildAddPhotoButton();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(String photoPath, int index, bool isNewPhoto) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: isNewPhoto
                  ? FileImage(File(photoPath)) as ImageProvider
                  : NetworkImage(photoPath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isNewPhoto) {
                  _newPhotos.removeAt(index - _photos.length);
                } else {
                  _photos.removeAt(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 30, color: Colors.grey[600]),
            const SizedBox(height: 5),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Bio',
              prefixIcon: const Icon(Icons.edit),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              hintText: 'Tell people about yourself...',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: ['Male', 'Female', 'Other'].map((gender) {
              return DropdownMenuItem(value: gender, child: Text(gender));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedGender = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select 3-10 interests',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.interests.map((interest) {
              final isSelected = _selectedInterests.contains(interest['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest['name']);
                    } else {
                      if (_selectedInterests.length < 10) {
                        _selectedInterests.add(interest['name']!);
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pink : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.grey[400]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        interest['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        interest['name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dating Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _normalizePreference('interestedIn', _preferences['interestedIn'] as String?),
            decoration: InputDecoration(
              labelText: 'Interested in',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: ['Male', 'Female'].map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _preferences['interestedIn'] = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _normalizePreference('lookingFor', _preferences['lookingFor'] as String?),
            decoration: InputDecoration(
              labelText: 'Looking for',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: [
              'Long-term relationship',
              'Short-term relationship',
              'Friendship',
              'Not sure yet'
            ].map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _preferences['lookingFor'] = value;
              });
            },
          ),
        ],
      ),
    );
  }
}