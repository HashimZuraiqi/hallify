const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send notification when a new message is created
 */
exports.onMessageCreated = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    
    console.log('New message:', message.senderName, '->', message.receiverName);

    try {
      // Get receiver's FCM token
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(message.receiverId)
        .get();
      
      if (!receiverDoc.exists) {
        console.log('Receiver not found');
        return null;
      }

      const fcmToken = receiverDoc.data().fcmToken;

      if (!fcmToken) {
        console.log('No FCM token');
        return null;
      }

      // Send push notification
      const payload = {
        notification: {
          title: `New message from ${message.senderName}`,
          body: message.content.substring(0, 100),
        },
        data: {
          type: 'message',
          conversationId: message.conversationId,
          senderId: message.senderId,
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(payload);
      console.log('✅ Notification sent:', response);
      return response;

    } catch (error) {
      console.error('❌ Error:', error);
      return null;
    }
  });

/**
 * Send notification when a new hall is created
 */
exports.onHallCreated = functions.firestore
  .document('halls/{hallId}')
  .onCreate(async (snap, context) => {
    const hall = snap.data();
    
    console.log('New hall:', hall.name, 'in', hall.city);

    try {
      // Get all customers
      const usersSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'customer')
        .get();

      if (usersSnapshot.empty) {
        console.log('No customers found');
        return null;
      }

      // Collect FCM tokens
      const tokens = [];
      usersSnapshot.forEach(doc => {
        const token = doc.data().fcmToken;
        if (token) tokens.push(token);
      });

      if (tokens.length === 0) {
        console.log('No tokens found');
        return null;
      }

      console.log(`Sending to ${tokens.length} customers`);

      // Send to all customers
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: {
          title: '🎉 New Hall Available!',
          body: `${hall.name} in ${hall.city} - ${hall.pricePerHour} JOD/hr`,
        },
        data: {
          type: 'new_hall',
          hallId: context.params.hallId,
        },
      });

      console.log(`✅ Sent: ${response.successCount}, Failed: ${response.failureCount}`);
      return response;

    } catch (error) {
      console.error('❌ Error:', error);
      return null;
    }
  });
