import 'package:flutter/material.dart';

/// Admin Dashboard Card Widget
/// Displays key metrics in a visually appealing card format
class AdminDashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const AdminDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Debug print to check what value is being passed
    print('📊 [DashboardCard] Rendering: $title = $value');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160, // Further increased height to fully show content
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, // Increased font size for better readability
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8), // Increased padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20, // Increased icon size
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing
            Flexible(
              child: Text(
                value.isEmpty ? '0' : value, // Fallback to '0' if empty
                style: const TextStyle(
                  fontSize: 24, // Reduced font size to prevent overflow
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Roboto', // Explicitly set font family
                  letterSpacing: 0.5, // Add letter spacing for better readability
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr, // Ensure left-to-right rendering
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4), // Reduced spacing
              Flexible(
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12, // Increased font size for subtitle
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
