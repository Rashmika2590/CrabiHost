import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/utils/date_formatter.dart';
import 'providers/notifications_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B2A4A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_alert_rounded,
              size: 21.sp,
              color: const Color(0xFF1B2A4A),
            ),
            tooltip: 'Simulate Booking Alert',
            onPressed: () =>
                ref.read(notificationsProvider.notifier).triggerTestAlert(),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 21.sp,
              color: const Color(0xFF1B2A4A),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            onSelected: (val) async {
              if (val == 'read') {
                await ref
                    .read(notificationsProvider.notifier)
                    .markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'All notifications marked as read',
                        style: GoogleFonts.poppins(fontSize: 12.5.sp),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (val == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    title: Text(
                      'Clear History',
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B2A4A),
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to clear all notification history?',
                      style: GoogleFonts.poppins(fontSize: 13.5.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(notificationsProvider.notifier).clearAll();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded,
                        size: 18.sp, color: AppColors.primary),
                    SizedBox(width: 10.w),
                    Text(
                      'Mark all as read',
                      style: GoogleFonts.poppins(fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        size: 18.sp, color: AppColors.error),
                    SizedBox(width: 10.w),
                    Text(
                      'Clear alert history',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: notificationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Failed to load notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B2A4A),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  PrimaryGradientButton(
                    text: 'Retry',
                    icon: Icons.refresh_rounded,
                    width: 130.w,
                    height: 42.h,
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 120.h),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 42.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 18.h),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B2A4A),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            'You will receive instant alerts whenever guests book, check in, or message you.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5.sp,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        PrimaryGradientButton(
                          text: 'Simulate Test Alert',
                          icon: Icons.notifications_active_rounded,
                          width: 220.w,
                          height: 46.h,
                          onPressed: () => ref
                              .read(notificationsProvider.notifier)
                              .triggerTestAlert(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () {
                    if (!item.isRead) {
                      ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(item.id);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.isRead
                          ? Colors.white
                          : AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: item.isRead
                            ? const Color(0xFFE2E8F0)
                            : AppColors.primary.withValues(alpha: 0.35),
                        width: item.isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B2A4A)
                              .withValues(alpha: item.isRead ? 0.03 : 0.06),
                          blurRadius: 10.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(14.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color:
                                _badgeColor(item.type).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            item.icon,
                            color: _badgeColor(item.type),
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5.sp,
                                        fontWeight: item.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        color: const Color(0xFF1B2A4A),
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
                              SizedBox(height: 4.h),
                              Text(
                                item.body,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                DateFormatter.relativeDate(item.timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5.sp,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _badgeColor(String type) {
    switch (type.toLowerCase()) {
      case 'new_booking':
      case 'booking':
        return AppColors.primary;
      case 'check_in':
        return AppColors.success;
      case 'check_out':
        return AppColors.warning;
      case 'payment':
        return const Color(0xFF6366F1);
      default:
        return AppColors.accentDark;
    }
  }
}
