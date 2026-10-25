import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CrabiHostLogo extends StatelessWidget {
  final double height;

  const CrabiHostLogo({
    super.key,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo/crab_icon.png',
          height: height.h,
          width: height.h,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 8.w),
        SvgPicture.asset(
          'assets/images/logo/crabihost_text.svg',
          height: (height * 0.72).h,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
