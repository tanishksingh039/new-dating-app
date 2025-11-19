import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/discovery_filters.dart';
import '../../services/discovery_service.dart';
import '../../services/match_service.dart';
import '../../services/swipe_limit_service.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/animated_card.dart'; // Import TinderSwipeCard
import '../../widgets/swipe_limit_indicator.dart';
import '../../widgets/purchase_swipes_dialog.dart';
import '../../constants/app_colors.dart';
import '../../mixins/screenshot_protection_mixin.dart';
import 'match_dialog.dart';
import 'filters_dialog.dart';

class SwipeableDiscoveryScreen extends StatefulWidget {
  const SwipeableDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<SwipeableDiscoveryScreen> createState() => _SwipeableDiscoveryScreenState();
}

class _SwipeableDiscoveryScreenState extends State<SwipeableDiscoveryScreen> 
    with ScreenshotProtectionMixin {
  final DiscoveryService _discoveryService = DiscoveryService();
  final MatchService _matchService = MatchService();
  final SwipeLimitService _swipeLimitService = SwipeLimitService();
  
  List<UserModel> _profiles = [];
  List<UserModel> _allProfiles = []; // Store all loaded profiles for looping
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _currentUserId;
  DiscoveryFilters _filters = DiscoveryFilters();
  Set<String> _swipedProfileIds = {}; // Track swiped profiles in current session
  bool _isCurrentUserVerified = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _checkUserVerification();
    _loadProfiles();
  }

  // Check if current user is verified and premium status
  Future<void> _checkUserVerification() async {
    if (_currentUserId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        final isVerified = userData?['isVerified'] ?? false;
        final isPremium = userData?['isPremium'] ?? false;
        
        setState(() {
          _isCurrentUserVerified = isVerified;
          _isPremium = isPremium;
        });
        
        debugPrint('User verified status: $_isCurrentUserVerified');
        debugPrint('User premium status: $_isPremium');
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
    }
  }

  // Show verification required dialog
  void _showVerificationDialog() {
    debugPrint('🔔 Opening verification dialog...');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.verified_user, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Get Verified!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Verify your account to unlock rewards!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Benefits of verification:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _VerificationBenefit(text: '✅ Earn points for messages'),
            _VerificationBenefit(text: '✅ Earn 30 points per image'),
            _VerificationBenefit(text: '✅ Appear on leaderboard'),
            _VerificationBenefit(text: '✅ Build trust with matches'),
            _VerificationBenefit(text: '✅ Stand out in discovery'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to liveness verification
              Navigator.pushNamed(context, '/settings/verification');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Verify Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Show purchase swipes dialog for both premium and non-premium users when swipes reach zero
  void _showPurchaseSwipesDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (context) => PurchaseSwipesDialog(isPremium: _isPremium),
    );
  }

  Future<void> _loadProfiles() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final profiles = await _discoveryService.getDiscoveryProfiles(
        _currentUserId!,
        filters: _filters,
      );
      
      setState(() {
        if (_allProfiles.isEmpty) {
          // First load - store all profiles
          _allProfiles = List.from(profiles);
          _profiles = List.from(profiles);
          
          // If no new profiles, try to get all users (for infinite loop)
          if (_profiles.isEmpty) {
            debugPrint('No new profiles found, will load all available profiles');
            _loadAllAvailableProfiles();
            return;
          }
        } else {
          // Add new profiles to the pool
          for (var profile in profiles) {
            if (!_allProfiles.any((p) => p.uid == profile.uid)) {
              _allProfiles.add(profile);
            }
          }
          _profiles = List.from(_allProfiles);
          
          // If still no profiles, load all available
          if (_profiles.isEmpty) {
            debugPrint('Profile pool empty, loading all available profiles');
            _loadAllAvailableProfiles();
            return;
          }
        }
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      setState(() => _isLoading = false);
    }
  }
  
  // Load all available profiles without swipe history filtering
  Future<void> _loadAllAvailableProfiles() async {
    if (_currentUserId == null) return;
    
    try {
      // Get current user's data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (!currentUserDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }
      
      final currentUser = UserModel.fromMap(currentUserDoc.data()!);
      final prefs = currentUser.preferences;
      
      // Build query
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: _currentUserId);
      
      // Filter by interested in gender
      if (prefs['interestedIn'] != null && 
          prefs['interestedIn'] != 'Everyone' && 
          prefs['interestedIn'] != '') {
        query = query.where('gender', isEqualTo: prefs['interestedIn']);
      }
      
      final snapshot = await query.limit(100).get();
      
      List<UserModel> profiles = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data);
          
          // Only check onboarding and basic requirements
          final isOnboardingComplete = data['onboardingCompleted'] == true || 
                                       data['isOnboardingComplete'] == true;
          if (!isOnboardingComplete) continue;
          if (user.dateOfBirth == null) continue;
          if (user.photos.isEmpty) continue;
          
          // Apply age filter
          int minAge = 18;
          int maxAge = 100;
          if (_filters.minAge > 0) minAge = _filters.minAge;
          if (_filters.maxAge > 0) maxAge = _filters.maxAge;
          
          final userAge = _calculateAge(user.dateOfBirth!);
          if (userAge < minAge || userAge > maxAge) continue;
          
          profiles.add(user);
        } catch (e) {
          continue;
        }
      }
      
      profiles.shuffle();
      
      setState(() {
        _allProfiles = profiles;
        _profiles = List.from(profiles);
        _currentIndex = 0;
        _isLoading = false;
      });
      
      debugPrint('Loaded ${profiles.length} profiles for infinite loop');
    } catch (e) {
      debugPrint('Error loading all profiles: $e');
      setState(() => _isLoading = false);
    }
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

  // Load more profiles in background without showing loading indicator
  Future<void> _loadMoreProfilesInBackground() async {
    if (_currentUserId == null || _isLoading) return;
    
    try {
      final profiles = await _discoveryService.getDiscoveryProfiles(
        _currentUserId!,
        filters: _filters,
      );
      
      if (mounted) {
        setState(() {
          // Add new unique profiles to the pool
          for (var profile in profiles) {
            if (!_allProfiles.any((p) => p.uid == profile.uid)) {
              _allProfiles.add(profile);
              _profiles.add(profile);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading more profiles: $e');
    }
  }

  Future<void> _refreshProfiles() async {
    setState(() {
      _allProfiles.clear();
      _swipedProfileIds.clear();
      _currentIndex = 0;
    });
    await _loadProfiles();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profiles refreshed!'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _openFiltersDialog() async {
    final result = await showDialog<DiscoveryFilters>(
      context: context,
      builder: (context) => FiltersDialog(currentFilters: _filters),
    );

    if (result != null) {
      setState(() {
        _filters = result;
        _allProfiles.clear(); // Clear cache when filters change
        _swipedProfileIds.clear();
      });
      _loadProfiles();
    }
  }

  Future<void> _handleSwipe(String action) async {
    if (_currentUserId == null || _currentIndex >= _profiles.length) return;
    
    // Check swipe limit BEFORE swiping
    final canSwipe = await _swipeLimitService.canSwipe();
    if (!canSwipe) {
      // Show purchase dialog for BOTH premium and non-premium users when swipes reach zero
      _showPurchaseSwipesDialog();
      return;
    }
    
    final currentProfile = _profiles[_currentIndex];
    
    // Use a swipe
    final swipeUsed = await _swipeLimitService.useSwipe();
    if (!swipeUsed) {
      // Swipe limit reached, show purchase dialog for BOTH premium and non-premium users
      _showPurchaseSwipesDialog();
      return;
    }
    
    // Track swiped profile
    _swipedProfileIds.add(currentProfile.uid);

    // Show verification popup on like (right swipe) if not verified AND non-premium
    if (action == 'like' && !_isCurrentUserVerified && !_isPremium) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showVerificationDialog();
        }
      });
    }

    // Move to next profile IMMEDIATELY for smooth UX
    setState(() {
      _currentIndex++;
      
      // Loop back to start if we've reached the end
      if (_currentIndex >= _profiles.length) {
        _currentIndex = 0;
        // Reset swiped tracking after full cycle
        _swipedProfileIds.clear();
      }
    });

    // Load more profiles in background if running low
    if (_currentIndex >= _profiles.length - 3 && !_isLoading) {
      _loadMoreProfilesInBackground();
    }

    // Do all async operations in background (non-blocking)
    _processSwipeInBackground(currentProfile, action);
  }

  // Process swipe operations in background without blocking UI
  Future<void> _processSwipeInBackground(UserModel profile, String action) async {
    try {
      // Record the swipe
      await _discoveryService.recordSwipe(
        _currentUserId!,
        profile.uid,
        action,
      );

      // Check for match if it's a like or superlike
      if (action == 'like' || action == 'superlike') {
        final isMatch = await _matchService.checkAndCreateMatch(
          _currentUserId!,
          profile.uid,
        );

        if (isMatch && mounted) {
          // Show match dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MatchDialog(
              currentUserId: _currentUserId!,
              matchedUser: profile,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing swipe in background: $e');
      // Don't show error to user - it's in background
    }
  }

  void _onLike() {
    // Directly handle swipe for instant response
    _handleSwipe('like');
  }
  
  void _onPass() {
    // Directly handle swipe for instant response
    _handleSwipe('pass');
  }
  
  void _onSuperLike() {
    // Directly handle swipe for instant response
    _handleSwipe('superlike');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Swipe limit indicator
          SwipeLimitIndicator(),
          const SizedBox(width: 8),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
                onPressed: _openFiltersDialog,
              ),
              if (_filters.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfiles,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Please sign in to discover profiles'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    // This should rarely happen now with infinite looping
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No profiles found",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or check back later',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentProfile = _profiles[_currentIndex];

    return SafeArea(
      child: Column(
        children: [
          // Swipe progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _profiles.isEmpty ? 0 : (_currentIndex / _profiles.length),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_currentIndex + 1}/${_profiles.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Active filters indicator
          if (_filters.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B9D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Color(0xFFFF6B9D),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Filters active',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _filters = DiscoveryFilters();
                        });
                        _loadProfiles();
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Swipeable Profile Card Stack
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Background card (next profile) for depth effect
                  if (_currentIndex + 1 < _profiles.length)
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 0.95,
                        child: Opacity(
                          opacity: 0.5,
                          child: ProfileCard(
                            user: _profiles[_currentIndex + 1],
                            enablePhotoCarousel: false, // Disable carousel for background card
                          ),
                        ),
                      ),
                    ),
                  
                  // Main swipeable card
                  Positioned.fill(
                    child: TinderSwipeCard(
                      key: ValueKey('${currentProfile.uid}_$_currentIndex'), // Unique key for each card
                      onSwipeLeft: () => _handleSwipe('pass'),
                      onSwipeRight: () => _handleSwipe('like'),
                      onSwipeUp: () => _handleSwipe('superlike'),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to detailed profile view
                          Navigator.pushNamed(
                            context,
                            '/profile-detail',
                            arguments: {
                              'user': currentProfile,
                              'onLike': _onLike,
                              'onPass': _onPass,
                              'onSuperLike': _onSuperLike,
                            },
                          );
                        },
                        child: ProfileCard(
                          key: ValueKey(currentProfile.uid), // Unique key for ProfileCard
                          user: currentProfile,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ActionButtons(
              onPass: _onPass,
              onLike: _onLike,
              onSuperLike: _onSuperLike,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for verification benefits
class _VerificationBenefit extends StatelessWidget {
  final String text;
  
  const _VerificationBenefit({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
