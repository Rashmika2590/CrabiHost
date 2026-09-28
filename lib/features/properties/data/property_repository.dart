import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/hotel_model.dart';

class PropertyRepository {
  final _client = ApiClient.instance;

  /// Get all hotels owned by the logged-in host
  Future<List<HotelModel>> getMyHotels() async {
    final data = await _client.get('/hotel/owner');
    debugPrint('[PropertyRepository] RAW API RESPONSE (/hotel/owner):\n$data');

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(HotelModel.fromJson)
          .toList();
    }
    return [];
  }

  /// Get a single hotel's details
  Future<HotelModel> getHotelDetails(int hotelId) async {
    final data = await _client.get('/hotel/$hotelId');
    return HotelModel.fromJson(data as Map<String, dynamic>);
  }

  /// Enable or disable a hotel listing
  Future<void> toggleHotelEnabled(int hotelId, {required bool enable}) async {
    await _client.patch(
      '/hotel/enable-by-owner/$hotelId',
      queryParameters: {'enable_by_owner': enable},
    );
  }

  /// Get verification status for all owned hotels
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final data = await _client.get('/hotel/verification/owner/status');
    if (data is Map<String, dynamic>) return data;
    return {};
  }
}
