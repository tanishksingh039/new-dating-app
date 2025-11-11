import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../firebase_services.dart';
import '../../services/rewards_service.dart';
import '../../models/user_model.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../../mixins/screenshot_protection_mixin.dart';

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

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _checkUserGender();
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
        
        // Get other user's online status data
        final otherUserLastActive = (otherUserData?['lastActive'] as Timestamp?)?.toDate();
        final otherUserPrivacy = otherUserData?['privacySettings'] as Map<String, dynamic>? ?? {};
        final showOnlineStatus = otherUserPrivacy['showOnlineStatus'] ?? true;
        
        debugPrint('Current user gender: $currentGender');
        debugPrint('Other user gender: $otherGender');
        debugPrint('Current user verified: $isVerified');
        debugPrint('Other user last active: $otherUserLastActive');
        debugPrint('Other user show online status: $showOnlineStatus');
        
        setState(() {
          // Check for both 'Female' and 'female' (case-insensitive)
          _isCurrentUserFemale = currentGender?.toString().toLowerCase() == 'female';
          _isOtherUserMale = otherGender?.toString().toLowerCase() == 'male';
          _isCurrentUserVerified = isVerified;
          _otherUserLastActive = otherUserLastActive;
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
    if (_otherUserLastActive == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_otherUserLastActive!);
    return difference.inMinutes < 5;
  }

  // Get last seen text for other user
  String _getOtherUserLastSeen() {
    if (_otherUserLastActive == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(_otherUserLastActive!);
    
    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Active ${difference.inDays}d ago';
    } else {
      return 'Active long ago';
    }
  }

  @override
  void dispose() {
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

    try {
      await FirebaseServices.sendMessage(
        widget.currentUserId,
        widget.otherUserId,
        messageText,
      );

      _messageController.clear();
      setState(() => _isTyping = false);

      // Award points only if female, verified, and sending to male
      if (_isCurrentUserFemale && _isOtherUserMale) {
        if (_isCurrentUserVerified) {
          await _rewardsService.awardMessagePoints(widget.currentUserId);
          await _rewardsService.trackDailyConversation(widget.currentUserId, widget.otherUserId);
          debugPrint('✅ Points awarded: Verified Female → Male message');
        } else {
          debugPrint('⚠️ No points: User not verified');
        }
      } else {
        debugPrint('⏭️ No points: Not female→male conversation');
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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

  // Pick and send image (only for female users)
  Future<void> _pickAndSendImage() async {
    debugPrint('Image button clicked. Is female: $_isCurrentUserFemale');
    
    if (!_isCurrentUserFemale) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image sharing is only available for female users. Current status: $_isCurrentUserFemale'),
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
    setState(() => _isUploading = true);

    try {
      // Upload to Firebase Storage
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.currentUserId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

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

      // Award 30 points only if female, verified, and sending to male
      if (_isCurrentUserFemale && _isOtherUserMale) {
        if (_isCurrentUserVerified) {
          debugPrint('💰 About to award image points (Verified Female → Male)...');
          try {
            await _rewardsService.awardImagePoints(widget.currentUserId);
            debugPrint('💰 Image points awarded successfully');
            
            await _rewardsService.trackDailyConversation(widget.currentUserId, widget.otherUserId);
            debugPrint('💰 Daily conversation tracked');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image sent! +30 points earned ✅'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
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
              const SnackBar(
                content: Text('Image sent! Verify your account to earn 30 points'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        debugPrint('⏭️ No points for image: Not female→male conversation');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent successfully'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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
        setState(() => _isRecording = true);
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
      final String? audioPath = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (audioPath != null) {
        debugPrint('🎤 Recording stopped: $audioPath');
        await _sendAudioMessage(audioPath);
      }
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);
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
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
      debugPrint('🎤 Recording cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling recording: $e');
    }
  }

  // Send audio message
  Future<void> _sendAudioMessage(String audioPath) async {
    setState(() => _isUploading = true);
    
    String storagePath = '';
    try {
      final File audioFile = File(audioPath);
      final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      storagePath = 'chat_audio/${widget.currentUserId}/$fileName';
      
      debugPrint('📤 Uploading audio: $storagePath');
      debugPrint('📤 User ID: ${widget.currentUserId}');
      
      // Upload to Firebase Storage with metadata
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final metadata = SettableMetadata(
        contentType: 'audio/m4a',
        customMetadata: {'uploadedBy': widget.currentUserId},
      );
      await ref.putFile(audioFile, metadata);
      final String audioUrl = await ref.getDownloadURL();
      
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
      
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
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
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
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

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == widget.currentUserId;
                    final timestamp = message['timestamp'] as Timestamp?;

                    bool showDateSeparator = false;
                    if (index == 0 ||
                        _shouldShowDateSeparator(
                          messages[index - 1].data() as Map<String, dynamic>,
                          message,
                        )) {
                      showDateSeparator = true;
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(timestamp),
                        _buildMessageBubble(
                          message['text'] ?? '',
                          isMe,
                          timestamp,
                          imageUrl: message['imageUrl'],
                          audioUrl: message['audioUrl'],
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
    );
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
      title: Row(
        children: [
          Hero(
            tag: 'avatar_${widget.otherUserId}',
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
          const SizedBox(width: 12),
          Expanded(
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
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Color(0xFF2D3142)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF2D3142)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call coming soon!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, Timestamp? timestamp, {String? imageUrl, String? audioUrl}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: (imageUrl != null || audioUrl != null)
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: audioUrl != null
                  ? _buildAudioPlayer(audioUrl, isMe)
                  : imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
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
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : const Color(0xFF2D3142),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                child: Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
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
                          // Only update state if typing status actually changed
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
            _isRecording
                ? Row(
                    children: [
                      // Cancel button
                      GestureDetector(
                        onTap: _cancelRecording,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Recording indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Recording...',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button
                      GestureDetector(
                        onTap: _stopRecordingAndSend,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFFFA07A)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
              onTap: _isTyping ? _sendMessage : null,
              onLongPress: !_isTyping && !_isUploading ? _startRecording : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _isTyping
                      ? const LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFC06C84)],
                        )
                      : null,
                  color: _isTyping ? null : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: _isTyping
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isTyping ? Icons.send_rounded : Icons.mic_outlined,
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

  // Build audio player widget
  Widget _buildAudioPlayer(String audioUrl, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: isMe ? Colors.white : const Color(0xFFFF6B9D),
              size: 32,
            ),
            onPressed: () async {
              final player = AudioPlayer();
              await player.play(UrlSource(audioUrl));
            },
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.graphic_eq,
            color: isMe ? Colors.white70 : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'Voice message',
            style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF2D3142),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Conversations list with actual data
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final userData = doc.data();
        setState(() {
          _isPremium = userData?['isPremium'] ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
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
            icon: const Icon(Icons.search, color: Color(0xFF2D3142)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(currentUserId),
    );
  }

  Widget _buildBody(String currentUserId) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B9D)),
      );
    }

    // Show lock overlay for free users
    if (!_isPremium) {
      return const PremiumLockOverlay(
        featureName: 'Chat',
        icon: Icons.chat_bubble,
      );
    }

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
          itemCount: matches.length,
          itemBuilder: (context, index) {
              final matchData = matches[index].data() as Map<String, dynamic>;
              final users = matchData['users'] as List<dynamic>;
              final otherUserId = users.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData == null) return const SizedBox.shrink();

                  final name = userData['name'] ?? 'Unknown';
                  final photos = userData['photos'] as List<dynamic>?;
                  final photoUrl = photos != null && photos.isNotEmpty
                      ? photos[0] as String?
                      : null;
                  final lastMessage = matchData['lastMessage'] ?? '';
                  final unreadCount = matchData['unreadCount_$currentUserId'] ?? 0;

                  return _buildConversationTile(
                    context,
                    otherUserId,
                    name,
                    photoUrl,
                    lastMessage,
                    unreadCount,
                    currentUserId,
                  );
                },
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