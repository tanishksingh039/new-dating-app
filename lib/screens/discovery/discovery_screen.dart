import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/discovery_service.dart';
import '../../services/match_service.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/action_buttons.dart';
import 'profile_detail_screen.dart';
import 'match_dialog.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final MatchService _matchService = MatchService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<UserModel> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _discoveryService.getDiscoveryProfiles(currentUserId);
      setState(() {
        _profiles = profiles;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  Future<void> _handleSwipe(String action) async {
    if (_isProcessing || _currentIndex >= _profiles.length) return;

    setState(() => _isProcessing = true);

    try {
      final targetUser = _profiles[_currentIndex];

      // Record the action
      await _discoveryService.recordSwipe(
        currentUserId,
        targetUser.uid,
        action,
      );

      // Check for match if it was a like or super like
      if (action == 'like' || action == 'superlike') {
        final isMatch = await _matchService.checkAndCreateMatch(
          currentUserId,
          targetUser.uid,
        );

        if (isMatch && mounted) {
          // Show match dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MatchDialog(matchedUser: targetUser),
          );
        }
      }

      // Move to next profile
      setState(() {
        _currentIndex++;
        _isProcessing = false;
      });

      // Load more profiles if running low
      if (_currentIndex >= _profiles.length - 2) {
        _loadMoreProfiles();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreProfiles() async {
    try {
      final newProfiles = await _discoveryService.getDiscoveryProfiles(currentUserId);
      setState(() {
        _profiles.addAll(newProfiles);
      });
    } catch (e) {
      debugPrint('Error loading more profiles: $e');
    }
  }

  void _openProfileDetail() {
    if (_currentIndex >= _profiles.length) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          user: _profiles[_currentIndex],
          onLike: () => _handleSwipe('like'),
          onPass: () => _handleSwipe('pass'),
          onSuperLike: () => _handleSwipe('superlike'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/logo.png',
          height: 30,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Dating App',
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.grey),
            onPressed: () {
              // TODO: Open filters
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No more profiles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Check back later for new people',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Profile cards stack
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Stack(
              children: [
                // Show next 2 cards in background
                if (_currentIndex + 2 < _profiles.length)
                  _buildCardPreview(_profiles[_currentIndex + 2], 2),
                if (_currentIndex + 1 < _profiles.length)
                  _buildCardPreview(_profiles[_currentIndex + 1], 1),
                // Current card
                _buildCurrentCard(_profiles[_currentIndex]),
              ],
            ),
          ),
        ),

        // Action buttons at bottom
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: ActionButtons(
            onPass: () => _handleSwipe('pass'),
            onSuperLike: () => _handleSwipe('superlike'),
            onLike: () => _handleSwipe('like'),
            isProcessing: _isProcessing,
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreview(UserModel user, int offset) {
    return Positioned(
      top: offset * 10.0,
      left: offset * 5.0,
      right: offset * 5.0,
      bottom: offset * 10.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard(UserModel user) {
    return GestureDetector(
      onTap: _openProfileDetail,
      child: Dismissible(
        key: Key(user.uid),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            _handleSwipe('like');
          } else {
            _handleSwipe('pass');
          }
        },
        background: _buildSwipeBackground(Colors.green, Icons.favorite, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Colors.red, Icons.close, Alignment.centerRight),
        child: ProfileCard(user: user),
      ),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 80, color: Colors.white),
    );
  }
}