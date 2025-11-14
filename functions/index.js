const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Triggered when a notification doc is created in Firestore
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();

    console.log('🔔 New notification queued:', notification);

    const fcmToken = notification?.fcmToken;
    if (!fcmToken) {
      console.log('❌ No fcmToken on notification doc, skipping');
      await snap.ref.update({
        status: 'failed',
        error: 'Missing fcmToken',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // Ensure data is a flat string map for FCM
    const data = {};
    if (notification.data) {
      Object.keys(notification.data).forEach((key) => {
        data[key] = String(notification.data[key]);
      });
    }

    const message = {
      token: fcmToken,
      notification: {
        title: notification.title || 'New notification',
        body: notification.body || '',
      },
      data,
      android: {
        notification: {
          channelId: 'campusbound_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('✅ FCM sent successfully:', response);
      
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });
    } catch (error) {
      console.error('❌ Error sending FCM:', error);
      
      await snap.ref.update({
        status: 'failed',
        error: String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// Optional: Clean up old notifications (runs daily)
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 2 * * *') // Run at 2 AM daily
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotifications = await admin.firestore()
      .collection('notifications')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .get();

    const batch = admin.firestore().batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🧹 Cleaned up ${oldNotifications.size} old notifications`);
  });
