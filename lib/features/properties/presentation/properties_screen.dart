import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../domain/hotel_model.dart';
import 'providers/properties_provider.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  Future<void> _openWebPortal(BuildContext context, {int? hotelId, String? action}) async {
    String url = AppConfig.webPortalUrl;
    if (hotelId != null) {
      if (action == 'edit') {
        url = '${AppConfig.webPortalUrl}/host/properties/$hotelId/edit';
      } else if (action == 'rooms') {
        url = '${AppConfig.webPortalUrl}/host/properties/$hotelId/rooms';
      } else {
        url = '${AppConfig.webPortalUrl}/host/properties/$hotelId';
      }
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _showAdvancedActionsModal(BuildContext context, HotelModel hotel) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.open_in_browser_rounded, color: AppColors.primary, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Web Portal Management', style: AppTextStyles.headlineSmall.copyWith(fontSize: 16.sp)),
                        Text(
                          'Advanced configuration on Crabigo Web',
                          style: AppTextStyles.caption.copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              const Divider(),
              ListTile(
                leading: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22.sp),
                title: Text('Edit Property Details', style: TextStyle(fontSize: 14.sp)),
                subtitle: Text('Photos, amenities, pricing & policies on web portal', style: TextStyle(fontSize: 12.sp)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWebPortal(context, hotelId: hotel.id, action: 'edit');
                },
              ),
              ListTile(
                leading: Icon(Icons.meeting_room_rounded, color: AppColors.accentDark, size: 22.sp),
                title: Text('Manage Rooms & Inventory', style: TextStyle(fontSize: 14.sp)),
                subtitle: Text('Set room types, ical sync & rates', style: TextStyle(fontSize: 12.sp)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWebPortal(context, hotelId: hotel.id, action: 'rooms');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22.sp),
                title: Text('Delete / Delist Listing', style: TextStyle(fontSize: 14.sp)),
                subtitle: Text('Requires owner confirmation on web portal', style: TextStyle(fontSize: 12.sp)),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWebPortal(context, hotelId: hotel.id, action: 'delete');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Properties', style: TextStyle(fontSize: 18.sp)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business_rounded, size: 22.sp),
            tooltip: 'Add Property on Web',
            onPressed: () => _openWebPortal(context),
          ),
        ],
      ),
      body: propertiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
              SizedBox(height: 12.h),
              Text(e.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)),
              SizedBox(height: 16.h),
              PrimaryGradientButton(
                text: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.read(propertiesProvider.notifier).load(),
                width: 140.w,
                height: 44.h,
              ),
            ],
          ),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_outlined, color: AppColors.textHint, size: 56.sp),
                  SizedBox(height: 16.h),
                  Text('No properties listed yet', style: AppTextStyles.headlineSmall.copyWith(fontSize: 16.sp)),
                  SizedBox(height: 8.h),
                  Text('Add your first property via Crabigo Web Portal', style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp)),
                  SizedBox(height: 20.h),
                  PrimaryGradientButton(
                    text: 'Open Web Portal',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => _openWebPortal(context),
                    width: 200.w,
                    height: 48.h,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(propertiesProvider.notifier).load(),
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: properties.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final hotel = properties[index];
                return _PropertyCard(
                  hotel: hotel,
                  onToggle: (val) {
                    ref.read(propertiesProvider.notifier).toggleEnabled(hotel.id, enable: val);
                  },
                  onManageWeb: () => _showAdvancedActionsModal(context, hotel),
                  onTap: () => context.go('/properties/${hotel.id}', extra: hotel),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final HotelModel hotel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onManageWeb;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.hotel,
    required this.onToggle,
    required this.onManageWeb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image Header with badges
            Stack(
              children: [
                Container(
                  height: 160.h,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: hotel.primaryImage.isNotEmpty
                      ? Image.network(
                          hotel.primaryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.broken_image_rounded, size: 40.sp, color: AppColors.textHint),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.apartment_rounded, size: 48.sp, color: AppColors.textHint),
                        ),
                ),
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: hotel.isVerified ? AppColors.accentDark : AppColors.warning,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hotel.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          hotel.isVerified ? 'Verified' : 'Pending Verification',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hotel.category != null && hotel.category!.isNotEmpty)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        hotel.category!,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16.sp),
                          SizedBox(width: 3.w),
                          Text(
                            hotel.reviewRating != null ? hotel.reviewRating!.toStringAsFixed(1) : 'New',
                            style: AppTextStyles.labelMedium.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                          if (hotel.totalReviews > 0)
                            Text(' (${hotel.totalReviews})', style: AppTextStyles.caption.copyWith(fontSize: 10.sp)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13.sp, color: AppColors.textSecondary),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          hotel.displayLocation,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20.h),

                  // Host Quick Toggles & Web Redirection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch.adaptive(
                            value: hotel.enableByOwner,
                            activeTrackColor: AppColors.primary,
                            onChanged: onToggle,
                          ),
                          Text(
                            hotel.enableByOwner ? 'Listed' : 'Unlisted',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: 12.sp,
                              color: hotel.enableByOwner ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: onManageWeb,
                        icon: Icon(Icons.open_in_browser_rounded, size: 15.sp),
                        label: Text('Manage on Web', style: TextStyle(fontSize: 12.sp)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
    );
  }
}
