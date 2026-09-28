import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../domain/booking_model.dart';

class BookingRepository {
  final _client = ApiClient.instance;

  /// Fetch all bookings for the host across all properties
  Future<List<BookingModel>> getOwnerBookings({
    BookingFilter filter = BookingFilter.upcoming,
    int skip = 0,
    int limit = 100,
    String? search,
  }) async {
    final data = await _client.get(
      '/hotel/owner/bookings',
      queryParameters: {
        'filter': filter.name,
        'skip': skip,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    debugPrint('[BookingRepository] RAW API RESPONSE (/hotel/owner/bookings - filter=${filter.name}):\n$data');
    return _parseBookingList(data);
  }

  /// Fetch bookings for a specific hotel
  Future<List<BookingModel>> getHotelBookings(
    int hotelId, {
    BookingFilter? filter,
    int skip = 0,
    int limit = 100,
  }) async {
    final data = await _client.get(
      '/hotel/$hotelId/bookings',
      queryParameters: {
        if (filter != null) 'filter': filter.name,
        'skip': skip,
        'limit': limit,
      },
    );
    return _parseBookingList(data);
  }

  /// Update booking status (check-in, check-out, cancel, etc.)
  Future<void> updateBookingStatus(
    int bookingId, {
    required String status,
    String? cancellationReason,
  }) async {
    await _client.patch(
      '/booking/$bookingId/status',
      data: {
        'status': status,
        if (cancellationReason != null)
          'cancellation_reason': cancellationReason,
      },
    );
  }

  List<BookingModel> _parseBookingList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(BookingModel.fromJson)
          .toList();
    }
    if (data is Map) {
      final list = data['bookings'] ?? data['data'] ?? data['results'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(BookingModel.fromJson)
            .toList();
      }
    }
    return [];
  }
}
