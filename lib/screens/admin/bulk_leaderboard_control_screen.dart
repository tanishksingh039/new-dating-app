import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'send_reward_dialog.dart';
import 'announce_winner_dialog.dart';

class BulkLeaderboardControlScreen extends StatefulWidget {
  const BulkLeaderboardControlScreen({Key? key}) : super(key: key);

  @override
  State<BulkLeaderboardControlScreen> createState() => _BulkLeaderboardControlScreenState();
}

class _BulkLeaderboardControlScreenState extends State<BulkLeaderboardControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _filteredProfiles = [];
  bool _isLoading = false;
  String _selectedGender = 'All';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterProfiles();
    });
  }
  
  void _filterProfiles() {
    if (_searchQuery.isEmpty) {
      _filteredProfiles = List.from(_profiles);
    } else {
      _filteredProfiles = _profiles.where((profile) {
        final name = (profile['name'] ?? '').toString().toLowerCase();
        final email = (profile['email'] ?? '').toString().toLowerCase();
        final uid = (profile['uid'] ?? '').toString().toLowerCase();
        
        return name.contains(_searchQuery) || 
               email.contains(_searchQuery) || 
               uid.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    
    try {
      Query query = _firestore.collection('users');
      
      if (_selectedGender != 'All') {
        query = query.where('gender', isEqualTo: _selectedGender);
      }
      
      final snapshot = await query.get();
      
      setState(() {
        _profiles = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          return data;
        }).toList();
        _filterProfiles();
      });
      
      debugPrint('[BulkLeaderboardControl] Loaded ${_profiles.length} profiles');
    } catch (e) {
      _showError('Error loading profiles: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileLeaderboard(
    String userId,
    int points,
    int? rank,
  ) async {
    try {
      debugPrint('[BulkLeaderboardControl] Updating leaderboard for $userId');
      debugPrint('[BulkLeaderboardControl] Points: $points, Rank: ${rank ?? "auto"}');
      
      await _firestore.collection('rewards_stats').doc(userId).set({
        'userId': userId,
        'monthlyScore': points,
        'monthlyRank': rank ?? 0,
        'weeklyScore': points ~/ 4,
        'totalScore': points,
        'currentStreak': 1,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_bulk_leaderboard',
      }, SetOptions(merge: true));
      
      debugPrint('[BulkLeaderboardControl] ✅ Updated leaderboard for $userId');
      _showSuccess('Updated $userId leaderboard');
      await _loadProfiles();
    } catch (e, stackTrace) {
      debugPrint('[BulkLeaderboardControl] ❌ Error updating leaderboard: $e');
      debugPrint('[BulkLeaderboardControl] Error type: ${e.runtimeType}');
      debugPrint('[BulkLeaderboardControl] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        debugPrint('[BulkLeaderboardControl] 🔐 PERMISSION DENIED');
        debugPrint('[BulkLeaderboardControl] ═══════════════════════════════════════');
        debugPrint('[BulkLeaderboardControl] TROUBLESHOOTING:');
        debugPrint('[BulkLeaderboardControl] 1. Check Firestore rules are published');
        debugPrint('[BulkLeaderboardControl] 2. Verify rule: allow write: if true;');
        debugPrint('[BulkLeaderboardControl] 3. Collection: rewards_stats');
        debugPrint('[BulkLeaderboardControl] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
        debugPrint('[BulkLeaderboardControl] ═══════════════════════════════════════');
      }
      
      _showError('Error updating leaderboard: $e');
    }
  }

  Future<void> _bulkUpdateLeaderboard(int basePoints, int increment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Update Leaderboard'),
        content: Text(
          'Update ${_profiles.length} profiles with points starting from $basePoints and incrementing by $increment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      int currentPoints = basePoints;
      
      debugPrint('[BulkLeaderboardControl] Starting bulk update');
      debugPrint('[BulkLeaderboardControl] Base points: $basePoints, Increment: $increment');
      debugPrint('[BulkLeaderboardControl] Total profiles: ${_profiles.length}');
      
      for (int i = 0; i < _profiles.length; i++) {
        final userId = _profiles[i]['uid'];
        final name = _profiles[i]['name'] ?? 'Unknown';
        
        debugPrint('[BulkLeaderboardControl] Updating profile $i: $name ($userId)');
        debugPrint('[BulkLeaderboardControl] Points: $currentPoints, Rank: ${i + 1}');
        
        try {
          await _firestore.collection('rewards_stats').doc(userId).set({
            'userId': userId,
            'monthlyScore': currentPoints,
            'monthlyRank': i + 1,
            'weeklyScore': currentPoints ~/ 4,
            'totalScore': currentPoints,
            'currentStreak': 1,
            'lastActivityAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': 'admin_bulk_leaderboard',
          }, SetOptions(merge: true));
          
          debugPrint('[BulkLeaderboardControl] ✅ Updated profile $i: $name');
        } catch (e) {
          debugPrint('[BulkLeaderboardControl] ❌ Error updating profile $i: $e');
          
          if (e.toString().contains('permission-denied')) {
            debugPrint('[BulkLeaderboardControl] 🔐 PERMISSION DENIED on profile $i');
            debugPrint('[BulkLeaderboardControl] Check Firestore rules for rewards_stats collection');
            rethrow;
          }
        }
        
        currentPoints -= increment;
        
        // Small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('[BulkLeaderboardControl] ✅ Bulk update completed successfully');
      _showSuccess('Updated ${_profiles.length} profiles!');
      await _loadProfiles();
    } catch (e, stackTrace) {
      debugPrint('[BulkLeaderboardControl] ❌ Bulk update error: $e');
      debugPrint('[BulkLeaderboardControl] Error type: ${e.runtimeType}');
      debugPrint('[BulkLeaderboardControl] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        debugPrint('[BulkLeaderboardControl] 🔐 PERMISSION DENIED');
        debugPrint('[BulkLeaderboardControl] ═══════════════════════════════════════');
        debugPrint('[BulkLeaderboardControl] TROUBLESHOOTING:');
        debugPrint('[BulkLeaderboardControl] 1. Check Firestore rules are published');
        debugPrint('[BulkLeaderboardControl] 2. Verify rule: allow write: if true;');
        debugPrint('[BulkLeaderboardControl] 3. Collection: rewards_stats');
        debugPrint('[BulkLeaderboardControl] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
        debugPrint('[BulkLeaderboardControl] ═══════════════════════════════════════');
      }
      
      _showError('Error updating profiles: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetLeaderboard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Leaderboard'),
        content: const Text(
          'Are you sure you want to reset the entire leaderboard? This will set all users\' points to 0 and cannot be undone.\n\nThis action affects ALL users regardless of gender filter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('[BulkLeaderboardControl] Starting leaderboard reset');
      
      // Get all documents from rewards_stats collection
      final snapshot = await _firestore.collection('rewards_stats').get();
      
      debugPrint('[BulkLeaderboardControl] Found ${snapshot.docs.length} leaderboard entries to reset');
      
      int resetCount = 0;
      for (final doc in snapshot.docs) {
        try {
          await _firestore.collection('rewards_stats').doc(doc.id).set({
            'userId': doc.id,
            'monthlyScore': 0,
            'monthlyRank': 0,
            'weeklyScore': 0,
            'totalScore': 0,
            'currentStreak': 0,
            'lastActivityAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': 'admin_leaderboard_reset',
          }, SetOptions(merge: true));
          
          resetCount++;
          debugPrint('[BulkLeaderboardControl] ✅ Reset ${doc.id} ($resetCount/${snapshot.docs.length})');
          
          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          debugPrint('[BulkLeaderboardControl] ❌ Error resetting ${doc.id}: $e');
        }
      }
      
      debugPrint('[BulkLeaderboardControl] ✅ Leaderboard reset completed: $resetCount entries reset');
      _showSuccess('Leaderboard reset! $resetCount entries set to 0 points');
      await _loadProfiles();
    } catch (e, stackTrace) {
      debugPrint('[BulkLeaderboardControl] ❌ Leaderboard reset error: $e');
      debugPrint('[BulkLeaderboardControl] Stack trace: $stackTrace');
      _showError('Error resetting leaderboard: $e');
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _updateUserName(String userId, String newName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': newName,
      });
      _showSuccess('Name updated to: $newName');
      await _loadProfiles();
    } catch (e) {
      _showError('Error updating name: $e');
    }
  }

  Future<void> _toggleVerification(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
      _showSuccess(isVerified ? 'User marked as verified' : 'User marked as unverified');
      await _loadProfiles();
    } catch (e) {
      _showError('Error updating verification: $e');
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    try {
      // Delete from users collection
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete from rewards_stats if exists
      try {
        await _firestore.collection('rewards_stats').doc(userId).delete();
      } catch (e) {
        debugPrint('No rewards_stats entry to delete: $e');
      }
      
      _showSuccess('User $userName deleted successfully');
      await _loadProfiles();
    } catch (e) {
      _showError('Error deleting user: $e');
    }
  }

  void _showDeleteConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete $userName? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(userId, userName);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeWinner(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Winner'),
        content: Text(
          'Are you sure you want to remove $userName from winner announcements?\n\nThis will delete all winner announcements for this user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('[BulkLeaderboardControl] Removing winner announcements for $userName ($userId)');
      
      // Get all winner announcements for this user
      final snapshot = await _firestore
          .collection('monthly_winners')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (snapshot.docs.isEmpty) {
        _showError('No winner announcements found for $userName');
        return;
      }
      
      debugPrint('[BulkLeaderboardControl] Found ${snapshot.docs.length} winner announcement(s) to remove');
      
      // Delete all winner announcements for this user
      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        try {
          await _firestore.collection('monthly_winners').doc(doc.id).delete();
          deletedCount++;
          debugPrint('[BulkLeaderboardControl] ✅ Deleted winner announcement: ${doc.id}');
        } catch (e) {
          debugPrint('[BulkLeaderboardControl] ❌ Error deleting announcement ${doc.id}: $e');
        }
      }
      
      debugPrint('[BulkLeaderboardControl] ✅ Removed $deletedCount winner announcement(s) for $userName');
      _showSuccess('Removed $deletedCount winner announcement(s) for $userName');
      await _loadProfiles();
    } catch (e, stackTrace) {
      debugPrint('[BulkLeaderboardControl] ❌ Error removing winner: $e');
      debugPrint('[BulkLeaderboardControl] Stack trace: $stackTrace');
      _showError('Error removing winner: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadUserPhoto(String userId, String userName) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        _showError('No image selected');
        return;
      }

      setState(() => _isLoading = true);
      
      final File imageFile = File(image.path);
      final String fileName = 'users/$userId/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      debugPrint('[BulkLeaderboardControl] Uploading photo for $userName');
      debugPrint('[BulkLeaderboardControl] File path: ${image.path}');
      debugPrint('[BulkLeaderboardControl] Storage path: $fileName');
      
      // Upload to Firebase Storage
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('[BulkLeaderboardControl] ✅ Photo uploaded: $downloadUrl');
      
      // Get current photos array
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final List<dynamic> currentPhotos = userDoc.data()?['photos'] ?? [];
      
      // Add new photo to the beginning of the array
      final List<String> updatedPhotos = [downloadUrl];
      updatedPhotos.addAll(currentPhotos.cast<String>());
      
      // Update user document with new photo
      await _firestore.collection('users').doc(userId).update({
        'photos': updatedPhotos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('[BulkLeaderboardControl] ✅ User profile updated with new photo');
      _showSuccess('Photo added for $userName!');
      await _loadProfiles();
    } catch (e) {
      debugPrint('[BulkLeaderboardControl] ❌ Error uploading photo: $e');
      _showError('Error uploading photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUserPhoto(String userId, String photoUrl, String userName) async {
    try {
      setState(() => _isLoading = true);
      
      debugPrint('[BulkLeaderboardControl] Deleting photo for $userName');
      debugPrint('[BulkLeaderboardControl] Photo URL: $photoUrl');
      
      // Delete from Firebase Storage
      try {
        final Reference ref = FirebaseStorage.instance.refFromURL(photoUrl);
        await ref.delete();
        debugPrint('[BulkLeaderboardControl] ✅ Photo deleted from storage');
      } catch (e) {
        debugPrint('[BulkLeaderboardControl] ⚠️ Could not delete from storage: $e');
      }
      
      // Remove from user's photos array
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final List<dynamic> currentPhotos = userDoc.data()?['photos'] ?? [];
      
      final List<String> updatedPhotos = currentPhotos
          .cast<String>()
          .where((photo) => photo != photoUrl)
          .toList();
      
      await _firestore.collection('users').doc(userId).update({
        'photos': updatedPhotos,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('[BulkLeaderboardControl] ✅ Photo removed from user profile');
      _showSuccess('Photo deleted for $userName!');
      await _loadProfiles();
    } catch (e) {
      debugPrint('[BulkLeaderboardControl] ❌ Error deleting photo: $e');
      _showError('Error deleting photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Leaderboard Control'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or user ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter by Gender',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Female', label: Text('Female')),
                    ButtonSegment(value: 'Male', label: Text('Male')),
                  ],
                  selected: {_selectedGender},
                  onSelectionChanged: _isLoading
                      ? null
                      : (Set<String> newSelection) {
                          setState(() => _selectedGender = newSelection.first);
                          _loadProfiles();
                        },
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Profiles: ${_profiles.length}${_searchQuery.isNotEmpty ? ' (Filtered: ${_filteredProfiles.length})' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Bulk Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bulk Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _bulkUpdateLeaderboard(50000, 100),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Top 50K'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _bulkUpdateLeaderboard(100000, 500),
                      icon: const Icon(Icons.star),
                      label: const Text('Top 100K'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _bulkUpdateLeaderboard(10000, 50),
                      icon: const Icon(Icons.equalizer),
                      label: const Text('Balanced'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _resetLeaderboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Leaderboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Profiles List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProfiles.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty 
                              ? 'No profiles found matching "$_searchQuery"'
                              : 'No profiles found for $_selectedGender',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = _filteredProfiles[index];
                          return _buildProfileCard(profile, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    final name = profile['name'] ?? 'Unknown';
    final gender = profile['gender'] ?? 'N/A';
    final uid = profile['uid'] ?? '';
    final isTestProfile = profile['isTestProfile'] ?? false;
    final isVerified = profile['isVerified'] ?? false;
    
    final pointsController = TextEditingController();
    final nameController = TextEditingController(text: name);
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _firestore.collection('rewards_stats').doc(uid).get().then((doc) => doc.data()),
      builder: (context, snapshot) {
        final currentPoints = snapshot.data?['monthlyScore'] ?? 0;
        final isOnLeaderboard = snapshot.data != null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: gender == 'Female' ? Colors.pink : Colors.blue,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$gender • $uid',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Test Profile Badge
                    if (isTestProfile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TEST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Current Points Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            currentPoints.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      if (isOnLeaderboard)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ON LEADERBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NOT ON LEADERBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Edit Points
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        decoration: InputDecoration(
                          labelText: 'New Points',
                          hintText: 'Enter points',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: const Icon(Icons.star),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final points = int.tryParse(pointsController.text);
                        if (points != null) {
                          _updateProfileLeaderboard(uid, points, index + 1);
                          pointsController.clear();
                        } else {
                          _showError('Please enter valid points');
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Send Reward Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => SendRewardDialog(
                        userId: uid,
                        userName: name,
                        userPhoto: profile['photos']?[0],
                      ),
                    );
                    
                    if (result == true) {
                      // Reward sent successfully
                      setState(() {}); // Refresh UI
                    }
                  },
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('Send Reward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Announce Winner Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => AnnounceWinnerDialog(
                        userId: uid,
                        userName: name,
                        userPhoto: profile['photos']?[0],
                        points: currentPoints,
                        rank: index + 1,
                      ),
                    );
                    
                    if (result == true) {
                      // Winner announced successfully
                      setState(() {}); // Refresh UI
                    }
                  },
                  icon: const Icon(Icons.emoji_events, size: 18),
                  label: const Text('Announce Winner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Remove Winner Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await _removeWinner(uid, name);
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Remove Winner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Display on Leaderboard Toggle
                if (isTestProfile)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (isOnLeaderboard) {
                        _removeFromLeaderboard(uid, name);
                      } else {
                        _addToLeaderboard(uid, name);
                      }
                    },
                    icon: Icon(
                      isOnLeaderboard ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(
                      isOnLeaderboard ? 'Remove from Leaderboard' : 'Add to Leaderboard',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnLeaderboard ? Colors.red : Colors.green,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Edit Name
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Edit Name',
                          hintText: 'Enter new name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          _updateUserName(uid, nameController.text.trim());
                        } else {
                          _showError('Please enter a name');
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Verified Toggle
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVerified ? Colors.blue.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVerified ? Colors.blue.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: isVerified ? Colors.blue : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isVerified ? 'Verified' : 'Not Verified',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isVerified ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isVerified,
                              onChanged: (value) {
                                _toggleVerification(uid, value);
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Upload Photo Button
                ElevatedButton.icon(
                  onPressed: () {
                    _uploadUserPhoto(uid, name);
                  },
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: const Text('Add Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Display User Photos
                if ((profile['photos'] as List?)?.isNotEmpty == true)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (profile['photos'] as List).length,
                          itemBuilder: (context, photoIndex) {
                            final photoUrl = (profile['photos'] as List)[photoIndex];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photoUrl,
                                      width: 100,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete Photo'),
                                            content: const Text(
                                              'Are you sure you want to delete this photo?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteUserPhoto(uid, photoUrl, name);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
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
                      const SizedBox(height: 12),
                    ],
                  ),
                
                // Delete User Button
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(uid, name);
                  },
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Delete User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _addToLeaderboard(String userId, String name) async {
    try {
      debugPrint('[BulkLeaderboardControl] Adding $name to leaderboard');
      
      await _firestore.collection('rewards_stats').doc(userId).set({
        'userId': userId,
        'monthlyScore': 10000,
        'monthlyRank': 0,
        'weeklyScore': 2500,
        'totalScore': 10000,
        'currentStreak': 1,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin_bulk_leaderboard',
        'displayOnLeaderboard': true,
      }, SetOptions(merge: true));
      
      debugPrint('[BulkLeaderboardControl] ✅ Added $name to leaderboard');
      _showSuccess('$name added to leaderboard with 10,000 points!');
      setState(() {}); // Refresh UI
    } catch (e) {
      debugPrint('[BulkLeaderboardControl] ❌ Error adding to leaderboard: $e');
      _showError('Error adding to leaderboard: $e');
    }
  }
  
  Future<void> _removeFromLeaderboard(String userId, String name) async {
    try {
      debugPrint('[BulkLeaderboardControl] Removing $name from leaderboard');
      
      await _firestore.collection('rewards_stats').doc(userId).delete();
      
      debugPrint('[BulkLeaderboardControl] ✅ Removed $name from leaderboard');
      _showSuccess('$name removed from leaderboard');
      setState(() {}); // Refresh UI
    } catch (e) {
      debugPrint('[BulkLeaderboardControl] ❌ Error removing from leaderboard: $e');
      _showError('Error removing from leaderboard: $e');
    }
  }
}
