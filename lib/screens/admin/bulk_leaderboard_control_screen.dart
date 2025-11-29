import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'send_reward_dialog.dart';
import 'announce_winner_dialog.dart';

class BulkLeaderboardControlScreen extends StatefulWidget {
  const BulkLeaderboardControlScreen({Key? key}) : super(key: key);

  @override
  State<BulkLeaderboardControlScreen> createState() => _BulkLeaderboardControlScreenState();
}

class _BulkLeaderboardControlScreenState extends State<BulkLeaderboardControlScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = false;
  String _selectedGender = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
                  'Total Profiles: ${_profiles.length}',
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
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _bulkUpdateLeaderboard(100000, 500),
                      icon: const Icon(Icons.star),
                      label: const Text('Top 100K'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _bulkUpdateLeaderboard(10000, 50),
                      icon: const Icon(Icons.equalizer),
                      label: const Text('Balanced'),
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
                : _profiles.isEmpty
                    ? Center(
                        child: Text(
                          'No profiles found for $_selectedGender',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _profiles.length,
                        itemBuilder: (context, index) {
                          final profile = _profiles[index];
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
    
    final pointsController = TextEditingController();
    
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
