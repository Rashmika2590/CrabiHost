import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Centered SVG Logo (150x150)
            SvgPicture.asset(
              'assets/images/logo/crabihost_logo.svg',
              width: 150.w,
              height: 150.h,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Container(
                width: 150.w,
                height: 150.h,
                alignment: Alignment.center,
                child: Text(
                  'CrabiHost',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),

            // Loading indicator styled with #45DFCD (Turquoise Accent)
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: const CircularProgressIndicator(
                color: AppColors.accent, // #45DFCD
                strokeWidth: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
