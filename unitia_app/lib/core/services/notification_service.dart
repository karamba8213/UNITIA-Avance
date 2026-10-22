import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/order.dart';

// FCM background handler — debe ser top-level
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Firebase ya inicializado en bootstrap.dart
  NotificationService._showLocalStatic(
    title: message.notification?.title ?? '🛎️ Nuevo pedido',
    body:  message.notification?.body  ?? 'Tienes un pedido nuevo',
  );
}

class NotificationService {
  NotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'orders';
  static const _channelName = 'Pedidos';

  static String? fcmToken;

  // ── Init (llamar en bootstrap antes de runApp) ─────────────
  static Future<void> init() async {
    // Canal de notificación Android (alta importancia = sonido + heads-up)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alertas de nuevos pedidos entrantes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Init local notifications
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // FCM
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Foreground FCM → mostrar como notificación local
    FirebaseMessaging.onMessage.listen((msg) {
      _showLocalStatic(
        title: msg.notification?.title ?? '🛎️ Nuevo pedido',
        body:  msg.notification?.body  ?? 'Tienes un pedido nuevo',
      );
    });

    // Obtener y guardar token
    fcmToken = await FirebaseMessaging.instance.getToken();

    // Refrescar token si cambia
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      fcmToken = token;
    });
  }

  // ── Notificación de pedido nuevo (desde stream) ────────────
  static Future<void> showNewOrder(Order order) async {
    await _showLocalStatic(
      title: '🛎️ Nuevo pedido',
      body: '${order.customerName}  •  \$${order.subtotal.toStringAsFixed(2)}',
      payload: order.id,
    );
  }

  // ── Recordatorio urgente (ID estable por pedido, reemplaza anterior) ─
  static Future<void> showUrgentOrder(Order order, int minutesWaiting) async {
    final stableId = order.id.hashCode.abs() % 100000;
    await _local.show(
      stableId,
      '⚠️ Pedido sin aceptar ($minutesWaiting min)',
      '${order.customerName}  •  \$${order.subtotal.toStringAsFixed(2)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Alertas de nuevos pedidos entrantes',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          color: Color(0xFFE53935),
        ),
      ),
      payload: order.id,
    );
  }

  // ── Interno ────────────────────────────────────────────────
  static Future<void> _showLocalStatic({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Alertas de nuevos pedidos entrantes',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: payload,
    );
  }
}
