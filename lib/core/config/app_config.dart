import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['API_BASE_URL'] ??
          'https://crabi-go-backend.t7gbzs75g5tc2.ap-southeast-1.cs.amazonlightsail.com';
    }
    return 'https://crabi-go-backend.t7gbzs75g5tc2.ap-southeast-1.cs.amazonlightsail.com';
  }

  static String get webPortalUrl {
    if (dotenv.isInitialized) {
      return dotenv.env['WEB_PORTAL_URL'] ?? 'https://crabigo.com';
    }
    return 'https://crabigo.com';
  }

  static String get appName {
    if (dotenv.isInitialized) {
      return dotenv.env['APP_NAME'] ?? 'Crabigo Host';
    }
    return 'Crabigo Host';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Web portal paths
  static String propertyEditUrl(int hotelId) =>
      '$webPortalUrl/host/properties/$hotelId/edit';
  static String propertyListingsUrl() => '$webPortalUrl/host/properties';
}
