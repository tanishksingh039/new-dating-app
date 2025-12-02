import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for real-time premium status monitoring
/// Listens to Firestore changes and updates all screens automatically
class PremiumProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isPremium = false;
  DateTime? _premiumActivatedAt;
  DateTime? _premiumExpiryDate;
  StreamSubscription<DocumentSnapshot>? _premiumSubscription;
  
  bool get isPremium => _isPremium;
  DateTime? get premiumActivatedAt => _premiumActivatedAt;
  DateTime? get premiumExpiryDate => _premiumExpiryDate;
  
  /// Get remaining days until premium expires (null if not premium)
  int? get remainingDays {
    if (!_isPremium || _premiumExpiryDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_premiumExpiryDate!)) return 0; // Already expired
    return _premiumExpiryDate!.difference(now).inDays;
  }
  
  /// Check if premium has expired
  bool get isPremiumExpired {
    if (!_isPremium || _premiumExpiryDate == null) return false;
    return DateTime.now().isAfter(_premiumExpiryDate!);
  }
  
  PremiumProvider() {
    _initializePremiumListener();
  }
  
  /// Initialize real-time listener for premium status
  void _initializePremiumListener() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[PremiumProvider] No user signed in');
      return;
    }
    
    debugPrint('[PremiumProvider] 🔄 Starting real-time premium status listener for user: ${user.uid}');
    
    // Listen to user document changes in real-time
    _premiumSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final newPremiumStatus = data?['isPremium'] ?? false;
          final newActivatedAt = (data?['premiumActivatedAt'] as Timestamp?)?.toDate();
          final newExpiryDate = (data?['premiumExpiryDate'] as Timestamp?)?.toDate();
          
          debugPrint('[PremiumProvider] 📊 Premium status update received');
          debugPrint('[PremiumProvider] Current: $_isPremium → New: $newPremiumStatus');
          
          // Check if premium has expired
          bool shouldExpirePremium = false;
          if (newPremiumStatus && newExpiryDate != null) {
            final now = DateTime.now();
            if (now.isAfter(newExpiryDate)) {
              debugPrint('[PremiumProvider] ⏰ Premium has expired! Expiry was: $newExpiryDate');
              shouldExpirePremium = true;
            } else {
              final remainingDays = newExpiryDate.difference(now).inDays;
              debugPrint('[PremiumProvider] ⏳ Premium active - $remainingDays days remaining');
            }
          }
          
          // Update status and notify listeners
          if (newPremiumStatus != _isPremium || 
              _premiumActivatedAt != newActivatedAt ||
              _premiumExpiryDate != newExpiryDate ||
              shouldExpirePremium) {
            debugPrint('[PremiumProvider] ═══════════════════════════════════════');
            debugPrint('[PremiumProvider] 🎉 Premium status changed!');
            debugPrint('[PremiumProvider] Old status: $_isPremium');
            debugPrint('[PremiumProvider] New status: $newPremiumStatus');
            debugPrint('[PremiumProvider] Activated at: $newActivatedAt');
            debugPrint('[PremiumProvider] Expires at: $newExpiryDate');
            debugPrint('[PremiumProvider] ═══════════════════════════════════════');
            
            _isPremium = shouldExpirePremium ? false : newPremiumStatus;
            _premiumActivatedAt = newActivatedAt;
            _premiumExpiryDate = newExpiryDate;
            
            // If premium expired, auto-expire it in Firestore
            if (shouldExpirePremium) {
              debugPrint('[PremiumProvider] 🔄 Auto-expiring premium in Firestore...');
              _firestore.collection('users').doc(user.uid).update({
                'isPremium': false,
              }).catchError((e) {
                debugPrint('[PremiumProvider] ❌ Error auto-expiring premium: $e');
              });
            }
            
            // Notify all listeners (screens) to rebuild
            notifyListeners();
          }
        } else {
          // User document doesn't exist, default to non-premium
          debugPrint('[PremiumProvider] ⚠️ User document does not exist, setting premium to false');
          if (_isPremium != false) {
            _isPremium = false;
            _premiumActivatedAt = null;
            _premiumExpiryDate = null;
            notifyListeners();
          }
        }
      },
      onError: (error) {
        debugPrint('[PremiumProvider] ❌ Error listening to premium status: $error');
      },
    );
  }
  
  /// Manually refresh premium status (for initial load)
  Future<void> refreshPremiumStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final newPremiumStatus = data?['isPremium'] ?? false;
        final newExpiryDate = (data?['premiumExpiryDate'] as Timestamp?)?.toDate();
        _isPremium = newPremiumStatus;
        _premiumActivatedAt = (data?['premiumActivatedAt'] as Timestamp?)?.toDate();
        _premiumExpiryDate = newExpiryDate;
        
        // Check if premium has expired
        if (newPremiumStatus && newExpiryDate != null) {
          final now = DateTime.now();
          if (now.isAfter(newExpiryDate)) {
            debugPrint('[PremiumProvider] ⏰ Premium has expired during refresh!');
            _isPremium = false;
            await _firestore.collection('users').doc(user.uid).update({
              'isPremium': false,
            });
          }
        }
        
        debugPrint('[PremiumProvider] ✅ Premium status refreshed: $_isPremium');
        debugPrint('[PremiumProvider] Expires at: $_premiumExpiryDate');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PremiumProvider] ❌ Error refreshing premium status: $e');
    }
  }
  
  @override
  void dispose() {
    debugPrint('[PremiumProvider] 🛑 Disposing premium listener');
    _premiumSubscription?.cancel();
    super.dispose();
  }
}
