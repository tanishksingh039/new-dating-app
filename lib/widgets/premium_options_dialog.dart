import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/payment_service.dart';
import '../services/swipe_limit_service.dart';
import '../config/swipe_config.dart';
import '../constants/app_colors.dart';

/// Dialog showing premium subscription and swipe pack options
/// Premium users: Only see swipe pack (₹20 for 10 swipes)
/// Non-premium users: See both premium (₹99) and swipe pack (₹20 for 6 swipes)
class PremiumOptionsDialog extends StatefulWidget {
  final bool isPremium;

  const PremiumOptionsDialog({
    Key? key,
    required this.isPremium,
  }) : super(key: key);

  @override
  State<PremiumOptionsDialog> createState() => _PremiumOptionsDialogState();
}

class _PremiumOptionsDialogState extends State<PremiumOptionsDialog> {
  final PaymentService _paymentService = PaymentService();
  final SwipeLimitService _swipeLimitService = SwipeLimitService();
  bool _isProcessing = false;
  int _swipesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  void _initializePayment() {
    _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    try {
      // Check if this was a swipe pack purchase or premium subscription
      // We'll determine this based on the amount or description
      // For now, we'll check if _swipesCount was set (swipe pack purchase)
      if (_swipesCount > 0) {
        // Swipe pack purchase
        await _swipeLimitService.addPurchasedSwipesAfterPayment(_swipesCount);
        
        if (mounted) {
          setState(() => _isProcessing = false);
          Navigator.of(context).pop();
          _showSwipePackSuccessDialog();
        }
      } else {
        // Premium subscription
        await _paymentService.handlePaymentSuccess(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId,
          signature: response.signature,
        );
        
        if (mounted) {
          setState(() => _isProcessing = false);
          Navigator.of(context).pop();
          _showPremiumSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _showErrorDialog(response.message ?? 'Payment failed');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _purchaseSwipePack() async {
    setState(() => _isProcessing = true);

    try {
      // Get swipe count first
      _swipesCount = SwipeConfig.getAdditionalSwipesCount(widget.isPremium);
      final description = SwipeConfig.getSwipePackageDescription(widget.isPremium);
      
      // Use the initialized payment service from this dialog
      await _paymentService.startPayment(
        amountInPaise: SwipeConfig.additionalSwipesPriceInPaise,
        description: description,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _purchasePremium() async {
    setState(() {
      _isProcessing = true;
      _swipesCount = 0; // Reset to indicate premium purchase
    });

    try {
      await _paymentService.startPremiumPayment();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _showSwipePackSuccessDialog() {
    final swipesCount = SwipeConfig.getAdditionalSwipesCount(widget.isPremium);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: Text(
          'You\'ve successfully purchased $swipesCount swipes!\nHappy swiping! 🎉',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showPremiumSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text('Welcome to Premium!', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Your premium features are now active. Enjoy unlimited access!',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: Text(
          'Failed to complete purchase.\n\n$error',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipesCount = SwipeConfig.getAdditionalSwipesCount(widget.isPremium);
    final swipePrice = SwipeConfig.additionalSwipesPriceDisplay;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isPremium ? 'Get More Swipes' : 'Upgrade Your Experience',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Premium Plan (only for non-premium users)
              if (!widget.isPremium) ...[
                _buildPremiumPlanCard(),
                const SizedBox(height: 16),
              ],

              // Swipe Pack
              _buildSwipePackCard(swipesCount, swipePrice),

              const SizedBox(height: 20),

              // Close button
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPlanCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFA500).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Popular badge
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.amber[700], size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Premium 1 Month',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '₹99',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA500),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFeature('50 weekly swipes'),
                _buildFeature('Unlimited likes'),
                _buildFeature('See who liked you'),
                _buildFeature('Advanced filters'),
                _buildFeature('Better swipe packages (10 swipes vs 6)'),
                _buildFeature('No verification prompts'),
                _buildFeature('Ad-free experience'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _purchasePremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                            'Get Premium',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipePackCard(int swipesCount, String price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B9D).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swipe, color: AppColors.primary, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Swipe Pack',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$swipesCount swipes',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B9D),
                ),
              ),
            ],
          ),
          if (widget.isPremium) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Premium Bonus: 4 extra swipes!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _purchaseSwipePack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
