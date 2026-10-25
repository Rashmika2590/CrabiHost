import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM-BG] Background notification received: ${message.messageId} | ${message.notification?.title}');
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'new_booking', 'check_in', 'check_out', 'payment', 'general'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ??
          json['notification_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ??
              json['created_at']?.toString() ??
              '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
        if (data != null) 'data': data,
      };

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'new_booking':
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'check_in':
        return Icons.login_rounded;
      case 'check_out':
        return Icons.logout_rounded;
      case 'payment':
      case 'revenue':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _prefsKey = 'app_notifications';
  static const _lastSyncedTokenKey = 'last_synced_fcm_token';

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  bool isFirebaseAvailable = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Optional navigation callback when notification is tapped
  void Function(Map<String, dynamic> data)? onNotificationClicked;

  Future<void> init() async {
    await _initLocalNotifications();
    await _loadSavedNotifications();
    await _initFirebaseMessaging();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification tapped with payload: ${response.payload}');
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationClicked?.call(data);
          } catch (_) {}
        }
      },
    );

    // Create default notification channel for Android O+
    const channel = AndroidNotificationChannel(
      'crabigo_host_channel',
      'Crabigo Host Alerts',
      description: 'Alerts for new bookings, guest check-ins, and activity',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not initialized yet.');
        return;
      }

      isFirebaseAvailable = true;

      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request notification permissions on startup
      await requestNotificationPermission();

      // 3. Configure foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM-FG] Foreground notification received: ${message.notification?.title}');
        _handleIncomingMessage(message);
      });

      // 5. App opened from background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM-TAP] App opened via notification: ${message.data}');
        onNotificationClicked?.call(message.data);
      });

      // 6. Check if app was opened from terminated state
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM-INIT] Initial notification found: ${initialMessage.data}');
        onNotificationClicked?.call(initialMessage.data);
      }

      // 7. Sync device token with backend
      await syncDeviceToken();

      // 8. Listen for token refresh events
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        _fcmToken = newToken;
        syncDeviceToken(forcedToken: newToken);
      });
    } catch (e) {
      debugPrint('[FCM] Firebase Messaging setup notice: $e');
      isFirebaseAvailable = false;
    }
  }

  /// Request user notification permissions
  Future<NotificationSettings?> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] User granted permission status: ${settings.authorizationStatus}');
      return settings;
    } catch (e) {
      debugPrint('[FCM] Error requesting notification permissions: $e');
      return null;
    }
  }

  /// Obtain FCM token and sync to AWS backend (POST /user/device-token)
  Future<void> syncDeviceToken({String? forcedToken, bool force = false}) async {
    try {
      if (!isFirebaseAvailable && Firebase.apps.isEmpty) return;

      final token = forcedToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] No FCM token available.');
        return;
      }
      _fcmToken = token;
      debugPrint('[FCM] Current FCM Device Token: $token');

      // Check if user is authenticated before sending to backend
      final authToken = await SecureStorageService.instance.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('[FCM] User not authenticated yet; deferring token sync.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSyncedToken = prefs.getString(_lastSyncedTokenKey);

      if (!force && lastSyncedToken == token) {
        debugPrint('[FCM] Device token is already synced with backend.');
        return;
      }

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : 'web';

      final body = {
        'device_token': token,
        'token': token,
        'fcm_token': token,
        'platform': platform,
        'device_type': platform,
      };

      // Send to AWS backend endpoint
      try {
        await ApiClient.instance.post('/user/device-token', data: body);
        await prefs.setString(_lastSyncedTokenKey, token);
        debugPrint('[FCM] Successfully synced device token to /user/device-token');
      } catch (e) {
        debugPrint('[FCM] /user/device-token attempt note: $e');
        // Secondary fallback route if backend routes under /user/fcm-token
        try {
          await ApiClient.instance.post('/user/fcm-token', data: body);
          await prefs.setString(_lastSyncedTokenKey, token);
          debugPrint('[FCM] Successfully synced device token to /user/fcm-token');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[FCM] Device token sync error: $e');
    }
  }

  void _handleIncomingMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'New Notification';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    final type = message.data['type']?.toString() ?? 'general';

    showLocalNotification(
      title: title,
      body: body,
      type: type,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'general',
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'crabigo_host_channel',
      'Crabigo Host Alerts',
      channelDescription: 'Alerts for new bookings and guest activity',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, title, body, details, payload: payload);

    // Save to in-app notification center
    await _saveNotification(
      AppNotification(
        id: id.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        data: payload != null
            ? (jsonDecode(payload) as Map<String, dynamic>?)
            : null,
      ),
    );
  }

  Future<void> _saveNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, list.take(100).toList());
  }

  Future<void> addNotifications(List<AppNotification> items) async {
    final existingIds = _notifications.map((n) => n.id).toSet();
    bool added = false;
    for (final item in items) {
      if (!existingIds.contains(item.id)) {
        _notifications.add(item);
        added = true;
      }
    }
    if (added) {
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateUnreadCount();
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_prefsKey, list.take(100).toList());
    }
  }

  Future<void> _loadSavedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    _notifications.clear();
    for (final item in list) {
      try {
        final json = jsonDecode(item) as Map<String, dynamic>;
        _notifications.add(AppNotification.fromJson(json));
      } catch (_) {}
    }
    _updateUnreadCount();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _updateUnreadCount();
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_prefsKey, list);
    }
  }

  Future<void> markAllRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _updateUnreadCount();
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, list);
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _updateUnreadCount();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = _notifications.where((n) => !n.isRead).length;
  }

  int get unreadCount => unreadCountNotifier.value;

  Future<void> onLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncedTokenKey);
    } catch (_) {}
  }

  Future<void> triggerTestNotification() async {
    await showLocalNotification(
      title: '🔔 New Booking Received!',
      body: 'Guest Kasun Perera booked Deluxe Ocean Villa for 3 nights.',
      type: 'new_booking',
    );
  }
}
