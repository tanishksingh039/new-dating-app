import 'package:flutter/material.dart';
import '../services/profile_picture_verification_service.dart';
import '../screens/verification/liveness_verification_screen.dart';

/// Dialog shown when user attempts to change profile picture
/// Mandatory verification dialog with no dismiss option
class ProfilePictureVerificationDialog extends StatefulWidget {
  final VoidCallback onVerificationComplete;
  final VoidCallback onPictureDiscarded;

  const ProfilePictureVerificationDialog({
    Key? key,
    required this.onVerificationComplete,
    required this.onPictureDiscarded,
  }) : super(key: key);

  @override
  State<ProfilePictureVerificationDialog> createState() => _ProfilePictureVerificationDialogState();
}

class _ProfilePictureVerificationDialogState extends State<ProfilePictureVerificationDialog> {
  bool _isProcessing = false;

  /// Navigate to liveness verification screen
  Future<void> _goToLivenessVerification() async {
    try {
      setState(() => _isProcessing = true);
      
      // Store the callback before closing dialog
      final callback = widget.onVerificationComplete;
      
      // Close this dialog first
      Navigator.of(context).pop();
      
      // Navigate to liveness verification screen with profile picture context
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LivenessVerificationScreen(
            isProfilePictureVerification: true,
          ),
        ),
      );
      
      if (result == true) {
        // Verification completed successfully
        // The LivenessVerificationScreen already completed the profile picture verification
        print('✅ [ProfilePictureVerificationDialog] Liveness verification completed - calling callback');
        callback();
      } else {
        print('⚠️ [ProfilePictureVerificationDialog] Liveness verification returned false or null');
      }
    } catch (e) {
      print('❌ Error navigating to liveness verification: $e');
      if (mounted) {
        _showMessage('Error opening verification screen. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Discard the pending profile picture
  Future<void> _discardProfilePicture() async {
    try {
      setState(() => _isProcessing = true);
      
      // Discard the pending picture
      await ProfilePictureVerificationService.discardPendingProfilePicture();
      
      if (mounted) {
        setState(() => _isProcessing = false);
        // Close dialog
        Navigator.of(context).pop();
        widget.onPictureDiscarded();
      }
    } catch (e) {
      print('❌ Error discarding picture: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showMessage('Error discarding picture. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent dismissal by back button
      onWillPop: () async => false,
      child: Dialog(
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
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Verify Your Identity',
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
                'To ensure account security and prevent misuse, please verify your identity with a live photo before changing your profile picture.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a one-time verification to match your new photo with your identity.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Verify Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _goToLivenessVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'I Want to Verify Myself Once Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Discard Picture Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _discardProfilePicture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Want to Change My Profile Picture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Warning text
              Text(
                '⚠️ This dialog cannot be dismissed. You must complete one of the above options.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
