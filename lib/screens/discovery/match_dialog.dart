import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../chat/chat_screen.dart';
import 'package:confetti/confetti.dart';

class MatchDialog extends StatefulWidget {
  final String currentUserId;
  final UserModel matchedUser;
  final String? currentUserPhotoUrl; // Optional: pass from parent

  const MatchDialog({
    Key? key,
    required this.currentUserId,
    required this.matchedUser,
    this.currentUserPhotoUrl,
  }) : super(key: key);

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  String? _currentUserPhoto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Scale animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Load current user photo
    _loadCurrentUserPhoto();

    // Start animations
    _animationController.forward();
    _confettiController.play();
  }

  Future<void> _loadCurrentUserPhoto() async {
    try {
      // Use passed photo if available
      if (widget.currentUserPhotoUrl != null) {
        setState(() {
          _currentUserPhoto = widget.currentUserPhotoUrl;
          _isLoading = false;
        });
        return;
      }

      // Otherwise fetch from Firestore
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final photos = userData?['photos'] as List<dynamic>?;
        setState(() {
          _currentUserPhoto = photos?.isNotEmpty == true ? photos![0] : null;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading current user photo: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final matchedUserPhoto = widget.matchedUser.photos.isNotEmpty
        ? widget.matchedUser.photos[0]
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.pink,
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),

          // Match content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // It's a Match text
                  const Text(
                    "It's a Match! 🎉",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Subtitle
                  Text(
                    'You and ${widget.matchedUser.name} have liked each other',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Profile pictures
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Current user photo
                            _buildProfileImage(_currentUserPhoto ?? '', true),

                            const SizedBox(width: 30),

                            // Heart icon
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 30,
                              ),
                            ),

                            const SizedBox(width: 30),

                            // Matched user photo
                            _buildProfileImage(matchedUserPhoto ?? '', false),
                          ],
                        ),

                  const SizedBox(height: 30),

                  // Send message button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              currentUserId: currentUserId,
                              otherUserId: widget.matchedUser.uid,
                              otherUserName: widget.matchedUser.name,
                              otherUserPhoto: matchedUserPhoto,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Keep swiping button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Keep Swiping',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl, bool isCurrentUser) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
      ),
    );
  }
}