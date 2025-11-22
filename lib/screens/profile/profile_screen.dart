import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/match_service.dart';
import '../../widgets/spotlight_status_widget.dart';
import '../../providers/appearance_provider.dart';
import 'edit_profile_screen.dart';
import 'profile_preview_screen.dart';
import '../settings/settings_screen.dart';
import '../payment/payment_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final String currentUserId;
  final MatchService _matchService = MatchService();
  
  UserModel? _currentUser;
  Map<String, int> _stats = {};
  bool _isLoading = true;
  int _profileCompletion = 0;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        _currentUser = UserModel.fromMap(userDoc.data()!);
        
        // Load statistics
        _stats = await _matchService.getMatchStats(currentUserId);
        
        // Calculate profile completion
        if (_currentUser != null) {
          _profileCompletion = _calculateProfileCompletion(_currentUser!);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile refreshed!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.pink,
        ),
      );
    }
  }

  int _calculateProfileCompletion(UserModel user) {
    int completed = 0;
    int total = 7;

    if (user.name.isNotEmpty) completed++;
    if (user.dateOfBirth != null) completed++;
    if (user.gender.isNotEmpty) completed++;
    if (user.photos.length >= 2) completed++;
    if (user.interests.length >= 3) completed++;
    if (user.bio.isNotEmpty) completed++;
    if (user.preferences.isNotEmpty) completed++;

    return ((completed / total) * 100).round();
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppearanceProvider>(
      builder: (context, appearanceProvider, child) {
        return Scaffold(
          backgroundColor: appearanceProvider.surfaceColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              color: Colors.pink,
              child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 10),
                      const SpotlightStatusWidget(),
                      _buildStatsSection(),
                      const SizedBox(height: 10),
                      _buildCompletionSection(),
                      const SizedBox(height: 10),
                      _buildQuickActions(),
                      const SizedBox(height: 10),
                      _buildProfilePreview(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.pink,
      flexibleSpace: FlexibleSpaceBar(
        background: _currentUser?.photos.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: _currentUser!.photos[0],
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.pink[300],
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _loadUserData());
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final age = _currentUser?.dateOfBirth != null
        ? _calculateAge(_currentUser!.dateOfBirth!)
        : 0;

    return Consumer<AppearanceProvider>(
      builder: (context, appearanceProvider, child) {
        return Container(
          color: appearanceProvider.backgroundColor,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _currentUser?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              ', $age',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (_currentUser?.isVerified == true) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified, color: Colors.blue, size: 24),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_currentUser?.isPremium == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber[700]!, Colors.orange[600]!],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Premium Member',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(user: _currentUser!),
                        ),
                      ).then((_) => _loadUserData());
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Consumer<AppearanceProvider>(
      builder: (context, appearanceProvider, child) {
        return Container(
          color: appearanceProvider.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                Icons.favorite,
                '${_stats['matches'] ?? 0}',
                'Matches',
                Colors.pink,
              ),
              _buildStatItem(
                Icons.thumb_up,
                '${_stats['likes'] ?? 0}',
                'Likes Sent',
                Colors.green,
              ),
              _buildStatItem(
                Icons.visibility,
                '${_stats['receivedLikes'] ?? 0}',
                'Likes Received',
                Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_profileCompletion%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _profileCompletion == 100 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _profileCompletion / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _profileCompletion == 100 ? Colors.green : Colors.orange,
              ),
            ),
          ),
          if (_profileCompletion < 100) ...[
            const SizedBox(height: 12),
            Text(
              'Complete your profile to get more matches!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildActionTile(
            Icons.remove_red_eye,
            'Preview Profile',
            'See how others view your profile',
            () {
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePreviewScreen(
                      user: _currentUser!,
                    ),
                  ),
                );
              }
            },
          ),
          _buildVerificationTile(),
          if (_currentUser?.isPremium != true)
            _buildActionTile(
              Icons.star,
              'Upgrade to Premium',
              'Unlock exclusive features',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentScreen(),
                  ),
                );
              },
              trailingColor: Colors.amber[700],
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationTile() {
    final isVerified = _currentUser?.isVerified == true;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isVerified 
              ? Colors.green.withOpacity(0.1) 
              : Colors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isVerified ? Icons.verified : Icons.verified_user,
          color: isVerified ? Colors.green : Colors.pink,
        ),
      ),
      title: Text(
        isVerified ? 'Verified' : 'Get Verified',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isVerified ? 'Your profile is verified ✓' : 'Verify your profile',
        style: TextStyle(
          fontSize: 12,
          color: isVerified ? Colors.green[700] : Colors.grey[600],
        ),
      ),
      trailing: isVerified
          ? Icon(Icons.check_circle, color: Colors.green, size: 24)
          : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: isVerified
          ? null // Make it non-clickable when verified
          : () {
              // Navigate to liveness verification in settings
              Navigator.pushNamed(context, '/settings/verification');
            },
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? trailingColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.pink),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: trailingColor ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildProfilePreview() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with preview button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.purple.shade400],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'See how others view your profile',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Preview content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Photos preview
                  if (_currentUser?.photos.isNotEmpty == true) ...[
                    Row(
                      children: [
                        const Icon(Icons.photo_library, size: 18, color: Colors.pink),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentUser!.photos.length} Photos',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentUser!.photos.length > 4 ? 4 : _currentUser!.photos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _currentUser!.photos[index],
                                    fit: BoxFit.cover,
                                  ),
                                  if (index == 3 && _currentUser!.photos.length > 4)
                                    Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Text(
                                          '+${_currentUser!.photos.length - 4}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bio preview
                  if (_currentUser?.bio.isNotEmpty == true) ...[
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.pink),
                        const SizedBox(width: 8),
                        const Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser!.bio.length > 100
                          ? '${_currentUser!.bio.substring(0, 100)}...'
                          : _currentUser!.bio,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Interests preview
                  if (_currentUser?.interests.isNotEmpty == true) ...[
                    Row(
                      children: [
                        const Icon(Icons.favorite_outline, size: 18, color: Colors.pink),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentUser!.interests.length} Interests',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentUser!.interests.take(5).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.pink.withOpacity(0.3)),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(fontSize: 13, color: Colors.pink),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_currentUser!.interests.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${_currentUser!.interests.length - 5} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // View full profile button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePreviewScreen(user: _currentUser!),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'View Full Profile Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAppearanceSection() {
    return Consumer<AppearanceProvider>(
      builder: (context, appearanceProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appearanceProvider.cardBackgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      appearanceProvider.isDarkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appearanceProvider.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: appearanceProvider.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appearanceProvider.isDarkModeEnabled 
                            ? 'Dark backgrounds enabled' 
                            : 'Light backgrounds enabled',
                        style: TextStyle(
                          fontSize: 14,
                          color: appearanceProvider.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: appearanceProvider.isDarkModeEnabled,
                      onChanged: (_) => appearanceProvider.toggleDarkMode(),
                      activeColor: Colors.purple,
                      activeTrackColor: Colors.purple.shade200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dark mode only affects white backgrounds. Your brand colors remain unchanged.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}