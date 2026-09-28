import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../notifications/data/fcm_service.dart';
import '../domain/booking_model.dart';
import 'providers/bookings_provider.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final Object? booking;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late BookingModel? _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking is BookingModel) {
      _booking = widget.booking as BookingModel;
    } else {
      _booking = null;
    }
  }

  Future<void> _updateStatus(String status, {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingRepositoryProvider).updateBookingStatus(
            widget.bookingId,
            status: status,
            cancellationReason: reason,
          );

      if (status == 'checked_in') {
        await FcmService.instance.showLocalNotification(
          title: '📥 Guest Checked-In Alert',
          body: '${_booking?.displayGuestName ?? 'Guest'} has checked in.',
          type: 'check_in',
        );
      } else if (status == 'checked_out') {
        await FcmService.instance.showLocalNotification(
          title: '📤 Guest Checked-Out Alert',
          body: '${_booking?.displayGuestName ?? 'Guest'} has checked out.',
          type: 'check_out',
        );
      }

      ref.invalidate(upcomingBookingsProvider);
      ref.invalidate(ongoingBookingsProvider);
      ref.invalidate(completedBookingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to ${status.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _promptCancelDialog() async {
    final reasonController = TextEditingController();
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking', style: TextStyle(fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this booking? This action cannot be undone.', style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                labelText: 'Reason for cancellation',
                labelStyle: TextStyle(fontSize: 12.sp),
                hintText: 'e.g. Host requested cancellation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await _updateStatus('cancelled', reason: reasonController.text.trim());
    }
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phone')),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot email $email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking #${widget.bookingId}', style: TextStyle(fontSize: 17.sp)),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  width: 18.w,
                  height: 18.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: booking == null
          ? const Center(child: Text('Booking details not available'))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status & Price Header Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.primary,
                              size: 26.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.displayStatus,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontSize: 16.sp,
                                    color: _statusColor(booking.status),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Booked on ${DateFormatter.formatDate(booking.bookingTime)}',
                                  style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              booking.price,
                              currency: booking.displayCurrency,
                            ),
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 16.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Guest Information Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text('Guest Details',
                                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            ],
                          ),
                          Divider(height: 24.h),
                          _DetailRow(
                            label: 'Name',
                            value: booking.displayGuestName,
                          ),
                          if (booking.guestEmail != null &&
                              booking.guestEmail!.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Email', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp)),
                                Row(
                                  children: [
                                    Text(booking.guestEmail!,
                                        style: AppTextStyles.labelMedium.copyWith(fontSize: 12.sp)),
                                    SizedBox(width: 6.w),
                                    IconButton(
                                      icon: Icon(Icons.mail_outline_rounded,
                                          size: 18.sp, color: AppColors.accentDark),
                                      onPressed: () =>
                                          _launchEmail(booking.guestEmail!),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          if (booking.guestPhone != null &&
                              booking.guestPhone!.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Phone', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp)),
                                Row(
                                  children: [
                                    Text(booking.guestPhone!,
                                        style: AppTextStyles.labelMedium.copyWith(fontSize: 12.sp)),
                                    SizedBox(width: 6.w),
                                    IconButton(
                                      icon: Icon(Icons.phone_outlined,
                                          size: 18.sp, color: AppColors.success),
                                      onPressed: () =>
                                          _launchCall(booking.guestPhone!),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          if (booking.relationshipToUser != null &&
                              booking.relationshipToUser!.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            _DetailRow(
                              label: 'Booking For',
                              value: booking.relationshipToUser!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Dates & Stay Details Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text('Stay Dates',
                                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            ],
                          ),
                          Divider(height: 24.h),
                          Row(
                            children: [
                              Expanded(
                                child: _DateBlock(
                                  title: 'CHECK-IN',
                                  date: DateFormatter.formatDate(
                                      booking.checkInDate),
                                  time: DateFormatter.formatTime(
                                      booking.checkInTime),
                                  icon: Icons.login_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                              Container(
                                width: 1.w,
                                height: 48.h,
                                color: AppColors.divider,
                              ),
                              Expanded(
                                child: _DateBlock(
                                  title: 'CHECK-OUT',
                                  date: DateFormatter.formatDate(
                                      booking.checkOutDate),
                                  time: DateFormatter.formatTime(
                                      booking.checkOutTime),
                                  icon: Icons.logout_rounded,
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _PillInfo(
                                  label: 'Duration',
                                  value: DateFormatter.duration(
                                      booking.checkInDate, booking.checkOutDate),
                                ),
                                _PillInfo(
                                  label: 'Adults',
                                  value: '${booking.adultCount ?? 1}',
                                ),
                                _PillInfo(
                                  label: 'Children',
                                  value: '${booking.childrenCount ?? 0}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Payment & Policies
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment_rounded,
                                  color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text('Payment & Policy',
                                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            ],
                          ),
                          Divider(height: 24.h),
                          _DetailRow(
                            label: 'Payment Method',
                            value: booking.paymentMethod ?? 'Pay at Property',
                          ),
                          if (booking.paymentReference != null &&
                              booking.paymentReference!.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            _DetailRow(
                              label: 'Reference No.',
                              value: booking.paymentReference!,
                            ),
                          ],
                          SizedBox(height: 10.h),
                          _DetailRow(
                            label: 'Free Cancellation',
                            value: booking.freeCancellation ? 'Yes' : 'No',
                          ),
                          if (booking.promoCode != null &&
                              booking.promoCode!.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            _DetailRow(
                              label: 'Promo Code Applied',
                              value: booking.promoCode!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Special Request Notes
                  if (booking.specialRequest != null &&
                      booking.specialRequest!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.notes_rounded,
                                    color: AppColors.primary, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text('Special Requests',
                                    style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                              ],
                            ),
                            Divider(height: 24.h),
                            Text(
                              booking.specialRequest!,
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Action Buttons Section
                  SizedBox(height: 8.h),
                  Text('Host Actions', style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                  SizedBox(height: 12.h),

                  // Action: Mark Checked-In
                  if (booking.status?.toLowerCase() != 'checked_in' &&
                      booking.status?.toLowerCase() != 'completed' &&
                      booking.status?.toLowerCase() != 'cancelled')
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _updateStatus('checked_in'),
                      icon: Icon(Icons.login_rounded, size: 18.sp),
                      label: Text('Mark Guest Checked-In', style: TextStyle(fontSize: 14.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),

                  SizedBox(height: 10.h),

                  // Action: Mark Checked-Out
                  if (booking.status?.toLowerCase() == 'checked_in' ||
                      booking.status?.toLowerCase() == 'ongoing')
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _updateStatus('checked_out'),
                      icon: Icon(Icons.logout_rounded, size: 18.sp),
                      label: Text('Mark Guest Checked-Out', style: TextStyle(fontSize: 14.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),

                  SizedBox(height: 10.h),

                  // Action: Cancel Booking
                  if (booking.status?.toLowerCase() != 'cancelled' &&
                      booking.status?.toLowerCase() != 'completed')
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _promptCancelDialog,
                      icon: Icon(Icons.cancel_outlined, color: AppColors.error, size: 18.sp),
                      label: Text('Cancel Booking',
                          style: TextStyle(color: AppColors.error, fontSize: 14.sp)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return AppColors.upcoming;
      case 'checked_in':
      case 'ongoing':
        return AppColors.ongoing;
      case 'completed':
        return AppColors.completed;
      case 'cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.primary;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13.sp),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final IconData icon;
  final Color color;

  const _DateBlock({
    required this.title,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22.sp),
        SizedBox(height: 4.h),
        Text(title, style: AppTextStyles.caption.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text(date, style: AppTextStyles.labelLarge.copyWith(fontSize: 13.sp)),
        Text(time, style: AppTextStyles.caption.copyWith(fontSize: 11.sp)),
      ],
    );
  }
}

class _PillInfo extends StatelessWidget {
  final String label;
  final String value;

  const _PillInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11.sp)),
        SizedBox(height: 2.h),
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontSize: 13.sp)),
      ],
    );
  }
}
