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
  StreamSubscription<DocumentSnapshot>? _premiumSubscription;
  
  bool get isPremium => _isPremium;
  DateTime? get premiumActivatedAt => _premiumActivatedAt;
  
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
          
          // Only notify if status changed
          if (newPremiumStatus != _isPremium) {
            debugPrint('[PremiumProvider] ═══════════════════════════════════════');
            debugPrint('[PremiumProvider] 🎉 Premium status changed!');
            debugPrint('[PremiumProvider] Old status: $_isPremium');
            debugPrint('[PremiumProvider] New status: $newPremiumStatus');
            debugPrint('[PremiumProvider] Activated at: $newActivatedAt');
            debugPrint('[PremiumProvider] ═══════════════════════════════════════');
            
            _isPremium = newPremiumStatus;
            _premiumActivatedAt = newActivatedAt;
            
            // Notify all listeners (screens) to rebuild
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
        _isPremium = data?['isPremium'] ?? false;
        _premiumActivatedAt = (data?['premiumActivatedAt'] as Timestamp?)?.toDate();
        
        debugPrint('[PremiumProvider] ✅ Premium status refreshed: $_isPremium');
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
