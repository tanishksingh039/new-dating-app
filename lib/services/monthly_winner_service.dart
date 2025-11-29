import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_winner_model.dart';

class MonthlyWinnerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Announce monthly winner (Admin only)
  static Future<String> announceWinner({
    required String userId,
    required String userName,
    String? userPhoto,
    required int points,
    required int rank,
    required String month,
    required String year,
    String? achievement,
    String? message,
    String? adminId,
  }) async {
    try {
      debugPrint('[MonthlyWinnerService] ═══════════════════════════════════════');
      debugPrint('[MonthlyWinnerService] 🏆 Announcing monthly winner');
      debugPrint('[MonthlyWinnerService] User: $userName');
      debugPrint('[MonthlyWinnerService] Month: $month $year');
      debugPrint('[MonthlyWinnerService] Points: $points');

      final winner = MonthlyWinnerModel(
        id: '',
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        points: points,
        rank: rank,
        month: month,
        year: year,
        achievement: achievement ?? 'Winner of the Month',
        message: message ?? 'Congratulations on being the top performer this month!',
        announcedAt: DateTime.now(),
        adminId: adminId,
      );

      // Add winner to monthly_winners collection
      final winnerRef = await _firestore.collection('monthly_winners').add(winner.toMap());
      
      debugPrint('[MonthlyWinnerService] ✅ Winner announced with ID: ${winnerRef.id}');

      // Send notification to winner
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': '🏆 Congratulations! You\'re Winner of the Month!',
        'body': message ?? 'You\'ve been announced as the winner for $month $year!',
        'type': 'winner_announcement',
        'data': {
          'winnerId': winnerRef.id,
          'month': month,
          'year': year,
          'screen': 'rewards',
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
      });

      debugPrint('[MonthlyWinnerService] ✅ Notification sent to winner');
      debugPrint('[MonthlyWinnerService] ═══════════════════════════════════════');

      return winnerRef.id;
    } catch (e, stackTrace) {
      debugPrint('[MonthlyWinnerService] ❌ Error announcing winner: $e');
      debugPrint('[MonthlyWinnerService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get current month's winner
  static Future<MonthlyWinnerModel?> getCurrentMonthWinner() async {
    try {
      final now = DateTime.now();
      final currentMonth = _getMonthName(now.month);
      final currentYear = now.year.toString();

      debugPrint('[MonthlyWinnerService] Fetching winner for: $currentMonth $currentYear');

      final snapshot = await _firestore
          .collection('monthly_winners')
          .where('month', isEqualTo: currentMonth)
          .where('year', isEqualTo: currentYear)
          .orderBy('announcedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[MonthlyWinnerService] No winner found for current month');
        return null;
      }

      final winner = MonthlyWinnerModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      debugPrint('[MonthlyWinnerService] ✅ Found winner: ${winner.userName}');
      return winner;
    } catch (e) {
      debugPrint('[MonthlyWinnerService] ❌ Error fetching winner: $e');
      return null;
    }
  }

  /// Get current month's winner (Stream)
  static Stream<MonthlyWinnerModel?> getCurrentMonthWinnerStream() {
    final now = DateTime.now();
    final currentMonth = _getMonthName(now.month);
    final currentYear = now.year.toString();

    return _firestore
        .collection('monthly_winners')
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .orderBy('announcedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MonthlyWinnerModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  /// Get all winners
  static Stream<List<MonthlyWinnerModel>> getAllWinnersStream() {
    return _firestore
        .collection('monthly_winners')
        .orderBy('announcedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MonthlyWinnerModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get winners by year
  static Future<List<MonthlyWinnerModel>> getWinnersByYear(String year) async {
    try {
      final snapshot = await _firestore
          .collection('monthly_winners')
          .where('year', isEqualTo: year)
          .orderBy('announcedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MonthlyWinnerModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[MonthlyWinnerService] Error fetching winners by year: $e');
      return [];
    }
  }

  /// Delete winner announcement
  static Future<void> deleteWinner(String winnerId) async {
    try {
      await _firestore.collection('monthly_winners').doc(winnerId).delete();
      debugPrint('[MonthlyWinnerService] ✅ Winner deleted');
    } catch (e) {
      debugPrint('[MonthlyWinnerService] ❌ Error deleting winner: $e');
      rethrow;
    }
  }

  /// Helper: Get month name from number
  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Get current month name
  static String getCurrentMonth() {
    return _getMonthName(DateTime.now().month);
  }

  /// Get current year
  static String getCurrentYear() {
    return DateTime.now().year.toString();
  }
}
