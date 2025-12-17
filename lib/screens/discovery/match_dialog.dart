import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../chat/chat_screen.dart';
import 'package:confetti/confetti.dart';
import '../../widgets/icebreaker_selection_widget.dart';
import '../../firebase_services.dart';

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
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // It's a Match text
                    const Text(
                      "It's a Match! 🎉",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'You and ${widget.matchedUser.name} have liked each other',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 20),

                    // Profile pictures
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Current user photo
                                _buildProfileImage(_currentUserPhoto ?? '', true),

                                const SizedBox(width: 12),

                                // Heart icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.pink,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Matched user photo
                                _buildProfileImage(matchedUserPhoto ?? '', false),
                              ],
                            ),
                          ),

                    const SizedBox(height: 20),

                    // Start with icebreaker button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showIcebreakerSelection(context, currentUserId, matchedUserPhoto),
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: const Text(
                          'Start with a Fun Question',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Send message button (secondary)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Colors.pink, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Type My Own Message',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.pink,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Keep swiping button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Keep Swiping',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show icebreaker selection bottom sheet
  void _showIcebreakerSelection(BuildContext context, String currentUserId, String? matchedUserPhoto) {
    final matchId = _generateMatchId(currentUserId, widget.matchedUser.uid);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: IcebreakerSelectionWidget(
          matchId: matchId,
          currentUserId: currentUserId,
          otherUserId: widget.matchedUser.uid,
          otherUserName: widget.matchedUser.name,
          onQuestionSelected: (question) async {
            // Close icebreaker sheet
            Navigator.pop(context);
            
            // Send the icebreaker question
            await _sendIcebreakerMessage(currentUserId, question);
            
            // Close match dialog
            Navigator.pop(context);
            
            // Navigate to chat
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
        ),
      ),
    );
  }

  /// Send icebreaker question to chat
  Future<void> _sendIcebreakerMessage(String currentUserId, String question) async {
    try {
      // Send question directly to chat
      await FirebaseServices.sendMessage(
        currentUserId,
        widget.matchedUser.uid,
        question,
      );
      
      debugPrint('✅ Icebreaker question sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending icebreaker: $e');
    }
  }

  /// Generate match ID (same logic as MatchService)
  String _generateMatchId(String user1Id, String user2Id) {
    final ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Widget _buildProfileImage(String imageUrl, bool isCurrentUser) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
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