import 'package:flutter/material.dart';
import '../services/swipe_limit_service.dart';
import '../config/swipe_config.dart';

/// Widget to display swipe limit indicator
class SwipeLimitIndicator extends StatelessWidget {
  SwipeLimitIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final swipeLimitService = SwipeLimitService();
    return StreamBuilder<Map<String, dynamic>>(
      stream: swipeLimitService.swipeStatsStream().asyncMap(
        (_) => swipeLimitService.getSwipeSummary(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final summary = snapshot.data!;
        final freeSwipesRemaining = summary['freeSwipesRemaining'] as int;
        final purchasedSwipesRemaining = summary['purchasedSwipesRemaining'] as int;
        final totalRemaining = summary['totalRemaining'] as int;
        final isPremium = summary['isPremium'] as bool;

        // Color based on remaining swipes
        Color indicatorColor;
        if (totalRemaining == 0) {
          indicatorColor = Colors.red;
        } else if (freeSwipesRemaining == 0) {
          indicatorColor = Colors.orange;
        } else if (freeSwipesRemaining <= 3) {
          indicatorColor = Colors.yellow.shade700;
        } else {
          indicatorColor = Colors.green;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: indicatorColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swipe,
                size: 18,
                color: indicatorColor,
              ),
              const SizedBox(width: 6),
              Text(
                totalRemaining == 0
                    ? 'No swipes left'
                    : '$totalRemaining swipe${totalRemaining == 1 ? '' : 's'}',
                style: TextStyle(
                  color: indicatorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (purchasedSwipesRemaining > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$purchasedSwipesRemaining',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
