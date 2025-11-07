import 'package:flutter/material.dart';

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
            color: Colors.yellow[700]!,
            size: 50,
            onTap: () {
              // TODO: Implement rewind (premium feature)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rewind is a premium feature'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            isPremium: true,
          ),

          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            size: 60,
            onTap: isProcessing ? null : onPass,
          ),

          // Super like button
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            size: 55,
            onTap: isProcessing ? null : onSuperLike,
          ),

          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green,
            size: 60,
            onTap: isProcessing ? null : onLike,
          ),

          // Boost button (premium feature)
          _buildActionButton(
            icon: Icons.flash_on,
            color: Colors.purple,
            size: 50,
            onTap: () {
              // TODO: Implement boost (premium feature)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Boost is a premium feature'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            isPremium: true,
          ),
        ],
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