import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../discovery/swipeable_discovery_screen.dart';
import '../matches/matches_screen.dart';
import '../likes/likes_screen.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../rewards/rewards_leaderboard_screen.dart';
import '../warning_screen.dart';
import '../../constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/navigation_service.dart';
import '../../services/action_notification_service.dart';
import '../../services/presence_service.dart';
import '../../services/reward_notification_service.dart';
import '../../widgets/admin_action_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isFemale = false;
  bool _isLoading = true;
  final PresenceService _presenceService = PresenceService();
  int _unreadRewardNotifications = 0;

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _checkUserGender();
    _listenToRewardNotifications();
    
    // Listen to navigation service for tab changes
    NavigationService.selectedTabNotifier.addListener(_onTabChangeFromNotification);
    
    // Start presence tracking when home screen loads
    WidgetsBinding.instance.addObserver(this);
    _presenceService.startPresenceTracking();
  }

  @override
  void dispose() {
    NavigationService.selectedTabNotifier.removeListener(_onTabChangeFromNotification);
    WidgetsBinding.instance.removeObserver(this);
    _presenceService.stopPresenceTracking();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update presence based on app lifecycle
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - start tracking
        _presenceService.startPresenceTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background - stop tracking
        _presenceService.stopPresenceTracking();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onTabChangeFromNotification() {
    final newIndex = NavigationService.selectedTabNotifier.value;
    if (newIndex != _selectedIndex && mounted) {
      setState(() {
        _selectedIndex = newIndex;
      });
      
      // Mark notifications as read when user opens Rewards tab
      if (_isFemale && newIndex == 4) {
        RewardNotificationService.markWinnerNotificationsAsRead();
      }
    }
  }
  
  void _listenToRewardNotifications() {
    debugPrint('[HomeScreen] 🔔 Setting up reward notification listener...');
    RewardNotificationService.getUnreadWinnerNotificationsCount().listen((count) {
      debugPrint('[HomeScreen] 🔔 Received notification count: $count');
      if (mounted) {
        setState(() {
          _unreadRewardNotifications = count;
          debugPrint('[HomeScreen] 🔔 Updated badge count to: $_unreadRewardNotifications');
        });
      }
    }, onError: (error) {
      debugPrint('[HomeScreen] ❌ Error in notification listener: $error');
    });
  }

  Future<void> _checkUserGender() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data();
          if (data is Map<String, dynamic>) {
            final user = UserModel.fromMap(data);
            setState(() {
              _isFemale = user.gender.toLowerCase() == 'female';
              _screens = _isFemale
                  ? [
                      const AdminActionChecker(child: SwipeableDiscoveryScreen()),
                      const AdminActionChecker(child: LikesScreen()),
                      const AdminActionChecker(child: MatchesScreen()),
                      const AdminActionChecker(child: ConversationsScreen()),
                      const AdminActionChecker(child: RewardsLeaderboardScreen()),
                      const AdminActionChecker(child: ProfileScreen()),
                    ]
                  : [
                      const AdminActionChecker(child: SwipeableDiscoveryScreen()),
                      const AdminActionChecker(child: LikesScreen()),
                      const AdminActionChecker(child: MatchesScreen()),
                      const AdminActionChecker(child: ConversationsScreen()),
                      const AdminActionChecker(child: ProfileScreen()),
                    ];
              _isLoading = false;
            });
          } else {
            debugPrint('[HomeScreen] Document data is not a Map');
            setState(() => _isLoading = false);
          }
        } else {
          debugPrint('[HomeScreen] Document does not exist or data is null');
          setState(() => _isLoading = false);
        }
      } else {
        debugPrint('[HomeScreen] User ID is null');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error checking user gender: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Mark notifications as read when user taps Rewards tab
    if (_isFemale && index == 4) {
      RewardNotificationService.markWinnerNotificationsAsRead();
    }
    
    // Check for pending warnings when user changes tabs
    _checkForWarnings();
  }
  
  Future<void> _checkForWarnings() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('[HomeScreen] 🔍 Checking for warnings on tab change');
      debugPrint('[HomeScreen] User ID: $userId');
      
      if (userId == null) {
        debugPrint('[HomeScreen] ❌ No user ID');
        return;
      }
      
      final notificationService = ActionNotificationService();
      debugPrint('[HomeScreen] Fetching pending notifications...');
      
      final notifications = await notificationService.getPendingActionNotifications(userId);
      debugPrint('[HomeScreen] 📬 Found ${notifications.length} notifications');
      
      if (notifications.isNotEmpty) {
        debugPrint('[HomeScreen] ✅ Notifications found:');
        for (var notif in notifications) {
          debugPrint('[HomeScreen]   - Action: ${notif['action']}, Reason: ${notif['reason']}');
        }
      }
      
      if (notifications.isNotEmpty && mounted) {
        final firstNotification = notifications[0];
        final action = firstNotification['action'];
        
        debugPrint('[HomeScreen] Processing first notification');
        debugPrint('[HomeScreen] Action: "$action"');
        debugPrint('[HomeScreen] Is warning? ${action == 'warning'}');
        
        if (action == 'warning' || action.toString().toLowerCase().contains('warning')) {
          debugPrint('[HomeScreen] 🎯 Showing warning screen from tab change');
          
          // Show warning screen
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WarningScreen(
                warningData: {
                  'reason': firstNotification['reason'] ?? 'Violation of community guidelines',
                  'warningCount': 1,
                  'lastWarningAt': firstNotification['createdAt'],
                },
              ),
            ),
          );
          
          debugPrint('[HomeScreen] ✅ User returned from warning screen');
          
          // Mark as read
          await notificationService.markNotificationAsRead(userId, firstNotification['id']);
          debugPrint('[HomeScreen] ✅ Notification marked as read');
        } else {
          debugPrint('[HomeScreen] Action is not warning: $action');
        }
      } else {
        debugPrint('[HomeScreen] No notifications to show');
      }
    } catch (e, stackTrace) {
      debugPrint('[HomeScreen] ❌ Error checking warnings: $e');
      debugPrint('[HomeScreen] Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: AppColors.surface,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
              ),
              items: _isFemale
                  ? [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.explore_outlined),
                        activeIcon: Icon(Icons.explore),
                        label: 'Discover',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.favorite_border),
                        activeIcon: Icon(Icons.favorite),
                        label: 'Likes',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.people_outline),
                        activeIcon: Icon(Icons.people),
                        label: 'Matches',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble_outline),
                        activeIcon: Icon(Icons.chat_bubble),
                        label: 'Chat',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildRewardsIconWithBadge(false),
                        activeIcon: _buildRewardsIconWithBadge(true),
                        label: 'Rewards',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ]
                  : const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.explore_outlined),
                        activeIcon: Icon(Icons.explore),
                        label: 'Discover',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite_border),
                        activeIcon: Icon(Icons.favorite),
                        label: 'Likes',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.people_outline),
                        activeIcon: Icon(Icons.people),
                        label: 'Matches',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat_bubble_outline),
                        activeIcon: Icon(Icons.chat_bubble),
                        label: 'Chat',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        activeIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
        ),
      ),
    );
  }
  
  Widget _buildRewardsIconWithBadge(bool isActive) {
    debugPrint('[HomeScreen] 🎨 Building rewards icon with badge. Count: $_unreadRewardNotifications, Active: $isActive');
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isActive ? Icons.emoji_events : Icons.emoji_events_outlined,
          size: 24,
        ),
        if (_unreadRewardNotifications > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  _unreadRewardNotifications > 9 ? '9+' : '$_unreadRewardNotifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}