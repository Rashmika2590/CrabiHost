import 'dart:developer' as dev;
import '../../../core/network/api_client.dart';
import 'fcm_service.dart';

class NotificationRepository {
  final ApiClient _client;
  final FcmService _fcmService;

  NotificationRepository({
    ApiClient? client,
    FcmService? fcmService,
  })  : _client = client ?? ApiClient.instance,
        _fcmService = fcmService ?? FcmService.instance;

  /// Fetches notifications from backend if available, merging them with locally cached alerts.
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _client.get('/notifications/');
      final dynamic rawList;
      if (response is List) {
        rawList = response;
      } else if (response is Map) {
        rawList = response['notifications'] ??
            response['data'] ??
            response['items'] ??
            [];
      } else {
        rawList = [];
      }

      if (rawList is List && rawList.isNotEmpty) {
        final remoteItems = rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => AppNotification.fromJson(item))
            .toList();

        await _fcmService.addNotifications(remoteItems);
      }
    } catch (e) {
      dev.log('Remote notifications fetch notice (using cached): $e',
          name: 'NotificationRepository');
    }

    return _fcmService.notifications;
  }

  Future<void> markAsRead(String id) async {
    await _fcmService.markAsRead(id);
    try {
      await _client.post('/notifications/$id/read');
    } catch (_) {
      // Backend route optional
    }
  }

  Future<void> markAllAsRead() async {
    await _fcmService.markAllRead();
    try {
      await _client.post('/notifications/read-all');
    } catch (_) {
      // Backend route optional
    }
  }

  Future<void> clearAll() async {
    await _fcmService.clearAll();
    try {
      await _client.delete('/notifications/');
    } catch (_) {
      // Backend route optional
    }
  }
}
