import 'package:flutter/material.dart';
import '../services/verification_check_service.dart';
import '../screens/verification/liveness_verification_screen.dart';

/// Dialog shown when user tries to purchase premium without verification
class VerificationRequiredDialog extends StatefulWidget {
  final VoidCallback onVerificationComplete;

  const VerificationRequiredDialog({
    Key? key,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<VerificationRequiredDialog> createState() => _VerificationRequiredDialogState();
}

class _VerificationRequiredDialogState extends State<VerificationRequiredDialog> {
  bool _isChecking = false;

  /// Check if user is now verified and close dialog if true
  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);

    try {
      final isVerified = await VerificationCheckService.isUserVerified();

      if (mounted) {
        setState(() => _isChecking = false);

        if (isVerified) {
          // User is now verified, close dialog and trigger callback
          Navigator.of(context).pop();
          widget.onVerificationComplete();
        } else {
          // Still not verified
          _showMessage('Still not verified. Please complete all verification steps.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        _showMessage('Error checking verification status');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Navigate to liveness verification screen (same as Settings → Verify Profile)
  Future<void> _goToLivenessVerification() async {
    try {
      // Close this dialog first
      Navigator.of(context).pop();
      
      // Navigate to liveness verification screen using the same path as Settings
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LivenessVerificationScreen(),
        ),
      );
      
      if (result == true) {
        // Verification completed successfully
        // Verify that user is now verified before proceeding
        final isNowVerified = await VerificationCheckService.isUserVerified();
        
        if (isNowVerified) {
          // User is verified, proceed with payment
          widget.onVerificationComplete();
        } else {
          // Verification still not complete
          _showMessage('Verification not completed. Please try again.');
        }
      }
    } catch (e) {
      print('❌ Error navigating to liveness verification: $e');
      if (mounted) {
        _showMessage('Error opening verification screen. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Verification Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'To purchase premium and ensure a safe community, please verify your account first.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Verification Steps
            _buildVerificationStep(
              icon: Icons.person,
              title: 'Complete Profile',
              description: 'Fill in all profile details',
            ),
            const SizedBox(height: 12),
            _buildVerificationStep(
              icon: Icons.verified,
              title: 'Verify Account',
              description: 'Complete verification process',
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _goToLivenessVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Want to Verify Myself',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkVerificationStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    : const Text(
                        'I\'ve Verified My Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
