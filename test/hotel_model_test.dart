import 'package:flutter_test/flutter_test.dart';
import 'package:crabihost/features/properties/domain/hotel_model.dart';

void main() {
  group('HotelModel Tests', () {
    test('fromJson parses HotelRead payload correctly', () {
      final json = {
        'id': 10,
        'name': 'Coral Rock Villa',
        'category': 'Villa',
        'address': 'Beach Road, Bentota',
        'state': 'Southern Province',
        'postal_code': '80500',
        'latitude': 6.425,
        'longitude': 79.998,
        'rules': ['No smoking', 'No pets'],
        'email': 'coral@crabigo.com',
        'mobile': '+94712345678',
        'images': ['https://example.com/hotel.jpg'],
        'description': 'Beautiful seaside boutique villa.',
        'user_uid': 'owner_001',
        'review_rating': 4.8,
        'total_reviews': 32,
        'is_verified': true,
        'enable_by_owner': true,
        'enable_by_admin': true,
      };

      final hotel = HotelModel.fromJson(json);

      expect(hotel.id, 10);
      expect(hotel.name, 'Coral Rock Villa');
      expect(hotel.category, 'Villa');
      expect(hotel.isActive, isTrue);
      expect(hotel.primaryImage, 'https://example.com/hotel.jpg');
      expect(hotel.displayLocation, 'Southern Province, Sri Lanka');
      expect(hotel.rules.length, 2);
    });

    test('copyWith enables and disables owner status', () {
      const hotel = HotelModel(
        id: 1,
        name: 'Test Hotel',
        address: 'Colombo',
        userUid: 'uid1',
        enableByOwner: true,
      );

      final disabled = hotel.copyWith(enableByOwner: false);
      expect(disabled.enableByOwner, isFalse);
    });
  });
}
