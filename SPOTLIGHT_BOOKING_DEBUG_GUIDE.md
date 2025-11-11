# Spotlight Booking Debug Guide 🔍

## Comprehensive Logging Added

### What Was Added:

1. **Payment Success Handler Logging** (`spotlight_service.dart`)
2. **Calendar Loading Logging** (`spotlight_booking_screen.dart`)
3. **Firestore Query Logging** (`getDateStatuses()`)
4. **Automatic Fallback Mechanisms**

---

## 📊 Console Output Guide

### When Booking a Spotlight Date:

```
🎉 ===== PAYMENT SUCCESS CALLBACK =====
📅 Selected date: 15/12/2025
💳 Payment ID: pay_xxxxx
📝 Order ID: order_xxxxx

📞 Calling spotlight service...

🎯 ===== SPOTLIGHT PAYMENT SUCCESS HANDLER =====
📅 Date: 15/12/2025
💳 Payment ID: pay_xxxxx
📝 Order ID: order_xxxxx
✅ User authenticated: kyWfva4qPZWXj7G8lhNQeXSO49n2

📝 Creating booking document...
   Booking ID: abc123xyz
   Date: 2025-12-15 00:00:00.000
   Status: pending
✅ Booking document created successfully
✅ Booking verified in Firestore
   Stored data: {userId: kyWfva..., date: Timestamp(...), status: pending, ...}

📝 Creating payment order record...
✅ Payment order created: payment_doc_id

🎉 ===== SPOTLIGHT BOOKING COMPLETED =====
   Booking ID: abc123xyz
   Date: 15/12/2025
   User: kyWfva4qPZWXj7G8lhNQeXSO49n2
=========================================

✅ Spotlight service completed

🔄 Refreshing calendar data...

🔄 ===== LOADING CALENDAR DATA =====
📅 Date range: 1/12 to 28/2

🔍 ===== GET DATE STATUSES =====
📅 Range: 1/12 to 28/2
✅ User: kyWfva4qPZWXj7G8lhNQeXSO49n2

📡 Querying Firestore...
✅ Query returned 1 documents
   📄 Doc abc123xyz:
      Date: 15/12/2025
      User: kyWfva4qPZWXj7G8lhNQeXSO49n2
      Status: pending
      Yours: true

✅ Returning 1 date statuses
===============================

✅ Loaded 1 booked dates from Firestore
   📅 15/12/2025: booked=true, yours=true
✅ Calendar state updated with 1 entries
=====================================

✅ Calendar refreshed
🔄 Fallback refresh triggered (after 2 seconds)
```

---

## 🔍 What to Look For

### ✅ SUCCESS Indicators:

1. **Booking Created**:
   ```
   ✅ Booking document created successfully
   ✅ Booking verified in Firestore
   ```

2. **Calendar Loaded**:
   ```
   ✅ Loaded X booked dates from Firestore
   ✅ Calendar state updated with X entries
   ```

3. **Date Shows as Booked**:
   ```
   📅 15/12/2025: booked=true, yours=true
   ```

### ❌ ERROR Indicators:

1. **User Not Authenticated**:
   ```
   ❌ ERROR: User not authenticated
   ```
   **Fix**: Ensure user is logged in

2. **Booking Not Verified**:
   ```
   ❌ WARNING: Booking not found after creation!
   ```
   **Fix**: Check Firestore rules and permissions

3. **Query Returns 0 Documents**:
   ```
   ✅ Query returned 0 documents
   ```
   **Fix**: Check if booking was actually saved

4. **Firestore Permission Error**:
   ```
   ❌ Error: [cloud_firestore/permission-denied]
   ```
   **Fix**: Deploy updated Firestore rules

---

## 🛠️ Fallback Mechanisms

### 1. Automatic Calendar Refresh
After successful payment, calendar refreshes **twice**:
- Immediately after booking
- 2 seconds later (fallback)

```dart
// Immediate refresh
await _loadCalendarData();

// Fallback refresh after 2 seconds
Future.delayed(Duration(seconds: 2), () {
  _loadCalendarData();
});
```

### 2. Retry on Error
If calendar loading fails, it automatically retries after 3 seconds:

```dart
// Fallback: Retry after 3 seconds
Future.delayed(Duration(seconds: 3), () {
  print('🔄 Retrying calendar load (fallback)...');
  _loadCalendarData();
});
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Booking Created But Not Showing in Calendar

**Symptoms**:
```
✅ Booking document created successfully
BUT
✅ Query returned 0 documents
```

**Possible Causes**:
1. Date mismatch (time component)
2. Status not 'pending' or 'active'
3. Firestore rules blocking read

**Debug Steps**:
1. Check console for booking date vs query range
2. Verify status field in Firestore
3. Check Firestore rules allow read

**Solution**:
```dart
// Ensure date is normalized (no time component)
final startOfDay = DateTime(date.year, date.month, date.day);
```

---

### Issue 2: Permission Denied

**Symptoms**:
```
❌ Error: [cloud_firestore/permission-denied]
```

**Solution**:
Deploy updated Firestore rules:
```bash
firebase deploy --only firestore:rules
```

Updated rules allow all authenticated users to read bookings:
```javascript
allow read: if isAuthenticated();
```

---

### Issue 3: Calendar Not Refreshing

**Symptoms**:
- Booking successful
- Console shows booking created
- Calendar doesn't update

**Debug**:
Check if setState is called:
```
✅ Calendar state updated with X entries
```

**Solution**:
Fallback refresh triggers automatically after 2 seconds.

---

### Issue 4: Date Shows as Available After Booking

**Symptoms**:
- Booking created
- Date still white (not green)

**Debug Steps**:
1. Check `_dateStatuses` map:
   ```
   ✅ Calendar state updated with 1 entries
   ```

2. Check if date key matches:
   ```dart
   final dateKey = DateTime(day.year, day.month, day.day);
   final status = _dateStatuses[dateKey];
   ```

3. Verify `isBookedByCurrentUser` flag:
   ```
   📅 15/12/2025: booked=true, yours=true
   ```

**Solution**:
Ensure date normalization is consistent everywhere.

---

## 📱 Testing Checklist

### Test 1: Book a Date
1. ✅ Open spotlight booking
2. ✅ Select a date
3. ✅ Complete payment
4. ✅ Check console for success logs
5. ✅ Verify booking in Firestore console
6. ✅ Date should turn GREEN in calendar

### Test 2: Verify Logging
1. ✅ Check for "PAYMENT SUCCESS CALLBACK"
2. ✅ Check for "SPOTLIGHT BOOKING COMPLETED"
3. ✅ Check for "Calendar state updated"
4. ✅ Check for date status logs

### Test 3: Check Fallback
1. ✅ Book a date
2. ✅ Wait 2 seconds
3. ✅ Check for "Fallback refresh triggered"
4. ✅ Calendar should update if it didn't before

### Test 4: Error Handling
1. ✅ Disconnect internet
2. ✅ Try to book
3. ✅ Check for error logs
4. ✅ Verify retry mechanism

---

## 🔧 Manual Debugging Steps

### Step 1: Check Firestore Console
1. Open Firebase Console
2. Go to Firestore Database
3. Check `spotlight_bookings` collection
4. Verify booking document exists
5. Check fields:
   - `userId`: Correct?
   - `date`: Correct timestamp?
   - `status`: 'pending' or 'active'?

### Step 2: Check Console Logs
Look for these key logs in order:
1. `PAYMENT SUCCESS CALLBACK`
2. `SPOTLIGHT PAYMENT SUCCESS HANDLER`
3. `Booking document created successfully`
4. `Booking verified in Firestore`
5. `SPOTLIGHT BOOKING COMPLETED`
6. `LOADING CALENDAR DATA`
7. `GET DATE STATUSES`
8. `Query returned X documents`
9. `Calendar state updated`

### Step 3: Verify Date Format
```dart
// Booking date (should be start of day)
Date: 2025-12-15 00:00:00.000

// Query range
Range: 1/12 to 28/2

// Result
Date: 15/12/2025  ✅ Within range
```

### Step 4: Check User ID
```
User authenticated: kyWfva4qPZWXj7G8lhNQeXSO49n2
...
User: kyWfva4qPZWXj7G8lhNQeXSO49n2
...
Yours: true  ✅ Match
```

---

## 📊 Expected Flow

```
User Selects Date
    ↓
User Completes Payment
    ↓
Payment Success Callback
    ↓
Create Booking in Firestore
    ↓
Verify Booking Exists
    ↓
Create Payment Order
    ↓
Refresh Calendar (immediate)
    ↓
Query Firestore for Bookings
    ↓
Update Calendar State
    ↓
Refresh Calendar (fallback after 2s)
    ↓
Date Shows as GREEN
```

---

## 🎯 Key Files Modified

1. **`lib/services/spotlight_service.dart`**
   - Added logging to `handleSpotlightPaymentSuccess()`
   - Added logging to `getDateStatuses()`
   - Added booking verification step

2. **`lib/screens/spotlight/spotlight_booking_screen.dart`**
   - Added logging to `_handlePaymentSuccess()`
   - Added logging to `_loadCalendarData()`
   - Added fallback refresh (2 seconds)
   - Added retry on error (3 seconds)

---

## 💡 Tips

### Enable Verbose Logging:
All logs are already enabled. Just run the app and watch the console.

### Filter Console Output:
Look for these emojis:
- 🎯 Payment handler
- 📅 Date operations
- ✅ Success
- ❌ Error
- 🔄 Refresh/Retry
- 📡 Firestore query

### Quick Debug:
```bash
# Run app with console visible
flutter run

# Watch for these patterns:
# "SPOTLIGHT BOOKING COMPLETED" = Success
# "Calendar state updated with X entries" = Calendar loaded
# "booked=true, yours=true" = Your booking
```

---

## 🚀 Next Steps

1. **Run the app**: `flutter run`
2. **Book a date**: Complete payment
3. **Watch console**: Look for success indicators
4. **Check calendar**: Date should turn green
5. **If issue persists**: Share console logs

---

**Status**: ✅ Comprehensive logging and fallback mechanisms added!

The system now provides detailed logs at every step and automatically retries if something fails.
