import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_gradient_button.dart';
import '../domain/hotel_model.dart';
import 'providers/properties_provider.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final int hotelId;
  final HotelModel? hotel;

  const PropertyDetailScreen({
    super.key,
    required this.hotelId,
    this.hotel,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  HotelModel? _hotel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hotel = widget.hotel;
    if (_hotel == null) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final details =
          await ref.read(propertyRepositoryProvider).getHotelDetails(widget.hotelId);
      setState(() => _hotel = details);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWebPortal(String action) async {
    String url = '${AppConfig.webPortalUrl}/host/properties/${widget.hotelId}';
    if (action == 'edit') {
      url = '${AppConfig.webPortalUrl}/host/properties/${widget.hotelId}/edit';
    } else if (action == 'rooms') {
      url = '${AppConfig.webPortalUrl}/host/properties/${widget.hotelId}/rooms';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _toggleListing(bool enable) async {
    final hotel = _hotel;
    if (hotel == null) return;

    try {
      await ref.read(propertiesProvider.notifier).toggleEnabled(hotel.id, enable: enable);
      setState(() {
        _hotel = hotel.copyWith(enableByOwner: enable);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enable ? 'Property enabled for bookings' : 'Property hidden from search'),
            backgroundColor: enable ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final hotel = _hotel;
    if (hotel == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Property Details', style: TextStyle(fontSize: 18.sp))),
        body: const Center(child: Text('Property not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image Header
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                hotel.name,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 16.sp,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 8, color: Colors.black)],
                ),
              ),
              background: hotel.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: hotel.images.length,
                      itemBuilder: (context, index) => Image.network(
                        hotel.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: Icon(Icons.apartment_rounded, size: 60.sp),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.apartment_rounded, size: 60.sp, color: AppColors.textHint),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.open_in_browser_rounded, size: 22.sp),
                tooltip: 'Open in Web Portal',
                onPressed: () => _openWebPortal('view'),
              ),
            ],
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status & Quick Toggle Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Listing Status', style: AppTextStyles.labelLarge.copyWith(fontSize: 14.sp)),
                              SizedBox(height: 2.h),
                              Text(
                                hotel.enableByOwner ? 'Active & Bookable' : 'Hidden from Guests',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11.sp,
                                  color: hotel.enableByOwner ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: hotel.enableByOwner,
                            activeTrackColor: AppColors.primary,
                            onChanged: _toggleListing,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Web Redirection Callout Card
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22.sp),
                              SizedBox(width: 8.w),
                              Text('Advanced Host Actions', style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Edit rooms, calendar sync (iCal), photo albums, and banking information on Crabigo Web Portal.',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp),
                          ),
                          SizedBox(height: 14.h),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryGradientButton(
                                  text: 'Edit Property',
                                  icon: Icons.edit_note_rounded,
                                  onPressed: () => _openWebPortal('edit'),
                                  height: 46.h,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openWebPortal('rooms'),
                                  icon: Icon(Icons.king_bed_outlined, size: 18.sp),
                                  label: Text('Rooms & Rates', style: TextStyle(fontSize: 13.sp)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Overview & Description Card
                  if (hotel.description != null && hotel.description!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About the Property', style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            Divider(height: 24.h),
                            Text(
                              hotel.description!,
                              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Location & Contact Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location & Contact', style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                          Divider(height: 24.h),
                          _InfoRow(label: 'Address', value: hotel.address),
                          if (hotel.state != null) ...[
                            SizedBox(height: 10.h),
                            _InfoRow(label: 'State / Province', value: hotel.state!),
                          ],
                          if (hotel.email != null) ...[
                            SizedBox(height: 10.h),
                            _InfoRow(label: 'Host Email', value: hotel.email!),
                          ],
                          if (hotel.mobile != null || hotel.hotline != null) ...[
                            SizedBox(height: 10.h),
                            _InfoRow(label: 'Contact Number', value: hotel.mobile ?? hotel.hotline ?? ''),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // House Rules Card
                  if (hotel.rules.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('House Rules', style: AppTextStyles.headlineSmall.copyWith(fontSize: 15.sp)),
                            Divider(height: 24.h),
                            ...hotel.rules.map(
                              (rule) => Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        size: 16.sp, color: AppColors.accentDark),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text(rule, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13.sp))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp)),
        SizedBox(width: 12.w),
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
