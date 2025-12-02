# Premium Expiry - UI Implementation Examples

## 🎨 Display Remaining Days Widget

### Simple Text Display

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    if (!premiumProvider.isPremium) {
      return const Text('Get Premium');
    }
    
    final remainingDays = premiumProvider.remainingDays;
    
    if (remainingDays == null) {
      return const Text('Premium (Lifetime)');
    }
    
    if (remainingDays == 0) {
      return const Text(
        'Premium Expired',
        style: TextStyle(color: Colors.red),
      );
    }
    
    return Text(
      'Premium - $remainingDays days left',
      style: const TextStyle(color: Colors.green),
    );
  },
)
```

---

## 🎯 Premium Badge with Countdown

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    if (!premiumProvider.isPremium) {
      return const SizedBox.shrink();
    }
    
    final remainingDays = premiumProvider.remainingDays ?? 0;
    final isExpired = premiumProvider.isPremiumExpired;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            isExpired 
              ? 'Premium Expired' 
              : 'Premium ($remainingDays days)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  },
)
```

---

## ⏰ Expiry Warning Card

Show this when premium is expiring soon (e.g., < 3 days):

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    final remainingDays = premiumProvider.remainingDays;
    
    // Only show if premium is expiring soon
    if (remainingDays == null || remainingDays > 3) {
      return const SizedBox.shrink();
    }
    
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Expiring Soon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Your premium expires in $remainingDays days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to premium purchase screen
              },
              child: const Text('Renew'),
            ),
          ],
        ),
      ),
    );
  },
)
```

---

## 📅 Detailed Premium Info Card

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    if (!premiumProvider.isPremium) {
      return const SizedBox.shrink();
    }
    
    final expiryDate = premiumProvider.premiumExpiryDate;
    final remainingDays = premiumProvider.remainingDays ?? 0;
    final isExpired = premiumProvider.isPremiumExpired;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Premium Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Status',
              isExpired ? 'Expired' : 'Active',
              isExpired ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Days Remaining',
              remainingDays.toString(),
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Expires On',
              expiryDate != null 
                ? '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'
                : 'N/A',
              Colors.grey,
            ),
            if (!isExpired) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Renew premium
                  },
                  child: const Text('Renew Premium'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
)

Widget _buildInfoRow(String label, String value, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
    ],
  );
}
```

---

## 🔐 Lock Features Based on Premium Status

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    final isPremium = premiumProvider.isPremium && 
                      !premiumProvider.isPremiumExpired;
    
    return GestureDetector(
      onTap: isPremium 
        ? () => _openFeature()
        : () => _showPremiumRequired(),
      child: Stack(
        children: [
          // Feature content
          Container(
            // Your feature widget
          ),
          
          // Lock overlay if not premium
          if (!isPremium)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Premium Feature',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  },
)
```

---

## 📊 Premium Progress Bar

Show expiry progress as a visual bar:

```dart
Consumer<PremiumProvider>(
  builder: (context, premiumProvider, _) {
    if (!premiumProvider.isPremium) {
      return const SizedBox.shrink();
    }
    
    final remainingDays = premiumProvider.remainingDays ?? 30;
    final progress = (remainingDays / 30).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Expiry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.3 ? Colors.green : Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$remainingDays days remaining',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  },
)
```

---

## 🎁 Renewal Reminder Dialog

Show when premium is about to expire:

```dart
void _showRenewalReminder(BuildContext context) {
  final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
  final remainingDays = premiumProvider.remainingDays ?? 0;
  
  if (remainingDays > 3) return; // Only show if < 3 days left
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Premium Expiring Soon'),
      content: Text(
        'Your premium subscription expires in $remainingDays days. '
        'Renew now to continue enjoying all premium features!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to premium purchase screen
          },
          child: const Text('Renew Now'),
        ),
      ],
    ),
  );
}
```

---

## 🔔 Show Expiry Notification

```dart
void _showExpiryNotification(BuildContext context) {
  final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
  
  if (premiumProvider.isPremiumExpired) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your premium subscription has expired'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Renew',
          onPressed: () {
            // Navigate to premium purchase
          },
        ),
      ),
    );
  }
}
```

---

## 💡 Usage Tips

1. **Always check `isPremiumExpired`** - Don't just check `isPremium`
2. **Use `remainingDays` for countdown** - Shows null if not premium
3. **Call `refreshPremiumStatus()`** - After payment to update UI immediately
4. **Listen to changes** - Use `Consumer<PremiumProvider>` for real-time updates
5. **Handle null values** - `remainingDays` and `premiumExpiryDate` can be null

---

## 🎯 Common Patterns

### Pattern 1: Show Premium Badge
```dart
if (premiumProvider.isPremium && !premiumProvider.isPremiumExpired) {
  // Show premium badge
}
```

### Pattern 2: Lock Feature
```dart
if (!premiumProvider.isPremium || premiumProvider.isPremiumExpired) {
  // Show lock overlay
}
```

### Pattern 3: Show Expiry Warning
```dart
if (premiumProvider.remainingDays != null && 
    premiumProvider.remainingDays! < 7) {
  // Show warning
}
```

### Pattern 4: Disable After Expiry
```dart
enabled: premiumProvider.isPremium && 
         !premiumProvider.isPremiumExpired,
```

---

**Ready to implement?** Copy-paste any of these examples into your widgets!
