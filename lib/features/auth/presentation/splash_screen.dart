import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crabihost_logo.dart';

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
            // Full Official CrabiHost Logo (Crab Character + CRABiHost Text)
            const CrabiHostLogo(height: 64),
            SizedBox(height: 36.h),

            // Loading indicator styled with #45DFCD (Turquoise Accent)
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: const CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
