import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class BulkProfileCreatorScreen extends StatefulWidget {
  const BulkProfileCreatorScreen({Key? key}) : super(key: key);

  @override
  State<BulkProfileCreatorScreen> createState() => _BulkProfileCreatorScreenState();
}

class _BulkProfileCreatorScreenState extends State<BulkProfileCreatorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final TextEditingController _countController = TextEditingController(text: '10');
  bool _isCreating = false;
  int _createdCount = 0;
  int _totalCount = 0;
  String _selectedGender = 'Mixed';
  
  final List<String> _maleNames = [
    'Rahul', 'Arjun', 'Rohan', 'Aarav', 'Vihaan', 'Aditya', 'Aryan', 'Sai',
    'Shaurya', 'Reyansh', 'Ayaan', 'Arnav', 'Vivaan', 'Aayan', 'Krishna',
    'Ishaan', 'Shiv', 'Atharv', 'Advait', 'Pranav'
  ];
  
  final List<String> _femaleNames = [
    'Priya', 'Ananya', 'Aadhya', 'Saanvi', 'Kiara', 'Diya', 'Pari', 'Navya',
    'Anika', 'Sara', 'Myra', 'Aaradhya', 'Avni', 'Riya', 'Ishita', 'Anvi',
    'Kavya', 'Zara', 'Shanaya', 'Tara'
  ];
  
  final List<String> _interests = [
    'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
    'Photography', 'Art', 'Dancing', 'Fitness', 'Gaming', 'Fashion'
  ];
  
  final List<String> _bios = [
    'Love to travel and explore new places 🌍',
    'Foodie | Music Lover | Adventure Seeker',
    'Living life one day at a time ✨',
    'Passionate about fitness and wellness 💪',
    'Coffee addict ☕ | Book lover 📚',
    'Making memories around the world 🌏',
    'Dance like nobody\'s watching 💃',
    'Fitness enthusiast | Healthy lifestyle',
    'Art lover | Creative soul 🎨',
    'Music is my therapy 🎵',
  ];

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _createBulkProfiles() async {
    final count = int.tryParse(_countController.text) ?? 0;
    
    if (count <= 0 || count > 100) {
      _showError('Please enter a number between 1 and 100');
      return;
    }

    setState(() {
      _isCreating = true;
      _createdCount = 0;
      _totalCount = count;
    });

    try {
      for (int i = 0; i < count; i++) {
        await _createSingleProfile();
        setState(() {
          _createdCount = i + 1;
        });
        
        // Small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _showSuccess('Successfully created $count profiles!');
    } catch (e) {
      _showError('Error creating profiles: $e');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _createSingleProfile() async {
    final random = Random();
    
    try {
      // Determine gender
      String gender;
      List<String> nameList;
      
      if (_selectedGender == 'Mixed') {
        gender = random.nextBool() ? 'Female' : 'Male';
      } else {
        gender = _selectedGender;
      }
      
      nameList = gender == 'Female' ? _femaleNames : _maleNames;
      
      // Generate random data
      final name = nameList[random.nextInt(nameList.length)] + ' ${random.nextInt(9999)}';
      final age = 18 + random.nextInt(15); // 18-32 years old
      final dateOfBirth = DateTime.now().subtract(Duration(days: age * 365));
      final phoneNumber = '${random.nextInt(900000000) + 100000000}';
      final bio = _bios[random.nextInt(_bios.length)];
      
      // Random interests (3-5 interests)
      final interestCount = 3 + random.nextInt(3);
      final shuffledInterests = List<String>.from(_interests)..shuffle();
      final selectedInterests = shuffledInterests.take(interestCount).toList();
      
      // Generate unique user ID
      final userId = 'test_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}';
      
      debugPrint('[BulkProfileCreator] Creating profile: $name ($gender)');
      debugPrint('[BulkProfileCreator] User ID: $userId');
      
      // Create user document
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'bio': bio,
        'interests': selectedInterests,
        'photos': [], // Empty photos array
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': false,
        'isPremium': false,
        'isVerified': false,
        'accountStatus': 'active',
        'createdBy': 'admin_bulk_creator',
        'isTestProfile': true, // Mark as test profile
      });
      
      debugPrint('[BulkProfileCreator] ✅ Created profile: $name ($gender)');
    } catch (e, stackTrace) {
      debugPrint('[BulkProfileCreator] ❌ Error creating profile: $e');
      debugPrint('[BulkProfileCreator] Error type: ${e.runtimeType}');
      debugPrint('[BulkProfileCreator] Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        debugPrint('[BulkProfileCreator] 🔐 PERMISSION DENIED');
        debugPrint('[BulkProfileCreator] ═══════════════════════════════════════');
        debugPrint('[BulkProfileCreator] TROUBLESHOOTING:');
        debugPrint('[BulkProfileCreator] 1. Check Firestore rules are published');
        debugPrint('[BulkProfileCreator] 2. Verify rule: allow create: if true;');
        debugPrint('[BulkProfileCreator] 3. Collection: users');
        debugPrint('[BulkProfileCreator] 4. Copy rules from FIRESTORE_RULES_ADMIN_BYPASS.txt');
        debugPrint('[BulkProfileCreator] ═══════════════════════════════════════');
      }
      
      rethrow;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Profile Creator'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create multiple test profiles at once. Perfect for testing and demo purposes.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Number of Profiles
            const Text(
              'Number of Profiles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countController,
              decoration: InputDecoration(
                hintText: 'Enter number (1-100)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isCreating,
            ),
            const SizedBox(height: 24),

            // Gender Selection
            const Text(
              'Gender Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Mixed',
                  label: Text('Mixed'),
                  icon: Icon(Icons.people),
                ),
                ButtonSegment(
                  value: 'Female',
                  label: Text('Female'),
                  icon: Icon(Icons.female),
                ),
                ButtonSegment(
                  value: 'Male',
                  label: Text('Male'),
                  icon: Icon(Icons.male),
                ),
              ],
              selected: {_selectedGender},
              onSelectionChanged: _isCreating
                  ? null
                  : (Set<String> newSelection) {
                      setState(() {
                        _selectedGender = newSelection.first;
                      });
                    },
            ),
            const SizedBox(height: 24),

            // Profile Features
            const Text(
              'Generated Profile Features',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.person, 'Random names from Indian database'),
            _buildFeatureItem(Icons.cake, 'Age between 18-32 years'),
            _buildFeatureItem(Icons.phone, 'Random phone numbers'),
            _buildFeatureItem(Icons.favorite, '3-5 random interests'),
            _buildFeatureItem(Icons.description, 'Random bio descriptions'),
            _buildFeatureItem(Icons.label, 'Marked as test profiles'),
            const SizedBox(height: 24),

            // Progress Indicator
            if (_isCreating) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Creating Profiles...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalCount > 0 ? _createdCount / _totalCount : 0,
                      backgroundColor: Colors.purple.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_createdCount / $_totalCount profiles created',
                      style: TextStyle(color: Colors.purple.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createBulkProfiles,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.group_add),
                label: Text(
                  _isCreating ? 'Creating Profiles...' : 'Create Profiles',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
