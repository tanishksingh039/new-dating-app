import 'package:flutter/material.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';
import '../../constants/app_colors.dart';

class SendRewardDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhoto;

  const SendRewardDialog({
    Key? key,
    required this.userId,
    required this.userName,
    this.userPhoto,
  }) : super(key: key);

  @override
  State<SendRewardDialog> createState() => _SendRewardDialogState();
}

class _SendRewardDialogState extends State<SendRewardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _couponValueController = TextEditingController();
  final _adminNotesController = TextEditingController();

  RewardType _selectedType = RewardType.coupon;
  DateTime? _expiryDate;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _couponCodeController.dispose();
    _couponValueController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _sendReward() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      await RewardService.sendRewardToUser(
        userId: widget.userId,
        userName: widget.userName,
        userPhoto: widget.userPhoto,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        couponCode: _selectedType == RewardType.coupon
            ? _couponCodeController.text.trim()
            : null,
        couponValue: _selectedType == RewardType.coupon
            ? _couponValueController.text.trim()
            : null,
        expiryDate: _expiryDate,
        adminId: 'admin_user',
        adminNotes: _adminNotesController.text.trim().isEmpty
            ? null
            : _adminNotesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reward sent to ${widget.userName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Reward',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'To: ${widget.userName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Reward Type
                  const Text(
                    'Reward Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RewardType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: RewardType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getRewardIcon(type), size: 20),
                            const SizedBox(width: 12),
                            Text(_getRewardTypeName(type)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Top 10 Leaderboard Reward',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe the reward...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Coupon Code (only for coupon type)
                  if (_selectedType == RewardType.coupon) ...[
                    const Text(
                      'Coupon Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _couponCodeController,
                      decoration: InputDecoration(
                        hintText: 'e.g., CAMPUS50',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_awesome),
                          onPressed: () {
                            // Generate random code
                            final code = 'CAMPUS${DateTime.now().millisecondsSinceEpoch % 100000}';
                            _couponCodeController.text = code;
                          },
                          tooltip: 'Generate Code',
                        ),
                      ),
                      validator: (value) {
                        if (_selectedType == RewardType.coupon &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter a coupon code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Coupon Value
                    const Text(
                      'Coupon Value',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _couponValueController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 50% OFF or \$10 OFF',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (_selectedType == RewardType.coupon &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter coupon value';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Expiry Date
                  const Text(
                    'Expiry Date (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _expiryDate == null
                                ? 'Select expiry date'
                                : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                            style: TextStyle(
                              color: _expiryDate == null
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          if (_expiryDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _expiryDate = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Admin Notes
                  const Text(
                    'Admin Notes (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adminNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Internal notes (not visible to user)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSending
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendReward,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Send Reward',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coupon:
        return Icons.local_offer;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.premium:
        return Icons.workspace_premium;
      case RewardType.spotlight:
        return Icons.star;
      case RewardType.other:
        return Icons.card_giftcard;
    }
  }

  String _getRewardTypeName(RewardType type) {
    switch (type) {
      case RewardType.coupon:
        return 'Coupon Code';
      case RewardType.badge:
        return 'Badge';
      case RewardType.premium:
        return 'Premium Access';
      case RewardType.spotlight:
        return 'Spotlight Boost';
      case RewardType.other:
        return 'Other Reward';
    }
  }
}
