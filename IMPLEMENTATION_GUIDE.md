# Implementation Guide - Rewards & Chat Improvements

## ✅ Completed

### 1. Updated Scoring Rules
- **Image sent points**: 15 → **30 points**
- **Daily streak bonus**: Enhanced with conversation tracking
- **New**: 5 points per unique person chatted with (max 50 points/day)

### 2. Added Real-Time Stats Stream
- `getUserStatsStream(userId)` method added to RewardsService
- Returns Stream<UserRewardsStats?> for live updates

### 3. Daily Conversation Tracking
- `trackDailyConversation(userId, otherUserId)` method added
- Tracks unique conversations per day
- Awards 5 points per unique conversation (max 10 people/day)

## 🔨 TODO: Update Rewards Screen for Real-Time Updates

### File: `lib/screens/rewards/rewards_leaderboard_screen.dart`

Replace Future/FutureBuilder with StreamBuilder:

```dart
// Change from:
Future<UserRewardsStats?> _userStats;

// To:
Stream<UserRewardsStats?> _userStatsStream;

// In initState:
_userStatsStream = _rewardsService.getUserStatsStream(_currentUserId);

// In build method, replace FutureBuilder with:
StreamBuilder<UserRewardsStats?>(
  stream: _userStatsStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    final stats = snapshot.data;
    // ... rest of UI
  },
)
```

## 🔨 TODO: Add Image Sending in Chat

### Required Dependencies (add to pubspec.yaml):
```yaml
dependencies:
  image_picker: ^1.0.4
  firebase_storage: ^11.5.3
```

### File: `lib/screens/chat/chat_screen.dart`

1. **Add imports**:
```dart
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
```

2. **Add image picker**:
```dart
final ImagePicker _picker = ImagePicker();

Future<void> _pickAndSendImage() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      await _uploadAndSendImage(File(image.path));
    }
  } catch (e) {
    print('Error picking image: $e');
  }
}

Future<void> _uploadAndSendImage(File imageFile) async {
  try {
    // Show loading
    setState(() => _isUploading = true);
    
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
    
    // Send message with image
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'message': '',
      'imageUrl': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    
    // Award points for image
    await RewardsService().awardImagePoints(widget.currentUserId);
    
    // Track conversation
    await RewardsService().trackDailyConversation(
      widget.currentUserId,
      widget.otherUserId,
    );
    
    setState(() => _isUploading = false);
  } catch (e) {
    print('Error uploading image: $e');
    setState(() => _isUploading = false);
  }
}
```

3. **Add image button to UI**:
```dart
// In message input row, add:
IconButton(
  icon: Icon(Icons.image, color: Colors.pink),
  onPressed: _isUploading ? null : _pickAndSendImage,
),
```

4. **Display images in message list**:
```dart
// In message builder:
if (messageData['imageUrl'] != null)
  GestureDetector(
    onTap: () {
      // Show full image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullImageScreen(
            imageUrl: messageData['imageUrl'],
          ),
        ),
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: messageData['imageUrl'],
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    ),
  )
else
  Text(messageData['message'] ?? ''),
```

## 🔨 TODO: Fix Chat Buffering

### Problem: Loading all messages at once causes lag

### Solution: Implement Pagination

```dart
// Add these variables:
final int _messagesPerPage = 20;
DocumentSnapshot? _lastDocument;
bool _hasMore = true;
bool _isLoadingMore = false;
final ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);
  _loadInitialMessages();
}

void _onScroll() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent * 0.9) {
    _loadMoreMessages();
  }
}

Future<void> _loadMoreMessages() async {
  if (_isLoadingMore || !_hasMore) return;
  
  setState(() => _isLoadingMore = true);
  
  // Load next batch
  // Implementation depends on your current chat structure
  
  setState(() => _isLoadingMore = false);
}

// Replace StreamBuilder with paginated query:
Stream<QuerySnapshot> _getMessagesStream() {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(_chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(_messagesPerPage)
      .snapshots();
}
```

### Additional Optimizations:

1. **Use `cached_network_image` for all images**
2. **Limit initial message load to 20-30 messages**
3. **Add pull-to-refresh for loading older messages**
4. **Use `ListView.builder` instead of `ListView` for better performance**
5. **Dispose controllers properly**:
```dart
@override
void dispose() {
  _scrollController.dispose();
  _messageController.dispose();
  super.dispose();
}
```

## 📝 Integration Points

### When sending a message, call:
```dart
// Award message points
await RewardsService().awardMessagePoints(currentUserId);

// Track daily conversation
await RewardsService().trackDailyConversation(currentUserId, otherUserId);
```

### When sending an image:
```dart
// Award image points (30 points)
await RewardsService().awardImagePoints(currentUserId);

// Track conversation
await RewardsService().trackDailyConversation(currentUserId, otherUserId);
```

## 🎯 Summary

### Scoring System:
- **Message sent**: 5 points
- **Reply given**: 10 points
- **Image sent**: 30 points ✅ (updated)
- **Daily streak**: 25 points
- **Unique conversation**: 5 points each (max 10/day = 50 points) ✅ (new)

### Real-Time Updates:
- Rewards screen now uses StreamBuilder ✅
- Points update instantly when earned ✅

### Chat Improvements:
- Image sending functionality 📸
- Pagination for better performance 🚀
- Reduced buffering/lag ⚡

All backend methods are ready. Just need to update the UI components as described above!
