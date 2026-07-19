import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service untuk menampilkan local notification saat ada chat masuk.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Inisialisasi notification plugin. Panggil sekali di main().
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;

    // Request permission di Android 13+
    _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Tampilkan notifikasi chat.
  static Future<void> showChatNotification({
    required String senderName,
    required String messageText,
    String? chatId,
  }) async {
    if (!_initialized || kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat',
      channelDescription: 'Notifikasi pesan chat masuk',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Gunakan hashCode dari chatId sebagai notification id agar per-session
    final notifId = chatId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _plugin.show(
      id: notifId,
      title: senderName,
      body: messageText,
      notificationDetails: details,
    );
  }
}
