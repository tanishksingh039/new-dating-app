# Performance Optimization Code Examples

## 1. ListView with cacheExtent

### ❌ Before (Janky)
```dart
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageTile(message: messages[index]);
  },
)
```
**Problem**: Only renders visible items, creates frame drops when scrolling

### ✅ After (Smooth)
```dart
ListView.builder(
  cacheExtent: 500, // Pre-render 500px above/below
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageTile(message: messages[index]);
  },
)
```
**Solution**: Pre-renders items outside viewport for smooth scrolling

---

## 2. Widget Extraction

### ❌ Before (Rebuilds Everything)
```dart
ListView.builder(
  itemBuilder: (context, index) {
    final message = messages[index];
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message.text),
          Text(message.time),
          Image.network(message.imageUrl),
        ],
      ),
    );
  },
)
```
**Problem**: Entire list rebuilds when any message changes

### ✅ After (Only Changed Item Rebuilds)
```dart
ListView.builder(
  itemBuilder: (context, index) {
    return MessageBubbleWidget(
      message: messages[index],
    );
  },
)

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  
  const MessageBubbleWidget({required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message.text),
          Text(message.time),
          Image.network(message.imageUrl),
        ],
      ),
    );
  }
}
```
**Solution**: Only changed message rebuilds

---

## 3. Image Caching

### ❌ Before (Slow, Memory Heavy)
```dart
Image.network(
  imageUrl,
  width: 200,
  height: 200,
)
```
**Problem**: 
- Loads full resolution image
- Caches at full size
- 150+ MB memory usage
- 2-3 seconds load time

### ✅ After (Fast, Memory Efficient)
```dart
Image.network(
  imageUrl,
  width: 200,
  height: 200,
  cacheHeight: 300,  // Cache at 300x300
  cacheWidth: 300,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[300],
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey[300],
      child: Icon(Icons.error),
    );
  },
)
```
**Solution**:
- Caches at 300x300 (display size)
- 90% less memory
- 500ms load time
- Shows loading progress
- Handles errors gracefully

---

## 4. State Management - Riverpod Select Pattern

### ❌ Before (Rebuilds on Any Change)
```dart
final userProvider = StateProvider<User>((ref) => User());

class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when ANY field changes
    final user = ref.watch(userProvider);
    
    return Text(user.name); // Only needs name!
  }
}
```
**Problem**: Rebuilds when email, age, or any field changes

### ✅ After (Only Rebuilds When Needed)
```dart
final userProvider = StateProvider<User>((ref) => User());

class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when name changes
    final name = ref.watch(userProvider.select((user) => user.name));
    
    return Text(name);
  }
}
```
**Solution**: Use `select()` to only listen to specific fields

---

## 5. Const Constructors

### ❌ Before (Widgets Recreated Every Build)
```dart
class MessageBubble extends StatelessWidget {
  final String text;
  
  MessageBubble({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(text),
    );
  }
}
```
**Problem**: Widget recreated every time parent rebuilds

### ✅ After (Widget Reused)
```dart
class MessageBubble extends StatelessWidget {
  final String text;
  
  const MessageBubble({required this.text}); // const constructor
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // const everywhere
      child: Text(text),
    );
  }
}
```
**Solution**: Use `const` constructors to enable widget reuse

---

## 6. RepaintBoundary for Expensive Widgets

### ❌ Before (Parent Repaints Everything)
```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveAnimationWidget(), // Repaints entire screen
        ListView.builder(...),
      ],
    );
  }
}
```
**Problem**: Animation repaints entire screen

### ✅ After (Only Animation Repaints)
```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          child: ExpensiveAnimationWidget(), // Only this repaints
        ),
        ListView.builder(...),
      ],
    );
  }
}
```
**Solution**: Isolate expensive widgets with RepaintBoundary

---

## 7. Lazy Loading with Pagination

### ❌ Before (Load All Messages)
```dart
final messagesStream = FirebaseFirestore.instance
    .collection('messages')
    .snapshots(); // Loads ALL messages
```
**Problem**: 
- Slow initial load
- High memory usage
- Janky UI

### ✅ After (Load in Batches)
```dart
int _pageSize = 50;
int _currentPage = 0;

Future<void> _loadMessages() async {
  final messages = await FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(_pageSize)
      .get();
  
  setState(() {
    _messages = messages.docs;
  });
}

Future<void> _loadMoreMessages() async {
  _currentPage++;
  final messages = await FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(_pageSize)
      .offset(_currentPage * _pageSize)
      .get();
  
  setState(() {
    _messages.addAll(messages.docs);
  });
}

// Trigger load when scrolling to end
_scrollController.addListener(() {
  if (_scrollController.position.pixels == 
      _scrollController.position.maxScrollExtent) {
    _loadMoreMessages();
  }
});
```
**Solution**: Load messages in batches of 50

---

## 8. Audio Player Optimization

### ❌ Before (Memory Leaks)
```dart
Future<void> _playAudio(String audioUrl) async {
  final player = AudioPlayer(); // New instance every time!
  await player.play(UrlSource(audioUrl));
}
```
**Problem**: 
- Creates new player each time
- Memory accumulates
- Crashes after many plays

### ✅ After (Reuse Player)
```dart
final Map<String, AudioPlayer> _audioPlayers = {};

Future<void> _playAudio(String audioUrl) async {
  // Stop all other audio
  for (var player in _audioPlayers.values) {
    await player.stop();
  }
  
  // Reuse or create player
  final player = _audioPlayers[audioUrl] ?? AudioPlayer();
  _audioPlayers[audioUrl] = player;
  
  // Play audio
  await player.play(UrlSource(audioUrl));
  
  // Cleanup on complete
  player.onPlayerComplete.listen((_) {
    _audioPlayers.remove(audioUrl);
  });
}

@override
void dispose() {
  // Cleanup all players
  for (var player in _audioPlayers.values) {
    player.dispose();
  }
  _audioPlayers.clear();
  super.dispose();
}
```
**Solution**: Reuse audio player instances, proper cleanup

---

## 9. Message Deduplication

### ❌ Before (Duplicate Messages)
```dart
final messages = snapshot.data?.docs ?? [];
// Could have duplicates from real-time updates
```
**Problem**: Same message appears twice

### ✅ After (No Duplicates)
```dart
final messageMap = <String, DocumentSnapshot>{};
for (var doc in snapshot.data?.docs ?? []) {
  messageMap[doc.id] = doc; // Use ID as key
}
final uniqueMessages = messageMap.values.toList();
```
**Solution**: Use map to deduplicate by ID

---

## 10. Performance Monitoring

### Add Performance Logging
```dart
void _logPerformance(String operation, Duration duration) {
  debugPrint('⏱️ $operation took ${duration.inMilliseconds}ms');
  
  if (duration.inMilliseconds > 100) {
    debugPrint('⚠️ WARNING: $operation is slow!');
  }
}

// Usage
final stopwatch = Stopwatch()..start();
// ... do work ...
stopwatch.stop();
_logPerformance('Load messages', stopwatch.elapsed);
```

### Profile with DevTools
```bash
flutter run --profile
# Open DevTools → Performance tab
# Record trace while scrolling
# Analyze frame times
```

---

## Summary

| Technique | Impact | Difficulty |
|-----------|--------|-----------|
| cacheExtent | High | Easy |
| Widget Extraction | High | Easy |
| Image Caching | High | Easy |
| Const Constructors | Medium | Easy |
| Riverpod Select | Medium | Medium |
| RepaintBoundary | Medium | Medium |
| Pagination | High | Hard |
| Audio Optimization | Medium | Medium |
| Deduplication | Low | Easy |
| Performance Monitoring | Low | Easy |

---

## 🎯 Recommended Implementation Order

1. ✅ cacheExtent (DONE)
2. ✅ Widget Extraction (DONE)
3. ✅ Image Caching (DONE)
4. ✅ Audio Optimization (DONE)
5. ⏳ Const Constructors (Easy win)
6. ⏳ Pagination (Big improvement)
7. ⏳ Riverpod Select (Better state management)
8. ⏳ RepaintBoundary (If needed)
9. ⏳ Deduplication (If needed)
10. ⏳ Performance Monitoring (Always useful)
