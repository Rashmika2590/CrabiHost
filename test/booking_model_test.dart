import 'package:flutter_test/flutter_test.dart';
import 'package:crabihost/features/bookings/domain/booking_model.dart';

void main() {
  group('BookingModel Tests', () {
    test('fromJson parses API booking payload correctly', () {
      final json = {
        'id': 101,
        'user_id': 'user_123',
        'status': 'confirmed',
        'ci_date': '2026-09-25',
        'ci_time': '14:00:00',
        'co_date': '2026-09-28',
        'co_time': '11:00:00',
        'adult_count': 2,
        'children_count': 1,
        'special_request': 'High floor please',
        'price': 45000.0,
        'currency': 'LKR',
        'payment_method': 'card',
        'payment_reference': 'PAY-98765',
        'guestName': 'John Doe',
        'guestEmail': 'john@example.com',
        'guestPhone': '+94771234567',
        'free_cancellation': true,
        'booking_items': [
          {
            'id': 1,
            'booking_id': 101,
            'room_id': 5,
            'room_adult_count': 2,
            'room_children_count': 1,
            'room_price': 45000.0,
            'currency': 'LKR',
          }
        ],
      };

      final booking = BookingModel.fromJson(json);

      expect(booking.id, 101);
      expect(booking.displayGuestName, 'John Doe');
      expect(booking.displayStatus, 'Confirmed');
      expect(booking.price, 45000.0);
      expect(booking.displayCurrency, 'LKR');
      expect(booking.freeCancellation, isTrue);
      expect(booking.bookingItems.length, 1);
      expect(booking.bookingItems.first.roomId, 5);
    });

    test('displayGuestName fallback works', () {
      const booking = BookingModel(id: 42, userId: 'u1');
      expect(booking.displayGuestName, 'Guest #42');
    });
  });
}
