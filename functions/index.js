const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Triggered when a new order is created in Firestore.
 * Sends an FCM push notification to the restaurant's device.
 */
exports.onNewOrder = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data.data();
  if (!order) return;

  const restaurantId = order.restaurantId;
  if (!restaurantId) return;

  // Fetch the restaurant document to get the FCM token
  const db = getFirestore();
  const restaurantSnap = await db.collection('restaurants').doc(restaurantId).get();
  if (!restaurantSnap.exists) return;

  const fcmToken = restaurantSnap.data()?.fcmToken;
  if (!fcmToken) {
    console.log(`Restaurant ${restaurantId} has no FCM token — skipping push.`);
    return;
  }

  const customerName = order.customerName ?? 'Cliente';
  const subtotal = (order.subtotal ?? 0).toFixed(2);

  const message = {
    token: fcmToken,
    notification: {
      title: '🛎️ Nuevo pedido',
      body: `${customerName}  •  $${subtotal}`,
    },
    android: {
      notification: {
        channelId: 'orders',
        priority: 'high',
        sound: 'default',
      },
      priority: 'high',
    },
    data: {
      orderId: event.params.orderId,
      type: 'new_order',
    },
  };

  try {
    const response = await getMessaging().send(message);
    console.log(`FCM sent to restaurant ${restaurantId}: ${response}`);
  } catch (err) {
    console.error(`FCM error for restaurant ${restaurantId}:`, err);
  }
});
