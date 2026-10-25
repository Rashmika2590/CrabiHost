import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/bookings/presentation/booking_detail_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/properties/presentation/properties_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/properties/domain/hotel_model.dart';

// Route paths
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const bookings = '/bookings';
  static const bookingDetail = '/bookings/:id';
  static const properties = '/properties';
  static const propertyDetail = '/properties/:id';
  static const notifications = '/notifications';
  static const profile = '/profile';
}

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  // Only react to authentication status changes so that updating user profile
  // or other state does not re-instantiate GoRouter and destroy the navigation stack.
  final authStatus = ref.watch(authProvider.select((s) => s.status));

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final status = authStatus;
      final isAuthRoute = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // Still initializing
      if (status == AuthStatus.unknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      // Not authenticated
      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      // Authenticated but on login/splash
      if (status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplash) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            builder: (_, __) => const BookingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'] ?? '0';
                  final id = int.tryParse(idStr) ?? 0;
                  final booking = state.extra;
                  return BookingDetailScreen(bookingId: id, booking: booking);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.properties,
            builder: (_, __) => const PropertiesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final idStr = state.pathParameters['id'] ?? '0';
                  final id = int.tryParse(idStr) ?? 0;
                  final hotel = state.extra as HotelModel?;
                  return PropertyDetailScreen(hotelId: id, hotel: hotel);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationCenterScreen(),
          ),
        ],
      ),
      // Full-page standard route pushed on the root navigator
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          name: 'profile',
          child: const ProfileScreen(),
        ),
      ),
    ],
  );
});

class _MainShell extends ConsumerWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  static const items = [
    (icon: Icons.dashboard_rounded, route: AppRoutes.dashboard),
    (icon: Icons.calendar_month_rounded, route: AppRoutes.bookings),
    (icon: Icons.home_work_rounded, route: AppRoutes.properties),
    (icon: Icons.notifications_rounded, route: AppRoutes.notifications),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/bookings')) currentIndex = 1;
    if (location.startsWith('/properties')) currentIndex = 2;
    if (location.startsWith('/notifications')) currentIndex = 3;

    return SafeArea(
      top: false,
      child: Container(
        height: 72.h,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = 54.h;
            final itemWidth = width / items.length;
            final targetX = (currentIndex + 0.5) * itemWidth;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: targetX, end: targetX),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, animatedX, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Curved Turquoise Capsule Background
                    Positioned(
                      top: 10.h,
                      left: 0,
                      right: 0,
                      height: height,
                      child: CustomPaint(
                        painter: _CurvedCapsulePainter(
                          activeX: animatedX,
                          color: AppColors.accentDark, // #1FC2B0 / #45DFCD
                        ),
                      ),
                    ),

                    // Active Floating White Circle Badge
                    Positioned(
                      left: animatedX - 25.w,
                      top: 0.h,
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          items[currentIndex].icon,
                          color: AppColors.primary, // Vibrant Orange #FF7518
                          size: 26.sp,
                        ),
                      ),
                    ),

                    // Interactive Tab Icons Row
                    Positioned(
                      top: 10.h,
                      left: 0,
                      right: 0,
                      height: height,
                      child: Row(
                        children: List.generate(items.length, (index) {
                          final isSelected = index == currentIndex;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                switch (index) {
                                  case 0:
                                    context.go(AppRoutes.dashboard);
                                    break;
                                  case 1:
                                    context.go(AppRoutes.bookings);
                                    break;
                                  case 2:
                                    context.go(AppRoutes.properties);
                                    break;
                                  case 3:
                                    context.go(AppRoutes.notifications);
                                    break;
                                }
                              },
                              child: Container(
                                alignment: Alignment.center,
                                child: isSelected
                                    ? const SizedBox.shrink()
                                    : Icon(
                                        items[index].icon,
                                        color: Colors.white,
                                        size: 24.sp,
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CurvedCapsulePainter extends CustomPainter {
  final double activeX;
  final Color color;

  _CurvedCapsulePainter({required this.activeX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final r = size.height / 2;
    final w = size.width;
    final h = size.height;

    // Start top-left corner
    path.moveTo(r, 0);

    // Concave cutout notch parameters matching Figma image
    const notchW = 36.0;
    const notchH = 20.0;

    if (activeX > r && activeX < w - r) {
      path.lineTo(activeX - notchW, 0);
      path.cubicTo(
        activeX - notchW * 0.5,
        0,
        activeX - notchW * 0.4,
        notchH,
        activeX,
        notchH,
      );
      path.cubicTo(
        activeX + notchW * 0.4,
        notchH,
        activeX + notchW * 0.5,
        0,
        activeX + notchW,
        0,
      );
    }

    // Top-right corner arc
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));

    // Bottom edge to bottom-left corner arc
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));

    path.close();

    canvas.drawPath(path.shift(const Offset(0, 5)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedCapsulePainter oldDelegate) {
    return oldDelegate.activeX != activeX || oldDelegate.color != color;
  }
}
