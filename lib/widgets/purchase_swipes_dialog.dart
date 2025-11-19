import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/swipe_limit_service.dart';
import '../services/payment_service.dart';
import '../config/swipe_config.dart';

/// Dialog to purchase additional swipes
class PurchaseSwipesDialog extends StatefulWidget {
  final bool isPremium;

  const PurchaseSwipesDialog({
    Key? key,
    required this.isPremium,
  }) : super(key: key);

  @override
  State<PurchaseSwipesDialog> createState() => _PurchaseSwipesDialogState();
}

class _PurchaseSwipesDialogState extends State<PurchaseSwipesDialog> {
  final SwipeLimitService _swipeLimitService = SwipeLimitService();
  final PaymentService _paymentService = PaymentService();
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
    // Add swipes to user account
    await _swipeLimitService.addPurchasedSwipesAfterPayment(_swipesCount);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pop();
      _showSuccessDialog();
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

  void _purchaseSwipes() async {
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

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
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
          'Failed to purchase swipes.\n\n$error',
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
    final price = SwipeConfig.additionalSwipesPriceDisplay;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B9D).withOpacity(0.1),
              const Color(0xFFC06C84).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swipe,
                size: 48,
                color: Color(0xFFFF6B9D),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Out of Swipes?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Get $swipesCount more swipes to keep discovering amazing people!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),

            // Package details
            Container(
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Swipes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '$swipesCount swipes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Premium badge if applicable
            if (widget.isPremium)
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
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _purchaseSwipes,
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
          ],
        ),
      ),
    );
  }
}
