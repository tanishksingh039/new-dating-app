import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../screens/spotlight/spotlight_booking_screen.dart';
import 'premium_options_dialog.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isProcessing;

  const ActionButtons({
    Key? key,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Spotlight button
          _buildSpotlightButton(context),

          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.softWarmPink,
            size: 60,
            onTap: isProcessing ? null : onPass,
          ),

          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.primary,
            size: 60,
            onTap: isProcessing ? null : onLike,
          ),

          // Thunder button (premium/swipe pack)
          _buildThunderButton(context),
        ],
      ),
    );
  }

  void _showPremiumOptionsDialog(BuildContext context) async {
    // Get user's premium status
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final isPremium = userDoc.data()?['isPremium'] ?? false;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => PremiumOptionsDialog(isPremium: isPremium),
      );
    } catch (e) {
      debugPrint('Error checking premium status: $e');
    }
  }

  Widget _buildSpotlightButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SpotlightBookingScreen(),
          ),
        );
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.star,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildThunderButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPremiumOptionsDialog(context);
      },
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onTap,
    bool isPremium = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey[300] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                color: onTap == null ? Colors.grey : color,
                size: size * 0.5,
              ),
            ),
            if (isPremium)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}