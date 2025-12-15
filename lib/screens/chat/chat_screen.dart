import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../firebase_services.dart';
import '../../services/rewards_service.dart';
import '../../services/r2_storage_service.dart';
import '../../services/presence_service.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../utils/firestore_extensions.dart';
import '../../mixins/screenshot_protection_mixin.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../../widgets/recording_overlay_widget.dart';
import '../safety/report_user_screen.dart';
import '../safety/block_user_screen.dart';
import '../../services/user_safety_service.dart';
import '../../providers/premium_provider.dart';
import '../../models/rewards_model.dart'; // Add import for ScoringRules from rewards_model

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with ScreenshotProtectionMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final RewardsService _rewardsService = RewardsService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isTyping = false;
  bool _isUploading = false;
  bool _isRecording = false;
  bool _isCurrentUserFemale = false;
  bool _isOtherUserMale = false;
  bool _isCurrentUserVerified = false;
  DateTime? _otherUserLastActive;
  bool _otherUserShowOnlineStatus = true;
  final PresenceService _presenceService = PresenceService();
  StreamSubscription<DateTime?>? _presenceSubscription;
  
  // Audio recording UI state
  final ValueNotifier<Duration> _recordingDurationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<List<double>> _waveformDataNotifier = ValueNotifier([]);
  Timer? _recordingTimer;
  double _slideOffset = 0.0;
  
  // Audio player state
  final Map<String, bool> _audioPlayingStates = {};
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, bool> _audioLoadingStates = {};

  // Search state
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _checkUserGender();
    _listenToOtherUserPresence();
  }
  
  /// Listen to other user's presence in real-time
  void _listenToOtherUserPresence() {
    _presenceSubscription = _presenceService
        .getUserLastActiveStream(widget.otherUserId)
        .listen((lastActive) {
          if (mounted) {
            setState(() {
              _otherUserLastActive = lastActive;
            });
          }
        });
  }

  // Check if current user is female and other user is male
  Future<void> _checkUserGender() async {
    try {
      // Check current user gender
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      
      // Check other user gender
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (currentUserDoc.exists && otherUserDoc.exists) {
        final currentUserData = currentUserDoc.data();
        final otherUserData = otherUserDoc.data();
        
        final currentGender = currentUserData?['gender'];
        final otherGender = otherUserData?['gender'];
        final isVerified = currentUserData?['isVerified'] ?? false;
        
        // Get other user's privacy settings
        final otherUserPrivacy = otherUserData?['privacySettings'] as Map<String, dynamic>? ?? {};
        final showOnlineStatus = otherUserPrivacy['showOnlineStatus'] ?? true;
        
        debugPrint('Current user gender: $currentGender');
        debugPrint('Other user gender: $otherGender');
        debugPrint('Current user verified: $isVerified');
        debugPrint('Other user show online status: $showOnlineStatus');
        
        setState(() {
          // Check for both 'Female' and 'female' (case-insensitive)
          _isCurrentUserFemale = currentGender?.toString().toLowerCase() == 'female';
          _isOtherUserMale = otherGender?.toString().toLowerCase() == 'male';
          _isCurrentUserVerified = isVerified;
          _otherUserShowOnlineStatus = showOnlineStatus;
        });
        
        debugPrint('Is current user female: $_isCurrentUserFemale');
        debugPrint('Is other user male: $_isOtherUserMale');
        debugPrint('Is current user verified: $_isCurrentUserVerified');
        debugPrint('Can earn points: ${_isCurrentUserFemale && _isOtherUserMale && _isCurrentUserVerified}');
      } else {
        debugPrint('User document(s) do not exist');
      }
    } catch (e) {
      debugPrint('Error checking user gender: $e');
    }
  }

  // Show verification required dialog
  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Verification Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to verify your account to earn points!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Benefits of verification:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildBenefit('✅ Earn points for messages'),
            _buildBenefit('✅ Earn 30 points per image'),
            _buildBenefit('✅ Appear on leaderboard'),
            _buildBenefit('✅ Build trust with matches'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to liveness verification in settings
              Navigator.pushNamed(context, '/settings/verification');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Verify Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  // Check if other user is online (active within last 5 minutes)
  bool _isOtherUserOnline() {
    return PresenceService.isUserOnline(_otherUserLastActive);
  }

  // Get last seen text for other user
  String _getOtherUserLastSeen() {
    return PresenceService.getLastSeenText(_otherUserLastActive);
  }

  @override
  void dispose() {
    _presenceSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    try {
      await FirebaseServices.markMessagesAsRead(
        currentUserId: widget.currentUserId,
        otherUserId: widget.otherUserId,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Clear input immediately for smooth UX (like WhatsApp)
    _messageController.clear();
    if (_isTyping) {
      setState(() => _isTyping = false);
    }

    try {
      await FirebaseServices.sendMessage(
        widget.currentUserId,
        widget.otherUserId,
        messageText,
      );

      // Award points only if female, verified, and sending to male (before clearing message)
      if (_isCurrentUserFemale && _isOtherUserMale) {
        if (_isCurrentUserVerified) {
          final chatId = _getChatId(widget.currentUserId, widget.otherUserId);
          await _rewardsService.awardMessagePoints(
            widget.currentUserId,
            chatId,
            messageText, // Use the saved messageText before it was cleared
            otherUserId: widget.otherUserId,
          );
          await _rewardsService.trackDailyConversation(widget.currentUserId, widget.otherUserId);
          debugPrint('✅ Points awarded: Verified Female → Male message');
        } else {
          debugPrint('⚠️ No points: User not verified');
        }
      } else {
        debugPrint('⏭️ No points: Not female→male conversation');
      }

      // Scroll to bottom after sending message (reverse list, so scroll to 0)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Delete message from Firestore
  Future<void> _deleteMessageFromFirestore(String messageId) async {
    try {
      final chatId = _getChatId(widget.currentUserId, widget.otherUserId);
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  /// Edit message in Firestore
  Future<void> _editMessageInFirestore(String messageId, String newText) async {
    try {
      final chatId = _getChatId(widget.currentUserId, widget.otherUserId);
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'text': newText,
            'edited': true,
            'editedAt': Timestamp.now(),
          });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message edited'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing message: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // Pick and send image (only for female users)
  Future<void> _pickAndSendImage() async {
    debugPrint('Image button clicked. Is female: $_isCurrentUserFemale');
    
    if (!_isCurrentUserFemale) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You can't send images,Guess What? Your Women Can. Current status: $_isCurrentUserFemale"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAndSendImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // Upload image to Firebase Storage and send message
  Future<void> _uploadAndSendImage(File imageFile) async {
    if (!_isUploading) {
      setState(() => _isUploading = true);
    }

    try {
      // Upload to Cloudflare R2 (FREE downloads, auto-compression)
      final String downloadUrl = await R2StorageService.uploadImage(
        imageFile: imageFile,
        folder: 'chat_images',
        userId: widget.currentUserId,
      );

      // Get chat ID
      final chatId = _getChatId(widget.currentUserId, widget.otherUserId);

      // Send message with image
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'receiverId': widget.otherUserId,
        'text': '',
        'imageUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message in chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'users': [widget.currentUserId, widget.otherUserId],
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': widget.currentUserId,
      }, SetOptions(merge: true));

      // Award image points only if female, verified, and sending to male
      if (_isCurrentUserFemale && _isOtherUserMale) {
        if (_isCurrentUserVerified) {
          debugPrint('💰 About to award image points (Verified Female → Male)...');
          try {
            final chatId = _getChatId(widget.currentUserId, widget.otherUserId);
            
            // Get user's profile photo for MANDATORY face verification
            String? profilePhotoPath;
            bool profilePhotoFetched = false;
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .get();
              if (userDoc.exists) {
                final userData = userDoc.data();
                final photos = userData?['photos'] as List<dynamic>?;
                if (photos != null && photos.isNotEmpty) {
                  final profilePhotoUrl = photos[0] as String;
                  final Directory appDocDir = await getApplicationDocumentsDirectory();
                  final String filePath = '${appDocDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final File file = File(filePath);
                  final http.Response response = await http.get(Uri.parse(profilePhotoUrl)).timeout(const Duration(seconds: 10));
                  if (response.statusCode == 200) {
                    await file.writeAsBytes(response.bodyBytes);
                    profilePhotoPath = filePath;
                    profilePhotoFetched = true;
                    debugPrint('✅ Profile photo fetched for face verification');
                  } else {
                    debugPrint('❌ Could not fetch profile photo: ${response.statusCode}');
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ Could not fetch profile photo: $e');
            }
            
            // Award points with mandatory face verification
            try {
              await _rewardsService.awardImagePoints(
                widget.currentUserId,
                chatId,
                imageFile.path,
                profileImagePath: profilePhotoPath,
                otherUserId: widget.otherUserId,
              );
              debugPrint('💰 Image points awarded successfully');
              
              await _rewardsService.trackDailyConversation(widget.currentUserId, widget.otherUserId);
              debugPrint('💰 Daily conversation tracked');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Image sent! +${ScoringRules.imageSentPoints} points earned ✅'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ Error awarding points: $e');
              if (mounted) {
                // Check if it's a face verification failure
                if (e.toString().contains('FACE') || !profilePhotoFetched) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Image sent but face verification failed - no points awarded'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Image sent but error awarding points: $e'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('❌ Error awarding points: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image sent but error awarding points: $e'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        } else {
          debugPrint('⚠️ No points for image: User not verified');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image sent! Verify your account to earn ${ScoringRules.imageSentPoints} points'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        debugPrint('⏭️ No points for image: Not female→male conversation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image sent successfully'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Scroll to bottom after sending image (reverse list, so scroll to 0)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Start audio recording
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        
        setState(() {
          _isRecording = true;
          _slideOffset = 0.0;
        });
        
        // Reset notifiers
        _recordingDurationNotifier.value = Duration.zero;
        _waveformDataNotifier.value = [];
        
        // Start timer and waveform generation (NO setState!)
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_isRecording) {
            // Update waveform data via notifier (no setState!)
            final newWaveform = List<double>.from(_waveformDataNotifier.value);
            newWaveform.add(0.3 + (timer.tick % 7) * 0.1);
            if (newWaveform.length > 40) {
              newWaveform.removeAt(0);
            }
            _waveformDataNotifier.value = newWaveform;
            
            // Update duration every second via notifier (no setState!)
            if (timer.tick % 10 == 0) {
              _recordingDurationNotifier.value = Duration(seconds: timer.tick ~/ 10);
            }
          }
        });
        
        debugPrint('🎤 Recording started: $filePath');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  // Stop recording and send audio
  Future<void> _stopRecordingAndSend() async {
    try {
      _recordingTimer?.cancel();
      final String? audioPath = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _slideOffset = 0.0;
      });
      
      // Reset notifiers
      _recordingDurationNotifier.value = Duration.zero;
      _waveformDataNotifier.value = [];
      
      if (audioPath != null) {
        debugPrint('🎤 Recording stopped: $audioPath');
        await _sendAudioMessage(audioPath);
      }
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _slideOffset = 0.0;
      });
      _recordingDurationNotifier.value = Duration.zero;
      _waveformDataNotifier.value = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    }
  }

  // Cancel recording
  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
        _slideOffset = 0.0;
      });
      
      // Reset notifiers
      _recordingDurationNotifier.value = Duration.zero;
      _waveformDataNotifier.value = [];
      
      debugPrint('🎤 Recording cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling recording: $e');
    }
  }

  // Send audio message
  Future<void> _sendAudioMessage(String audioPath) async {
    if (!_isUploading) {
      setState(() => _isUploading = true);
    }
    
    String storagePath = '';
    try {
      final File audioFile = File(audioPath);
      final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      storagePath = 'chat_audio/${widget.currentUserId}/$fileName';
      
      debugPrint('📤 Uploading audio: $storagePath');
      debugPrint('📤 User ID: ${widget.currentUserId}');
      
      // Upload to Cloudflare R2 (FREE downloads)
      final String audioUrl = await R2StorageService.uploadImage(
        imageFile: audioFile,
        folder: 'voice_notes',
        userId: widget.currentUserId,
      );
      
      debugPrint('✅ Audio uploaded: $audioUrl');
      
      // Send message with audio URL
      await FirebaseServices.sendMessage(
        widget.currentUserId,
        widget.otherUserId,
        '',
        audioUrl: audioUrl,
      );
      
      // Delete local file
      await audioFile.delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio sent successfully! 🎤'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Scroll to bottom after sending audio (reverse list, so scroll to 0)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error sending audio: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Storage path attempted: $storagePath');
      debugPrint('❌ Current user ID: ${widget.currentUserId}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending audio: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (_isUploading) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B9D)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFFF6B9D)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseServices.getMessages(
                    widget.currentUserId,
                    widget.otherUserId,
                  ),
                  builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B9D),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var messages = snapshot.data?.docs ?? [];

                // Filter messages based on search query
                if (_searchQuery.isNotEmpty) {
                  messages = messages.where((doc) {
                    final message = doc.safeData();
                    if (message == null) return false;
                    final text = (message['text'] ?? '').toString().toLowerCase();
                    return text.contains(_searchQuery);
                  }).toList();
                }

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  cacheExtent: 500, // Pre-render 500px above/below viewport for smooth scrolling
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // Reverse the index since we're using reverse: true
                    final reversedIndex = messages.length - 1 - index;
                    final messageDoc = messages[reversedIndex];
                    final message = messageDoc.safeData();
                    if (message == null) return const SizedBox.shrink();
                    final isMe = message['senderId'] == widget.currentUserId;
                    final timestamp = message['timestamp'] as Timestamp?;

                    bool showDateSeparator = false;
                    if (reversedIndex == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMessage = messages[reversedIndex - 1].safeData();
                      if (prevMessage != null && _shouldShowDateSeparator(prevMessage, message)) {
                        showDateSeparator = true;
                      }
                    }

                    return Column(
                      key: ValueKey(messageDoc.id),
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(timestamp),
                        // Extract to separate widget to prevent unnecessary rebuilds
                        MessageBubbleWidget(
                          text: message['text'] ?? '',
                          isMe: isMe,
                          timestamp: timestamp,
                          imageUrl: message['imageUrl'],
                          audioUrl: message['audioUrl'],
                          onAudioPlaybackToggle: _toggleAudioPlayback,
                          audioPlayingStates: _audioPlayingStates,
                          audioLoadingStates: _audioLoadingStates,
                          audioPlayers: _audioPlayers,
                          context: context,
                          messageId: messageDoc.id,
                          currentUserId: widget.currentUserId,
                          otherUserId: widget.otherUserId,
                          onDelete: () => _deleteMessageFromFirestore(messageDoc.id),
                          onEdit: (newText) => _editMessageInFirestore(messageDoc.id, newText),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
            ],
          ),
          // Recording overlay (separate from main column to prevent rebuilds)
          if (_isRecording) ...[
            // Semi-transparent barrier to prevent interaction with messages
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // Absorb taps
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            // Recording controls at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<Duration>(
                valueListenable: _recordingDurationNotifier,
                builder: (context, duration, child) {
                  return ValueListenableBuilder<List<double>>(
                    valueListenable: _waveformDataNotifier,
                    builder: (context, waveformData, child) {
                      return RecordingOverlayWidget(
                        recordingDuration: duration,
                        waveformData: waveformData,
                        onCancel: _cancelRecording,
                        onSend: _stopRecordingAndSend,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOptionsBottomSheet() async {
    // First get the other user's data
    UserModel? otherUser;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        if (data is Map<String, dynamic>) {
          otherUser = UserModel.fromMap(data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    if (otherUser == null) return;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report User'),
              subtitle: const Text('Report inappropriate behavior'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportUserScreen(reportedUser: otherUser!),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              subtitle: const Text('You won\'t see each other'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlockUserScreen(userToBlock: otherUser!),
                  ),
                ).then((blocked) {
                  if (blocked == true) {
                    Navigator.pop(context); // Go back to matches/chat list
                  }
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Show user profile preview (WhatsApp style)
  void _showUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();
      
      if (!doc.exists || !mounted) return;
      
      final userData = doc.data();
      if (userData == null) return;
      
      final user = UserModel.fromMap(userData);
      final photos = user.photos;
      final photoUrl = photos.isNotEmpty ? photos.first : null;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              // Full-screen background
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
              // Profile content
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile image
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              photoUrl,
                              width: 300,
                              height: 400,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 300,
                                  height: 400,
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 300,
                                  height: 400,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      // User info card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Age and Gender
                            if (user.dateOfBirth != null)
                              Text(
                                '${_calculateAge(user.dateOfBirth!)}, ${user.gender ?? 'Not specified'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Bio
                            if (user.bio != null && user.bio!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.bio!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            const SizedBox(height: 16),
                            // Verification badge
                            if (user.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.message),
                                    label: const Text('Message'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6B9D),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showOptionsBottomSheet();
                                    },
                                    icon: const Icon(Icons.more_horiz),
                                    label: const Text('More'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2D3142),
                                      side: const BorderSide(
                                        color: Color(0xFFFF6B9D),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing user profile: $e');
    }
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  PreferredSizeWidget _buildAppBar() {
    final initials = widget.otherUserName.split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _showUserProfile,
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.otherUserId}',
              child: GestureDetector(
                onTap: _showUserProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.otherUserPhoto != null
                      ? NetworkImage(widget.otherUserPhoto!)
                      : null,
                  backgroundColor: const Color(0xFFFF6B9D),
                  child: widget.otherUserPhoto == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _showUserProfile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        color: Color(0xFF2D3142),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Online status - only show if user allows it
                    if (_otherUserShowOnlineStatus && _otherUserLastActive != null)
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isOtherUserOnline() ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOtherUserOnline() ? 'Online' : _getOtherUserLastSeen(),
                            style: TextStyle(
                              color: _isOtherUserOnline() ? Colors.green : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF2D3142)),
          onPressed: () {
            setState(() => _isSearching = !_isSearching);
            if (!_isSearching) {
              _searchController.clear();
              _searchQuery = '';
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF2D3142)),
          onPressed: _showOptionsBottomSheet,
        ),
        const SizedBox(width: 8),
      ],
    );
  }


  Widget _buildMessageInput() {
    return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Color(0xFFADB5BD),
                                  fontSize: 15,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2D3142),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                final isTyping = value.trim().isNotEmpty;
                                if (_isTyping != isTyping) {
                                  setState(() {
                                    _isTyping = isTyping;
                                  });
                                }
                              },
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    color: _isCurrentUserFemale 
                                        ? const Color(0xFFFF6B9D)
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                            onPressed: _isUploading ? null : _pickAndSendImage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Microphone or Send button
                  GestureDetector(
                    onTap: () {
                      if (_isTyping) {
                        _sendMessage();
                      } else if (!_isUploading) {
                        // Show toast to inform user about long-hold
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Long hold to record audio 🎤'),
                            backgroundColor: Color(0xFF128C7E),
                            duration: Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    onLongPress: !_isTyping && !_isUploading ? _startRecording : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isTyping 
                            ? const Color(0xFF128C7E)
                            : const Color(0xFF128C7E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF128C7E).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isTyping ? Icons.send_rounded : Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: Color(0xFFFF6B9D),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start the conversation',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hi to ${widget.otherUserName}!',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(timestamp),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(
    Map<String, dynamic> previousMessage,
    Map<String, dynamic> currentMessage,
  ) {
    final prevTimestamp = previousMessage['timestamp'] as Timestamp?;
    final currTimestamp = currentMessage['timestamp'] as Timestamp?;

    if (prevTimestamp == null || currTimestamp == null) return false;

    final prevDate = prevTimestamp.toDate();
    final currDate = currTimestamp.toDate();

    return prevDate.day != currDate.day ||
        prevDate.month != currDate.month ||
        prevDate.year != currDate.year;
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  // Generate chat ID from two user IDs (sorted alphabetically)
  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  // Build audio player widget with waveform
  Widget _buildAudioPlayer(String audioUrl, bool isMe) {
    final isPlaying = _audioPlayingStates[audioUrl] ?? false;
    final isLoading = _audioLoadingStates[audioUrl] ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button with loading state
          GestureDetector(
            onTap: isLoading ? null : () => _toggleAudioPlayback(audioUrl),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withOpacity(0.2) : const Color(0xFF128C7E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMe ? Colors.white : const Color(0xFF128C7E),
                        ),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isMe ? Colors.white : const Color(0xFF128C7E),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Waveform visualization
          Expanded(
            child: _buildStaticWaveform(isMe, isPlaying),
          ),
          const SizedBox(width: 8),
          // Duration text
          Text(
            '0:06',
            style: TextStyle(
              color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Toggle audio playback
  Future<void> _toggleAudioPlayback(String audioUrl) async {
    try {
      final isCurrentlyPlaying = _audioPlayingStates[audioUrl] ?? false;
      
      if (isCurrentlyPlaying) {
        // Pause
        await _audioPlayers[audioUrl]?.pause();
        setState(() {
          _audioPlayingStates[audioUrl] = false;
          _audioLoadingStates[audioUrl] = false;
        });
      } else {
        // Show loading state immediately
        setState(() {
          _audioLoadingStates[audioUrl] = true;
        });
        
        // Stop all other audio
        for (var player in _audioPlayers.values) {
          await player.stop();
        }
        _audioPlayingStates.updateAll((key, value) => false);
        _audioLoadingStates.updateAll((key, value) => false);
        
        // Play this audio
        final player = _audioPlayers[audioUrl] ?? AudioPlayer();
        _audioPlayers[audioUrl] = player;
        
        player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _audioPlayingStates[audioUrl] = false;
              _audioLoadingStates[audioUrl] = false;
            });
          }
        });
        
        try {
          await player.play(UrlSource(audioUrl));
          setState(() {
            _audioLoadingStates[audioUrl] = false;
            _audioPlayingStates[audioUrl] = true;
          });
        } catch (e) {
          debugPrint('Error starting audio playback: $e');
          setState(() {
            _audioLoadingStates[audioUrl] = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() {
        _audioLoadingStates[audioUrl] = false;
      });
    }
  }
  
  // Build static waveform for audio messages
  Widget _buildStaticWaveform(bool isMe, bool isPlaying) {
    final waveformBars = List.generate(25, (index) {
      final heights = [0.3, 0.5, 0.7, 0.9, 0.6, 0.4, 0.8, 0.5, 0.6, 0.7, 0.5, 0.4, 0.6, 0.8, 0.5, 0.7, 0.4, 0.6, 0.5, 0.8, 0.6, 0.4, 0.7, 0.5, 0.6];
      return heights[index % heights.length];
    });
    
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          waveformBars.length,
          (index) {
            final height = waveformBars[index];
            return Container(
              width: 2,
              height: 4 + (height * 16),
              decoration: BoxDecoration(
                color: isMe 
                    ? Colors.white.withOpacity(isPlaying ? 0.9 : 0.5)
                    : const Color(0xFF128C7E).withOpacity(isPlaying ? 0.9 : 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Optimized conversation tile widget - extracted to prevent unnecessary rebuilds
class ConversationTileWidget extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final String otherUserId;
  final String currentUserId;
  final String searchQuery;

  const ConversationTileWidget({
    required this.matchData,
    required this.otherUserId,
    required this.currentUserId,
    required this.searchQuery,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = userSnapshot.data?.safeData();
        if (userData == null) return const SizedBox.shrink();

        final name = userData['name'] ?? 'Unknown';
        final photos = userData['photos'] as List<dynamic>?;
        final photoUrl = photos != null && photos.isNotEmpty
            ? photos[0] as String?
            : null;
        final lastMessage = matchData['lastMessage'] ?? '';
        final unreadCount = matchData['unreadCount_$currentUserId'] ?? 0;

        // Filter by search query
        if (searchQuery.isNotEmpty && 
            !name.toLowerCase().contains(searchQuery)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Hero(
            tag: 'avatar_$otherUserId',
            child: CircleAvatar(
              radius: 28,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              backgroundColor: const Color(0xFFFF6B9D),
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      name.split(' ').take(2).map((e) => e[0]).join('').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            lastMessage,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: unreadCount > 0
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B9D),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                  otherUserName: name,
                  otherUserPhoto: photoUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Optimized message bubble widget - extracted to prevent unnecessary rebuilds
class MessageBubbleWidget extends StatefulWidget {
  final String text;
  final bool isMe;
  final Timestamp? timestamp;
  final String? imageUrl;
  final String? audioUrl;
  final Function(String) onAudioPlaybackToggle;
  final Map<String, bool> audioPlayingStates;
  final Map<String, bool> audioLoadingStates;
  final Map<String, AudioPlayer> audioPlayers;
  final BuildContext context;
  final String messageId;
  final String currentUserId;
  final String otherUserId;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;

  const MessageBubbleWidget({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imageUrl,
    this.audioUrl,
    required this.onAudioPlaybackToggle,
    required this.audioPlayingStates,
    required this.audioLoadingStates,
    required this.audioPlayers,
    required this.context,
    required this.messageId,
    required this.currentUserId,
    required this.otherUserId,
    this.onDelete,
    this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  State<MessageBubbleWidget> createState() => _MessageBubbleWidgetState();
}

class _MessageBubbleWidgetState extends State<MessageBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _doubleTapController;
  Map<String, int> reactions = {}; // emoji -> count
  bool _showReactionPicker = false;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();
    _doubleTapController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _doubleTapLike() {
    // Add reaction to the list (will show below message)
    setState(() {
      reactions['❤️'] = (reactions['❤️'] ?? 0) + 1;
    });
    // Play animation but it won't show (hidden by condition)
    _doubleTapController.forward().then((_) {
      _doubleTapController.reverse();
    });
  }

  void _showMessageMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Reactions
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'React',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['❤️', '😂', '😮', '😢', '🔥', '👍', '👎', '🙏']
                    .map((emoji) => GestureDetector(
                          onTap: () {
                            setState(() {
                              reactions[emoji] = (reactions[emoji] ?? 0) + 1;
                            });
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // Edit (only for own messages)
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFFFF6B9D)),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog();
                },
              ),
            // Delete
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage();
              },
            ),
            // Copy (for text messages)
            if (widget.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF2D3142)),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
            // Forward
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF2D3142)),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Forward feature coming soon'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edit your message',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onEdit?.call(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDelete?.call();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onDoubleTap: _doubleTapLike,
        onLongPress: _showMessageMenu,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: (widget.imageUrl != null || widget.audioUrl != null)
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: widget.isMe
                          ? const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                            )
                          : null,
                      color: widget.isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                        bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.audioUrl != null
                        ? _buildAudioPlayer(widget.audioUrl!, widget.isMe)
                        : widget.imageUrl != null
                            ? _buildOptimizedImage(widget.imageUrl!)
                            : Text(
                                widget.text,
                                style: TextStyle(
                                  color: widget.isMe ? Colors.white : const Color(0xFF2D3142),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                  ),
                  // Heart animation hidden - reaction shows below instead
                  const SizedBox.shrink(),
                ],
              ),
              // Reactions display
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: reactions.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                reactions[e.key] = e.value - 1;
                                if (reactions[e.key]! <= 0) {
                                  reactions.remove(e.key);
                                }
                              });
                            },
                            child: Text(
                              '${e.key} ${e.value > 1 ? e.value : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (widget.timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(widget.timestamp!),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                      // Message status indicator (for sent messages)
                      if (widget.isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _buildMessageStatus(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build message status indicator (✓ sent, ✓✓ delivered, ✓✓ read in blue)
  Widget _buildMessageStatus() {
    // For now, show as "sent" (✓)
    // In a real app, this would be fetched from Firestore
    // Status can be: sent (✓), delivered (✓✓), read (✓✓ blue)
    return const Text(
      '✓',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Optimized image widget with caching and preview
  Widget _buildOptimizedImage(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImagePreview(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          cacheHeight: 300,
          cacheWidth: 300,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        ),
      ),
    );
  }

  /// Show full-screen image preview
  void _showImagePreview(String imageUrl) {
    showDialog(
      context: widget.context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full-screen image
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.white, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Audio player widget
  Widget _buildAudioPlayer(String audioUrl, bool isMe) {
    final isPlaying = widget.audioPlayingStates[audioUrl] ?? false;
    final isLoading = widget.audioLoadingStates[audioUrl] ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isLoading ? null : () => widget.onAudioPlaybackToggle(audioUrl),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMe ? Colors.white.withOpacity(0.2) : const Color(0xFF128C7E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMe ? Colors.white : const Color(0xFF128C7E),
                        ),
                      ),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isMe ? Colors.white : const Color(0xFF128C7E),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStaticWaveform(isMe, isPlaying),
          ),
          const SizedBox(width: 8),
          Text(
            '0:06',
            style: TextStyle(
              color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Static waveform for audio
  Widget _buildStaticWaveform(bool isMe, bool isPlaying) {
    final waveformBars = List.generate(25, (index) {
      final heights = [0.3, 0.5, 0.7, 0.9, 0.6, 0.4, 0.8, 0.5, 0.6, 0.7, 0.5, 0.4, 0.6, 0.8, 0.5, 0.7, 0.4, 0.6, 0.5, 0.8, 0.6, 0.4, 0.7, 0.5, 0.6];
      return heights[index % heights.length];
    });
    
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          waveformBars.length,
          (index) {
            final height = waveformBars[index];
            return Container(
              width: 2,
              height: 4 + (height * 16),
              decoration: BoxDecoration(
                color: isMe 
                    ? Colors.white.withOpacity(isPlaying ? 0.9 : 0.5)
                    : const Color(0xFF128C7E).withOpacity(isPlaying ? 0.9 : 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Conversations list with actual data
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Refresh premium status on screen load to ensure real-time display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PremiumProvider>(context, listen: false).refreshPremiumStatus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshChats() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chats refreshed!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFFFF6B9D),
        ),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3142)),
            onPressed: _refreshChats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF2D3142),
            ),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Close Search' : 'Search',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        color: const Color(0xFFFF6B9D),
        child: _buildBody(currentUserId),
      ),
    );
  }

  Widget _buildBody(String currentUserId) {
    // Use Consumer to listen to real-time premium status changes
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        final isPremium = premiumProvider.isPremium;
        
        debugPrint('[ConversationsScreen] 🔄 Premium status: $isPremium');
        
        // Show lock overlay for free users
        if (!isPremium) {
          return const PremiumLockOverlay(
            featureName: 'Chat',
            icon: Icons.chat_bubble,
          );
        }
        
        return Column(
          children: [
            if (_isSearching) _buildSearchField(),
            Expanded(child: _buildChatsList(currentUserId)),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B9D)),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }
  
  Widget _buildChatsList(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start matching to begin chatting!',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final matches = snapshot.data!.docs;

        return ListView.builder(
          cacheExtent: 500, // Pre-render 500px above/below viewport for smooth scrolling
          itemCount: matches.length,
          itemBuilder: (context, index) {
              final matchData = matches[index].safeData();
              if (matchData == null) return const SizedBox.shrink();
              final users = matchData['users'] as List<dynamic>;
              final otherUserId = users.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return ConversationTileWidget(
                matchData: matchData,
                otherUserId: otherUserId,
                currentUserId: currentUserId,
                searchQuery: _searchQuery,
              );
            },
          );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    String otherUserId,
    String name,
    String? photoUrl,
    String lastMessage,
    int unreadCount,
    String currentUserId,
  ) {
    final initials = name.split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar_$otherUserId',
          child: CircleAvatar(
            radius: 28,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            backgroundColor: const Color(0xFFFF6B9D),
            child: photoUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Text(
          lastMessage.isNotEmpty ? lastMessage : 'Start chatting...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                currentUserId: currentUserId,
                otherUserId: otherUserId,
                otherUserName: name,
                otherUserPhoto: photoUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}