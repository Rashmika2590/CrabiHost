import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/utils/date_formatter.dart';
import '../data/fcm_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _fcmService = FcmService.instance;

  Future<void> _markAllAsRead() async {
    await _fcmService.markAllRead();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All alerts marked as read')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Alerts', style: TextStyle(fontSize: 18.sp)),
        content: Text('Are you sure you want to clear all notifications?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fcmService.clearAll();
      setState(() {});
    }
  }

  Future<void> _triggerTestAlert() async {
    await _fcmService.showLocalNotification(
      title: '🔔 New Booking Received!',
      body: 'Guest Kasun Perera booked Deluxe Ocean Villa for 3 nights.',
      type: 'new_booking',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _fcmService.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Activity & Alerts', style: TextStyle(fontSize: 18.sp)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_alert_rounded, size: 22.sp),
            tooltip: 'Simulate Booking Alert',
            onPressed: _triggerTestAlert,
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'read') _markAllAsRead();
              if (val == 'clear') _clearAll();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text('Mark all as read', style: TextStyle(fontSize: 13.sp)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18.sp, color: AppColors.error),
                    SizedBox(width: 8.w),
                    Text('Clear alert history', style: TextStyle(fontSize: 13.sp, color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 56.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('No alerts yet', style: AppTextStyles.headlineSmall.copyWith(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      'You will receive instant alerts whenever guests book, check in, or check out of your listings.',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  PrimaryGradientButton(
                    text: 'Send Test Alert',
                    icon: Icons.notifications_active_rounded,
                    onPressed: _triggerTestAlert,
                    width: 200.w,
                    height: 48.h,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  color: item.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: item.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(14.w),
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: _badgeColor(item.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        item.icon,
                        color: _badgeColor(item.type),
                        size: 22.sp,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontSize: 14.sp,
                              fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          item.body,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          DateFormatter.formatDateTime(item.timestamp),
                          style: AppTextStyles.caption.copyWith(fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _badgeColor(String type) {
    switch (type) {
      case 'new_booking':
        return AppColors.primary;
      case 'check_in':
        return AppColors.success;
      case 'check_out':
        return AppColors.warning;
      default:
        return AppColors.accentDark;
    }
  }
}
