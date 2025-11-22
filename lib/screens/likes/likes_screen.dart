import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../services/match_service.dart';
import '../../utils/firestore_extensions.dart';
import '../../firebase_services.dart';
import '../chat/chat_screen.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({Key? key}) : super(key: key);

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final MatchService _matchService = MatchService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Likes',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B9D),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6B9D),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Who Likes You'),
            Tab(text: 'You Liked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWhoLikesYou(),
          _buildYouLiked(),
        ],
      ),
    );
  }

  Widget _buildWhoLikesYou() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('receivedLikes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final likes = snapshot.data?.docs ?? [];

        if (likes.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFFFF6B9D),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _buildEmptyState(
                      icon: Icons.favorite_border,
                      title: 'No likes yet',
                      subtitle: 'Keep swiping to find your matches!',
                    ),
                  ),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: const Color(0xFFFF6B9D),
          child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final likeData = likes[index].safeData();
            if (likeData == null) return const SizedBox.shrink();
            final userId = likeData['userId'] as String?;
            if (userId == null) return const SizedBox.shrink();

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B9D),
                    ),
                  );
                }

                final userData = userSnapshot.data?.safeData();
                if (userData == null) return const SizedBox.shrink();

                final user = UserModel.fromMap(userData);
                return _buildUserCard(user, showLikeBackButton: true);
              },
            );
          },
        ),
        );
      },
    );
  }

  Widget _buildYouLiked() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('likes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final likes = snapshot.data?.docs ?? [];

        if (likes.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Trigger rebuild
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: const Color(0xFFFF6B9D),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: _buildEmptyState(
                      icon: Icons.favorite,
                      title: 'No likes sent',
                      subtitle: 'Start swiping to like people!',
                    ),
                  ),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: const Color(0xFFFF6B9D),
          child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final likeData = likes[index].safeData();
            if (likeData == null) return const SizedBox.shrink();
            final userId = likes[index].id;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B9D),
                    ),
                  );
                }

                final userData = userSnapshot.data?.safeData();
                if (userData == null) return const SizedBox.shrink();

                final user = UserModel.fromMap(userData);
                return _buildUserCard(user, showLikeBackButton: false);
              },
            );
          },
        ),
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, {required bool showLikeBackButton}) {
    final age = user.dateOfBirth != null
        ? DateTime.now().year - user.dateOfBirth!.year
        : null;

    return GestureDetector(
      onTap: () => _showUserProfile(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile Image
              user.photos.isNotEmpty
                  ? Image.network(
                      user.photos[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder(user.name);
                      },
                    )
                  : _buildPlaceholder(user.name),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              // User Info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${user.name}${age != null ? ', $age' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (showLikeBackButton) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _likeBack(user),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, size: 18),
                                SizedBox(width: 4),
                                Text('Like Back'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Match Badge (if already matched)
              Positioned(
                top: 8,
                right: 8,
                child: FutureBuilder<bool>(
                  future: _checkIfMatched(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Matched',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    final initials = name.split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');

    return Container(
      color: const Color(0xFFFF6B9D),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: const Color(0xFFFF6B9D),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _likeBack(UserModel user) async {
    try {
      debugPrint('[LikesScreen] ═══════════════════════════════════════');
      debugPrint('[LikesScreen] 💝 Liking back user: ${user.name}');
      debugPrint('[LikesScreen] Current User: $currentUserId');
      debugPrint('[LikesScreen] Target User: ${user.uid}');
      
      // Check if already matched
      final isMatched = await _checkIfMatched(user.uid);
      if (isMatched) {
        debugPrint('[LikesScreen] ✅ Already matched! Navigating to chat...');
        if (mounted) {
          // Navigate to chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                currentUserId: currentUserId,
                otherUserId: user.uid,
                otherUserName: user.name,
                otherUserPhoto: user.photos.isNotEmpty ? user.photos[0] : null,
              ),
            ),
          );
        }
        return;
      }

      // Use FirebaseServices.recordLike for bidirectional recording
      // This adds to BOTH 'likes' and 'receivedLikes' collections
      debugPrint('[LikesScreen] 📝 Recording bidirectional like...');
      await FirebaseServices.recordLike(
        currentUserId: currentUserId,
        likedUserId: user.uid,
      );
      debugPrint('[LikesScreen] ✅ Like recorded successfully!');

      // Check if it's a match
      debugPrint('[LikesScreen] 🔍 Checking for match...');
      final newMatch = await _matchService.checkAndCreateMatch(
        currentUserId,
        user.uid,
      );
      debugPrint('[LikesScreen] Match result: $newMatch');

      if (mounted) {
        if (newMatch) {
          // Show match dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Color(0xFFFF6B9D),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "It's a Match!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You and ${user.name} liked each other!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF6B9D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Keep Swiping',
                            style: TextStyle(color: Color(0xFFFF6B9D)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  currentUserId: currentUserId,
                                  otherUserId: user.uid,
                                  otherUserName: user.name,
                                  otherUserPhoto: user.photos.isNotEmpty
                                      ? user.photos[0]
                                      : null,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B9D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Send Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          debugPrint('[LikesScreen] ℹ️ Like sent, no match yet');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You liked ${user.name}!'),
              backgroundColor: const Color(0xFFFF6B9D),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      debugPrint('[LikesScreen] ═══════════════════════════════════════');
    } catch (e) {
      debugPrint('[LikesScreen] ❌ Error in _likeBack: $e');
      debugPrint('[LikesScreen] ═══════════════════════════════════════');
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

  Future<bool> _checkIfMatched(String otherUserId) async {
    try {
      final chatId = _getChatId(currentUserId, otherUserId);
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(chatId)
          .get();
      return matchDoc.exists;
    } catch (e) {
      return false;
    }
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  void _showUserProfile(UserModel user) {
    Navigator.pushNamed(
      context,
      '/profile-detail',
      arguments: {
        'user': user,
        'onLike': () async {
          await _likeBack(user);
          Navigator.pop(context);
        },
        'onPass': () {
          Navigator.pop(context);
        },
        'onSuperLike': () async {
          await _likeBack(user);
          Navigator.pop(context);
        },
      },
    );
  }
}