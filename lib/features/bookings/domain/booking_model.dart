enum BookingFilter { upcoming, ongoing, completed }

class BookingItem {
  final int id;
  final int bookingId;
  final int roomId;
  final int roomAdultCount;
  final int roomChildrenCount;
  final double roomPrice;
  final String? currency;

  const BookingItem({
    required this.id,
    required this.bookingId,
    required this.roomId,
    required this.roomAdultCount,
    required this.roomChildrenCount,
    required this.roomPrice,
    this.currency,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return BookingItem(
      id: parseId(json['id']),
      bookingId: parseId(json['booking_id']),
      roomId: parseId(json['room_id']),
      roomAdultCount: (json['room_adult_count'] as num?)?.toInt() ?? 0,
      roomChildrenCount: (json['room_children_count'] as num?)?.toInt() ?? 0,
      roomPrice: (json['room_price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString(),
    );
  }
}

class BookingModel {
  final int id;
  final String userId;
  final String? status;
  final DateTime? checkInDate;
  final String? checkInTime;
  final DateTime? checkOutDate;
  final String? checkOutTime;
  final int? adultCount;
  final int? childrenCount;
  final String? specialRequest;
  final double? price;
  final String? currency;
  final String? paymentMethod;
  final String? paymentReference;
  final String? promoCode;
  final DateTime? bookingTime;
  final String? phoneNumber;
  final String? guestName;
  final String? guestEmail;
  final String? guestPhone;
  final String? relationshipToUser;
  final bool freeCancellation;
  final List<BookingItem> bookingItems;

  const BookingModel({
    required this.id,
    this.userId = 'guest',
    this.status,
    this.checkInDate,
    this.checkInTime,
    this.checkOutDate,
    this.checkOutTime,
    this.adultCount,
    this.childrenCount,
    this.specialRequest,
    this.price,
    this.currency,
    this.paymentMethod,
    this.paymentReference,
    this.promoCode,
    this.bookingTime,
    this.phoneNumber,
    this.guestName,
    this.guestEmail,
    this.guestPhone,
    this.relationshipToUser,
    this.freeCancellation = false,
    this.bookingItems = const [],
  });

  String get displayStatus {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'upcoming':
        return 'Upcoming';
      case 'checked_in':
      case 'checked-in':
        return 'Checked In';
      case 'ongoing':
        return 'Active';
      case 'checked_out':
      case 'checked-out':
        return 'Checked Out';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'awaiting payment':
        return 'Awaiting Payment';
      default:
        return status ?? 'Confirmed';
    }
  }

  String get displayGuestName {
    if (guestName != null && guestName!.isNotEmpty) return guestName!;
    return 'Guest #$id';
  }

  String get displayCurrency => currency ?? 'LKR';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      final str = val.toString();
      if (str.isEmpty) return null;
      try {
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

    final ci = json['ci_date'] ?? json['check_in_date'] ?? json['check_in'] ?? json['checkIn'];
    final co = json['co_date'] ?? json['check_out_date'] ?? json['check_out'] ?? json['checkOut'];
    final bt = json['booking_time'] ?? json['created_at'] ?? json['created_time'];

    return BookingModel(
      id: parseId(json['id'] ?? json['booking_id']),
      userId: json['user_id']?.toString() ?? json['user_uid']?.toString() ?? 'guest',
      status: json['status']?.toString(),
      checkInDate: parseDate(ci),
      checkInTime: json['ci_time']?.toString() ?? json['check_in_time']?.toString(),
      checkOutDate: parseDate(co),
      checkOutTime: json['co_time']?.toString() ?? json['check_out_time']?.toString(),
      adultCount: (json['adult_count'] as num?)?.toInt() ?? (json['adults'] as num?)?.toInt(),
      childrenCount: (json['children_count'] as num?)?.toInt() ?? (json['children'] as num?)?.toInt(),
      specialRequest: json['special_request']?.toString() ?? json['notes']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? (json['total_price'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentReference: json['payment_reference']?.toString(),
      promoCode: json['promo_code']?.toString(),
      bookingTime: parseDate(bt),
      phoneNumber: json['phone_number']?.toString() ?? json['guestPhone']?.toString(),
      guestName: json['guestName']?.toString() ?? json['guest_name']?.toString() ?? json['user_name']?.toString(),
      guestEmail: json['guestEmail']?.toString() ?? json['guest_email']?.toString() ?? json['email']?.toString(),
      guestPhone: json['guestPhone']?.toString() ?? json['guest_phone']?.toString() ?? json['phone']?.toString(),
      relationshipToUser: json['relationshiptoUser']?.toString() ?? json['relationship_to_user']?.toString(),
      freeCancellation: json['free_cancellation'] as bool? ?? false,
      bookingItems: (json['booking_items'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BookingItem.fromJson)
              .toList() ??
          const [],
    );
  }
}
