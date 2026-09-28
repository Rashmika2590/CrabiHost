import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../bookings/domain/booking_model.dart';
import '../../properties/domain/hotel_model.dart';
import '../domain/dashboard_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Soft Radial Glow
          Positioned(
            top: -40.h,
            left: -30.w,
            right: -30.w,
            height: 220.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accentDark.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(dashboardProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Capsule Button Shaped Bar
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7518),
                                    Color(0xFFFF8C3B),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(36.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7518)
                                        .withValues(alpha: 0.28),
                                    blurRadius: 14.r,
                                    offset: Offset(0, 5.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20.r,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      authState.user?.initials ?? 'H',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: const Color(0xFFFF7518),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Good ${_greeting()}! 👋',
                                          style: TextStyle(
                                            fontSize: 10.5.sp,
                                            color: Colors.white
                                                .withValues(alpha: 0.92),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatName(authState.user?.fullName),
                                          style: TextStyle(
                                            fontSize: 14.5.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(right: 6.w),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 13.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Container(
                            height: 48.h,
                            width: 48.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B2A4A)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.logout_rounded,
                                color: const Color(0xFF1B2A4A),
                                size: 19.sp,
                              ),
                              tooltip: 'Sign out',
                              onPressed: () async {
                                final confirm = await _confirmLogout(context);
                                if (confirm == true) {
                                  ref.read(authProvider.notifier).logout();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Content Body
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  sliver: dashboardAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: _DashboardSkeleton(),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: _ErrorCard(
                        message: e.toString(),
                        onRetry: () => ref.refresh(dashboardProvider),
                      ),
                    ),
                    data: (summary) => SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 6.h),
                        // 1. Overview Live Stats (Directly after Header)
                        const _SectionTitle('Overview'),
                        //SizedBox(height: 10.h),
                        _Overview3DGrid(summary: summary),
                        //SizedBox(height: 22.h),

                        // 2. 3D Category Management Cards (Original Card Size)
                        const _SectionTitle('Manage'),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(
                              child: _3DCategoryCard(
                                imagePath: 'assets/images/3d/accommodation.jpg',
                                title: 'Properties',
                                subtitle:
                                    '${summary.properties.length} Listings',
                                onTap: () => context.go(AppRoutes.properties),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _3DCategoryCard(
                                imagePath: 'assets/images/3d/bookings.jpg',
                                title: 'Bookings',
                                subtitle:
                                    '${summary.totalActiveBookings} Active',
                                onTap: () => context.go(AppRoutes.bookings),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Center(
                          child: SizedBox(
                            width: 165.w,
                            height: 165.h,
                            child: _3DCategoryCard(
                              imagePath: 'assets/images/3d/bundled.jpg',
                              title: 'Web Portal',
                              subtitle: 'Admin & Settings',
                              onTap: () => _openWebPortal(context),
                            ),
                          ),
                        ),
                        SizedBox(height: 22.h),

                        // 3. Today's Activity Section
                        if (summary.todayCheckIns.isNotEmpty ||
                            summary.todayCheckOuts.isNotEmpty) ...[
                          const _SectionTitle("Today's Activity"),
                          SizedBox(height: 10.h),
                          _TodayActivityCard(summary: summary),
                          SizedBox(height: 22.h),
                        ],

                        // 4. Properties Preview Section
                        if (summary.properties.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('My Properties'),
                              TextButton(
                                onPressed: () =>
                                    context.go(AppRoutes.properties),
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ...summary.properties
                              .take(3)
                              .map((h) => _PropertySummaryCard(hotel: h)),
                          SizedBox(height: 20.h),
                        ],

                        // 5. Upcoming Bookings Section
                        if (summary.upcomingBookings.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionTitle('Upcoming Bookings'),
                              TextButton(
                                onPressed: () => context.go(AppRoutes.bookings),
                                child: Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ...summary.upcomingBookings
                              .take(3)
                              .map((b) => _BookingPreviewCard(booking: b)),
                        ],

                        SizedBox(height: 100.h),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _formatName(String? raw) {
    if (raw == null || raw.isEmpty) return 'Host';
    if (raw.contains('@')) {
      final parts = raw.split('@');
      final name = parts[0];
      return name[0].toUpperCase() + name.substring(1);
    }
    return raw;
  }

  Future<void> _openWebPortal(BuildContext context) async {
    final Uri uri = Uri.parse(AppConfig.webPortalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Crabigo Web Portal...'),
          ),
        );
      }
    }
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Sign Out',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1B2A4A),
        letterSpacing: -0.3,
      ),
    );
  }
}

// 3D Category Card component (Original Size)
class _3DCategoryCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _3DCategoryCard({
    required this.imagePath,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22.r),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.home_work_rounded,
                        size: 42.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF1B2A4A),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Overview Stats 2x2 Grid
class _Overview3DGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _Overview3DGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 1.35,
      children: [
        _3DStatCard(
          imagePath: 'assets/images/3d/bookings.jpg',
          label: 'Active Bookings',
          value: summary.totalActiveBookings.toString(),
          accentColor: AppColors.primary,
        ),
        _3DStatCard(
          imagePath: 'assets/images/3d/wallet.jpg',
          label: 'Total Revenue',
          value: CurrencyFormatter.formatCompact(summary.totalRevenue),
          accentColor: AppColors.accentDark,
        ),
        _IconStatCard(
          icon: Icons.login_rounded,
          iconColor: AppColors.success,
          iconBg: AppColors.successLight,
          label: "Today's Check-ins",
          value: summary.todayCheckIns.length.toString(),
        ),
        _IconStatCard(
          icon: Icons.logout_rounded,
          iconColor: AppColors.warning,
          iconBg: AppColors.warningLight,
          label: "Today's Check-outs",
          value: summary.todayCheckOuts.length.toString(),
        ),
      ],
    );
  }
}

class _3DStatCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final String value;
  final Color accentColor;

  const _3DStatCard({
    required this.imagePath,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.analytics_rounded,
                  color: accentColor, size: 26.sp),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B2A4A),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _IconStatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B2A4A),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayActivityCard extends StatelessWidget {
  final DashboardSummary summary;
  const _TodayActivityCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.05),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        children: [
          if (summary.todayCheckIns.isNotEmpty) ...[
            _ActivityRow(
              icon: Icons.login_rounded,
              color: AppColors.success,
              label: 'Check-ins Today',
              count: summary.todayCheckIns.length,
            ),
            if (summary.todayCheckOuts.isNotEmpty) Divider(height: 18.h),
          ],
          if (summary.todayCheckOuts.isNotEmpty)
            _ActivityRow(
              icon: Icons.logout_rounded,
              color: AppColors.warning,
              label: 'Check-outs Today',
              count: summary.todayCheckOuts.length,
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B2A4A),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
                fontSize: 11.5.sp, color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  final HotelModel hotel;
  const _PropertySummaryCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => context.go('/properties/${hotel.id}', extra: hotel),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: hotel.primaryImage.isNotEmpty
              ? Image.network(
                  hotel.primaryImage,
                  width: 48.w,
                  height: 48.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlaceholderImage(),
                )
              : _PlaceholderImage(),
        ),
        title: Text(
          hotel.name,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B2A4A),
          ),
        ),
        subtitle: Text(
          hotel.displayLocation,
          style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: hotel.enableByOwner
                ? AppColors.successLight
                : AppColors.errorLight,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            hotel.enableByOwner ? 'Active' : 'Disabled',
            style: TextStyle(
              fontSize: 10.sp,
              color: hotel.enableByOwner ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child:
          Icon(Icons.home_work_rounded, color: AppColors.textHint, size: 22.sp),
    );
  }
}

class _BookingPreviewCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingPreviewCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.upcomingLight,
          child: Text(
            booking.displayGuestName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          booking.displayGuestName,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B2A4A),
          ),
        ),
        subtitle: Text(
          'Check-in: ${DateFormatter.formatDate(booking.checkInDate)}',
          style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(
                booking.price,
                currency: booking.displayCurrency,
              ),
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              DateFormatter.relativeDate(booking.checkInDate),
              style:
                  TextStyle(fontSize: 9.5.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        onTap: () => context.go('/bookings/${booking.id}', extra: booking),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          height: 75.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A4A).withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            'Failed to load dashboard',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B2A4A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            message,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          PrimaryGradientButton(
            text: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            width: 140.w,
            height: 44.h,
          ),
        ],
      ),
    );
  }
}
