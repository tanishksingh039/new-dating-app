import 'package:flutter/material.dart';
import '../services/leaderboard_optout_service.dart';

class LeaderboardOptOutToggle extends StatefulWidget {
  final String userId;
  final VoidCallback? onToggle;

  const LeaderboardOptOutToggle({
    required this.userId,
    this.onToggle,
    Key? key,
  }) : super(key: key);

  @override
  State<LeaderboardOptOutToggle> createState() => _LeaderboardOptOutToggleState();
}

class _LeaderboardOptOutToggleState extends State<LeaderboardOptOutToggle> {
  final LeaderboardOptOutService _optOutService = LeaderboardOptOutService();
  late Stream<bool> _optOutStatusStream;

  @override
  void initState() {
    super.initState();
    _optOutStatusStream = _optOutService.getOptOutStatusStream(widget.userId);
  }

  Future<void> _toggleOptOut(bool isCurrentlyOptedOut) async {
    try {
      if (isCurrentlyOptedOut) {
        // User is opted out, so opt them back in
        await _optOutService.optIn(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ You\'re back on the leaderboard!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // User is opted in, so opt them out
        _showOptOutConfirmation();
      }
      widget.onToggle?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showOptOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Step Into Silence?'),
        content: const Text(
          'You\'ll disappear from the leaderboard. Your chats continue normally, but nothing will be counted toward visibility or scores.\n\nYou can come back anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay Visible'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _optOutService.optOut(widget.userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔇 You\'re now in silent mode. Your presence is private.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                widget.onToggle?.call();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Go Silent',
              style: TextStyle(color: Colors.purple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _optOutStatusStream,
      builder: (context, snapshot) {
        final isOptedOut = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOptedOut ? Colors.purple.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOptedOut ? Colors.purple.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOptedOut ? Icons.visibility_off : Icons.visibility,
                    color: isOptedOut ? Colors.purple : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOptedOut ? 'Silent Mode Active' : 'Leaderboard Visibility',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOptedOut
                              ? 'You\'re invisible to the leaderboard. Your chats continue normally.'
                              : 'Your presence is visible on the leaderboard.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: !isOptedOut,
                    onChanged: (_) => _toggleOptOut(isOptedOut),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOptedOut
                      ? '✓ Your chats continue normally\n✓ No activity is analyzed\n✓ No scores are calculated\n✓ You can rejoin anytime'
                      : '✓ You\'re on the leaderboard\n✓ Your activity is recognized\n✓ You can opt out anytime\n✓ Your comfort matters',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
