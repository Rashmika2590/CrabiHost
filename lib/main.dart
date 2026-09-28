import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/data/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Env] .env file load notice: $e');
  }

  // Safely initialize Firebase Core
  try {
    await Firebase.initializeApp();
    debugPrint('[Firebase] Firebase App initialized successfully.');
  } catch (e) {
    debugPrint('[Firebase] Firebase initialization skipped/failed: $e');
  }

  // Initialize native HTTP ApiClient
  ApiClient.instance.init();

  // Initialize FCM and local notification services
  try {
    await FcmService.instance.init();
  } catch (e) {
    debugPrint('[Notifications] Notification service init notice: $e');
  }

  runApp(
    const ProviderScope(
      child: CrabigoHostApp(),
    ),
  );
}

class CrabigoHostApp extends ConsumerWidget {
  const CrabigoHostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,
          routerConfig: router,
        );
      },
    );
  }
}
