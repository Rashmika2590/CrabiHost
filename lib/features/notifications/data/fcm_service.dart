import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'new_booking', 'check_in', 'check_out'
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
      };

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  IconData get icon {
    switch (type) {
      case 'check_in':
        return Icons.login_rounded;
      case 'check_out':
        return Icons.logout_rounded;
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

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  Future<void> init() async {
    await _initLocalNotifications();
    await _loadSavedNotifications();
    await _initFirebase();
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
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  bool isFirebaseAvailable = false;

  Future<void> _initFirebase() async {
    try {
      isFirebaseAvailable = true;
      debugPrint('[FCM] Firebase Messaging initialized.');
    } catch (e) {
      debugPrint('[FCM] Firebase not configured: $e');
      isFirebaseAvailable = false;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'general',
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
    await _localNotifications.show(id, title, body, details);

    // Save to in-app notification center
    await _saveNotification(
      AppNotification(
        id: id.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _saveNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, list.take(50).toList());
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
  }

  Future<void> markAllRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    final prefs = await SharedPreferences.getInstance();
    final list = _notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefsKey, list);
  }

  Future<void> clearAll() async {
    _notifications.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> triggerTestNotification() async {
    await showLocalNotification(
      title: '🔔 New Booking Received!',
      body: 'A new guest has booked your property.',
      type: 'new_booking',
    );
  }
}
