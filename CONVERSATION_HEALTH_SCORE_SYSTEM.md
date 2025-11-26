# 🔥 CONVERSATION HEALTH SCORE (CHS) SYSTEM

## 📊 Overview

The Conversation Health Score (CHS) system evaluates the quality and engagement level of each conversation based on 4 key metrics.

---

## 🎯 CHS Components

### **1. Reply Speed Score (0-10 points)**
Measures how quickly you reply to messages.

```
Reply < 30 minutes  = 10 points ⚡
Reply < 60 minutes  = 8 points  ✅
Reply < 120 minutes = 5 points  ⚠️
Reply > 120 minutes = 2 points  ❌
```

**Example:**
- User A sends message at 10:00 AM
- User B replies at 10:15 AM (15 min)
- Score: 10 points

---

### **2. Message Length Score (0-5 points)**
Measures average message length (word count).

```
Average > 6 words  = 5 points 📝
Average > 4 words  = 3 points 📄
Average > 2 words  = 1 point  ✏️
Average ≤ 2 words  = 0 points ❌
```

**Example:**
- Message 1: "Hey, how are you doing today?" (6 words)
- Message 2: "I'm great, thanks for asking!" (5 words)
- Average: 5.5 words
- Score: 5 points

---

### **3. Engagement Score (0-3 points)**
Measures use of emojis and voice notes.

```
30%+ messages with emoji/voice = 3 points 🎉
15-30% messages with emoji/voice = 2 points 😊
5-15% messages with emoji/voice = 1 point 😐
< 5% messages with emoji/voice = 0 points 😶
```

**Example:**
- 10 messages total
- 4 messages with emojis
- Percentage: 40%
- Score: 3 points

---

### **4. Consistency Score (0-5 points)**
Measures daily messaging consistency (last 7 days).

```
6-7 days with messages = 5 points 🔥
4-5 days with messages = 4 points ✅
2-3 days with messages = 3 points 🌡️
1 day with messages    = 1 point  ❄️
0 days with messages   = 0 points ❌
```

**Example:**
- Messaged on: Mon, Tue, Wed, Fri, Sat (5 days)
- Score: 4 points

---

## 🏆 Total CHS & Health Status

### **CHS Calculation**
```
Total CHS = Reply Speed + Message Length + Engagement + Consistency
```

### **Health Status & Bonuses**

| CHS Score | Status | Bonus Points | Meaning |
|-----------|--------|--------------|---------|
| **> 15** | 🔥 Hot | **+25 points** | Excellent engagement |
| **8-15** | 🌡️ Warm | **+15 points** | Good engagement |
| **< 8** | ❄️ Cold | **+5 points** | Low engagement |

---

## 📈 Real-World Examples

### **Example 1: Hot Conversation 🔥**

```
Conversation between User A and User B

Message 1 (User A): "Hey! 😊 How are you doing today?"
Message 2 (User B): "I'm doing great, thanks for asking! 🎉" (5 min reply)
Message 3 (User A): "That's awesome! Want to grab coffee this weekend?" (3 min reply)
Message 4 (User B): "Absolutely! That sounds like fun! ☕😄" (2 min reply)

CHS Calculation:
├─ Reply Speed: 10/10 (avg 3.3 min)
├─ Message Length: 5/5 (avg 7 words)
├─ Engagement: 3/3 (100% with emojis)
└─ Consistency: 5/5 (messages on same day)

Total CHS: 23 🔥 (Hot)
Bonus: +25 points
```

---

### **Example 2: Warm Conversation 🌡️**

```
Conversation between User C and User D

Message 1 (User C): "Hi there"
Message 2 (User D): "Hey, what's up?" (45 min reply)
Message 3 (User C): "Not much, just chilling"
Message 4 (User D): "Cool cool" (2 hours reply)

CHS Calculation:
├─ Reply Speed: 5/10 (avg 1.5 hours)
├─ Message Length: 1/5 (avg 2 words)
├─ Engagement: 0/3 (no emojis)
└─ Consistency: 4/5 (messages on same day)

Total CHS: 10 🌡️ (Warm)
Bonus: +15 points
```

---

### **Example 3: Cold Conversation ❄️**

```
Conversation between User E and User F

Message 1 (User E): "Hi"
Message 2 (User F): "Hey" (1 day reply)
Message 3 (User E): "How are you"
Message 4 (User F): "Good" (3 days reply)

CHS Calculation:
├─ Reply Speed: 2/10 (avg 2 days)
├─ Message Length: 0/5 (avg 1.5 words)
├─ Engagement: 0/3 (no emojis)
└─ Consistency: 1/5 (messages on different days)

Total CHS: 3 ❄️ (Cold)
Bonus: +5 points
```

---

## 🎁 Points Awarded

When a message is sent in a conversation, CHS bonus points are awarded:

```
Hot Conversation (CHS > 15)   → +25 bonus points
Warm Conversation (CHS 8-15)  → +15 bonus points
Cold Conversation (CHS < 8)   → +5 bonus points
```

**Plus base message points:**
```
Regular message: 5 points
Reply: 10 points
Image: 15 points
```

**Total example:**
```
Send message in Hot conversation:
= 5 (base) + 25 (CHS bonus) = 30 points
```

---

## 🔄 CHS Calculation Frequency

CHS is recalculated:
- ✅ After every message sent
- ✅ When opening a conversation
- ✅ Daily (background task)

---

## 📊 Leaderboard Integration

The leaderboard now shows:

1. **User Score** (total points)
2. **CHS Status** (Hot/Warm/Cold)
3. **Hot Conversations Count** (number of 🔥 conversations)

**Ranking factors:**
- Primary: Total Score
- Secondary: Number of Hot Conversations
- Tertiary: Average CHS

---

## 🛠️ Implementation Details

### **Files Created**

1. **`lib/models/conversation_health_score_model.dart`**
   - ConversationHealthScoreModel class
   - CHS calculation logic
   - Health status determination

2. **`lib/services/conversation_health_service.dart`**
   - ConversationHealthService class
   - CHS calculation methods
   - Firestore integration

### **Firestore Collection**

```
conversation_health_scores/
├── {userId}_{conversationId}
│   ├── conversationId: string
│   ├── userId: string
│   ├── otherUserId: string
│   ├── replySpeedScore: number
│   ├── messageLengthScore: number
│   ├── engagementScore: number
│   ├── consistencyScore: number
│   ├── totalCHS: number
│   ├── healthStatus: string
│   ├── bonusPoints: number
│   └── lastUpdated: timestamp
```

---

## 🚀 Usage

### **Calculate CHS for a Conversation**

```dart
final chsService = ConversationHealthService();

final chs = await chsService.calculateCHS(
  userId: 'user123',
  otherUserId: 'user456',
  conversationId: 'chat_123_456',
);

print('CHS: ${chs.totalCHS} (${chs.healthStatus})');
print('Bonus Points: +${chs.bonusPoints}');
```

### **Get All CHS for User**

```dart
final allCHS = await chsService.getAllCHSForUser('user123');

for (final chs in allCHS) {
  print('${chs.conversationId}: ${chs.totalCHS} (${chs.healthStatus})');
}
```

### **Get Hot Conversations**

```dart
final hotConversations = await chsService.getHotConversations('user123');

print('Hot conversations: ${hotConversations.length}');
for (final chs in hotConversations) {
  print('🔥 ${chs.conversationId}: ${chs.totalCHS} points');
}
```

---

## 💡 Tips to Improve CHS

1. **Reply Quickly** ⚡
   - Reply within 30 minutes for 10 points
   - Faster replies = higher score

2. **Write Longer Messages** 📝
   - Use 6+ words per message
   - Share your thoughts and feelings

3. **Use Emojis & Voice Notes** 😊
   - Add emojis to 30%+ of messages
   - Send voice notes occasionally

4. **Message Consistently** 📅
   - Message on 6-7 days per week
   - Keep the conversation alive

---

## 📈 Expected Impact

With CHS system:
- ✅ Users get rewarded for quality conversations
- ✅ Encourages faster replies
- ✅ Promotes longer, more meaningful messages
- ✅ Rewards consistent engagement
- ✅ Leaderboard reflects conversation quality

---

## 🔍 Debugging

Check console logs for CHS calculations:

```
[ConversationHealthService] 🔍 Calculating CHS for conversation: chat_123_456
[ConversationHealthService] 📊 CHS Components:
[ConversationHealthService]   Reply Speed: 10/10
[ConversationHealthService]   Message Length: 5/5
[ConversationHealthService]   Engagement: 3/3
[ConversationHealthService]   Consistency: 5/5
[ConversationHealthService] ✅ CHS Calculated: 23 (Hot 🔥) | Bonus: +25 pts
[ConversationHealthService] 💾 CHS saved to Firestore
```

---

## 🎉 Summary

The CHS system makes the leaderboard more engaging by:
- Rewarding quality conversations
- Encouraging meaningful engagement
- Promoting consistent communication
- Making dating app interactions more valuable

**Result:** Users are incentivized to have better conversations! 🚀
