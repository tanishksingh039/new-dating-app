import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/payment/payment_screen.dart';
import '../screens/spotlight/spotlight_booking_screen.dart';

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
          // Rewind button (premium feature)
          _buildActionButton(
            icon: Icons.replay,
            color: AppColors.warmPeach,
            size: 50,
            onTap: () {
              _showPremiumDialog(context, 'Rewind');
            },
            isPremium: true,
          ),

          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.softWarmPink,
            size: 60,
            onTap: isProcessing ? null : onPass,
          ),

          // Spotlight button (replaces super like)
          _buildSpotlightButton(context),

          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.primary,
            size: 60,
            onTap: isProcessing ? null : onLike,
          ),

          // Boost button (premium feature)
          _buildActionButton(
            icon: Icons.flash_on,
            color: AppColors.shadowyPurple,
            size: 50,
            onTap: () {
              _showPremiumDialog(context, 'Boost');
            },
            isPremium: true,
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[700], size: 28),
            const SizedBox(width: 12),
            const Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'Do you want to avail Premium?\n\nUpgrade now to unlock exclusive features like unlimited swipes, advanced filters, and much more!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
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