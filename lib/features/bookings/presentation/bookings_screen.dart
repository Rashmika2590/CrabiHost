import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bookings/domain/booking_model.dart';
import '../presentation/providers/bookings_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bookings', style: TextStyle(fontSize: 18.sp)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 13.sp),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Search by guest name...',
                hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textHint),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textHint, size: 20.sp),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18.sp),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          SizedBox(height: 12.h),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  provider: upcomingBookingsProvider,
                  emptyMessage: 'No upcoming bookings',
                ),
                _BookingList(
                  provider: ongoingBookingsProvider,
                  emptyMessage: 'No active bookings',
                ),
                _BookingList(
                  provider: completedBookingsProvider,
                  emptyMessage: 'No completed bookings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _search(String query) {
    ref.read(upcomingBookingsProvider.notifier).search(query);
    ref.read(ongoingBookingsProvider.notifier).search(query);
    ref.read(completedBookingsProvider.notifier).search(query);
  }
}

class _BookingList extends ConsumerWidget {
  final StateNotifierProvider<BookingsNotifier, AsyncValue<List<BookingModel>>>
      provider;
  final String emptyMessage;

  const _BookingList({
    required this.provider,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return state.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48.sp),
            SizedBox(height: 12.h),
            Text(e.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)),
            SizedBox(height: 16.h),
            PrimaryGradientButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.read(provider.notifier).load(),
              width: 140.w,
              height: 44.h,
            ),
          ],
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: AppColors.textHint, size: 56.sp),
                SizedBox(height: 16.h),
                Text(emptyMessage,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(provider.notifier).load(),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => SizedBox(height: 6.h),
            itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => context.go('/bookings/${booking.id}', extra: booking),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Avatar
              CircleAvatar(
                radius: 22.r,
                backgroundColor: _statusBgColor(booking.status),
                child: Text(
                  booking.displayGuestName.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 14.sp,
                    color: _statusColor(booking.status),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            booking.displayGuestName,
                            style: AppTextStyles.headlineSmall.copyWith(fontSize: 14.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: booking.status),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.login_rounded,
                            size: 13.sp, color: AppColors.textHint),
                        SizedBox(width: 3.w),
                        Text(
                          DateFormatter.formatDate(booking.checkInDate),
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.arrow_forward_rounded,
                            size: 10.sp, color: AppColors.textHint),
                        SizedBox(width: 6.w),
                        Icon(Icons.logout_rounded,
                            size: 13.sp, color: AppColors.textHint),
                        SizedBox(width: 3.w),
                        Text(
                          DateFormatter.formatDate(booking.checkOutDate),
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                size: 13.sp, color: AppColors.textHint),
                            SizedBox(width: 4.w),
                            Text(
                              '${booking.adultCount ?? 0} adults, ${booking.childrenCount ?? 0} children',
                              style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(booking.price,
                              currency: booking.displayCurrency),
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 13.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
        return AppColors.upcoming;
      case 'checked_in':
      case 'ongoing':
        return AppColors.ongoing;
      case 'completed':
        return AppColors.completed;
      case 'cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBgColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
        return AppColors.upcomingLight;
      case 'checked_in':
      case 'ongoing':
        return AppColors.ongoingLight;
      case 'completed':
        return AppColors.completedLight;
      case 'cancelled':
        return AppColors.cancelledLight;
      default:
        return AppColors.surfaceVariant;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'upcoming':
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        label = 'Upcoming';
        break;
      case 'checked_in':
      case 'checked-in':
      case 'ongoing':
        color = AppColors.accentDark;
        bgColor = AppColors.accent.withValues(alpha: 0.2);
        label = 'Active';
        break;
      case 'completed':
        color = AppColors.textSecondary;
        bgColor = AppColors.surfaceVariant;
        label = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        bgColor = AppColors.errorLight;
        label = 'Cancelled';
        break;
      case 'awaiting payment':
        color = AppColors.warning;
        bgColor = AppColors.warningLight;
        label = 'Awaiting Payment';
        break;
      default:
        color = AppColors.textSecondary;
        bgColor = AppColors.surfaceVariant;
        label = status ?? 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
