import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/discovery_filters.dart';
import '../../services/discovery_service.dart';
import '../../services/match_service.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/action_buttons.dart';
import '../../constants/app_colors.dart';
import 'match_dialog.dart';
import 'filters_dialog.dart';

class SwipeableDiscoveryScreen extends StatefulWidget {
  const SwipeableDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<SwipeableDiscoveryScreen> createState() => _SwipeableDiscoveryScreenState();
}

class _SwipeableDiscoveryScreenState extends State<SwipeableDiscoveryScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final MatchService _matchService = MatchService();
  
  List<UserModel> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _currentUserId;
  DiscoveryFilters _filters = DiscoveryFilters();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadProfiles();
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
        _profiles = profiles;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      setState(() => _isLoading = false);
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
      });
      _loadProfiles();
    }
  }

  Future<void> _handleSwipe(String action) async {
    if (_currentUserId == null || _currentIndex >= _profiles.length) return;
    
    final currentProfile = _profiles[_currentIndex];
    
    try {
      // Record the swipe
      await _discoveryService.recordSwipe(
        _currentUserId!,
        currentProfile.uid,
        action,
      );

      // Check for match if it's a like or superlike
      if (action == 'like' || action == 'superlike') {
        final isMatch = await _matchService.checkAndCreateMatch(
          _currentUserId!,
          currentProfile.uid,
        );

        if (isMatch && mounted) {
          // Show match dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MatchDialog(
              currentUserId: _currentUserId!,
              matchedUser: currentProfile,
            ),
          );
        }
      }

      // Move to next profile
      setState(() {
        _currentIndex++;
      });

      // Load more profiles if running low
      if (_currentIndex >= _profiles.length - 2) {
        _loadProfiles();
      }
    } catch (e) {
      debugPrint('Error handling swipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onLike() => _handleSwipe('like');
  void _onPass() => _handleSwipe('pass');
  void _onSuperLike() => _handleSwipe('superlike');

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
      body: _buildBody(),
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

    if (_currentIndex >= _profiles.length || _profiles.isEmpty) {
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
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Check back later for new profiles',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
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

          // Profile Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                child: ProfileCard(user: currentProfile),
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
