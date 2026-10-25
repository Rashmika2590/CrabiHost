import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fcm_service.dart';
import '../../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  FutureOr<List<AppNotification>> build() async {
    return _repo.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getNotifications());
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = const AsyncValue.data([]);
  }

  Future<void> triggerTestAlert() async {
    await FcmService.instance.showLocalNotification(
      title: '🔔 New Booking Received!',
      body: 'Guest Kasun Perera booked Deluxe Ocean Villa for 3 nights.',
      type: 'new_booking',
    );
    state = AsyncValue.data(FcmService.instance.notifications);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncVal = ref.watch(notificationsProvider);
  return asyncVal.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => FcmService.instance.unreadCount,
  );
});
