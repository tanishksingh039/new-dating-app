import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ban_enforcement_service.dart';

class BannedScreen extends StatefulWidget {
  final Map<String, dynamic> banStatus;

  const BannedScreen({
    Key? key,
    required this.banStatus,
  }) : super(key: key);

  @override
  State<BannedScreen> createState() => _BannedScreenState();
}

class _BannedScreenState extends State<BannedScreen> {
  final BanEnforcementService _banService = BanEnforcementService();
  late Duration _timeRemaining;
  late Stream<Duration> _countdownStream;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
  }

  void _initializeCountdown() {
    if (widget.banStatus['banType'] == 'temporary' && widget.banStatus['bannedUntil'] != null) {
      final bannedUntil = widget.banStatus['bannedUntil'] as DateTime;
      _countdownStream = Stream.periodic(const Duration(seconds: 1), (_) {
        return bannedUntil.difference(DateTime.now());
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final banType = widget.banStatus['banType'] ?? 'unknown';
    final reason = widget.banStatus['reason'] ?? 'Violation of community guidelines';
    final daysLeft = widget.banStatus['daysLeft'] ?? 0;
    final hoursLeft = widget.banStatus['hoursLeft'] ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: banType == 'deleted' ? Colors.red.shade100 : Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    banType == 'deleted' ? Icons.delete_forever : Icons.block,
                    size: 64,
                    color: banType == 'deleted' ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  banType == 'deleted'
                      ? 'Account Deleted'
                      : banType == 'permanent'
                          ? 'Account Banned'
                          : 'Account Suspended',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Reason
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Countdown for temporary ban
                if (banType == 'temporary')
                  StreamBuilder<Duration>(
                    stream: _countdownStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final duration = snapshot.data!;
                      final days = duration.inDays;
                      final hours = duration.inHours.remainder(24);
                      final minutes = duration.inMinutes.remainder(60);
                      final seconds = duration.inSeconds.remainder(60);

                      if (duration.isNegative) {
                        // Ban expired, show message
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your suspension has ended!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You can now use your account again.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/home',
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue to App',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Time Remaining:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildTimeUnit(days.toString(), 'Days'),
                                _buildTimeUnit(hours.toString(), 'Hours'),
                                _buildTimeUnit(minutes.toString(), 'Min'),
                                _buildTimeUnit(seconds.toString(), 'Sec'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your account will be available again in $days days, $hours hours, $minutes minutes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                if (banType != 'temporary') const SizedBox(height: 24),

                // Message
                if (banType == 'deleted')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: const Text(
                      'Your account has been permanently deleted. All your data has been removed from our system. This action cannot be reversed.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (banType == 'permanent')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: const Text(
                      'Your account has been permanently banned. This action cannot be reversed. If you believe this is a mistake, please contact our support team.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                // Logout button
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
