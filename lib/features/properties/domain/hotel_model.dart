class HotelModel {
  final int id;
  final String name;
  final String? category;
  final String address;
  final String? city;
  final String? state;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final List<String> rules;
  final String? email;
  final String? hotline;
  final String? mobile;
  final String? whatsapp;
  final List<String> images;
  final String? description;
  final String userUid;
  final double? reviewRating;
  final int totalReviews;
  final bool isVerified;
  final bool enableByOwner;
  final bool enableByAdmin;
  final double? cancellationPercentage;

  const HotelModel({
    required this.id,
    required this.name,
    this.category,
    this.address = '',
    this.city,
    this.state,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.rules = const [],
    this.email,
    this.hotline,
    this.mobile,
    this.whatsapp,
    this.images = const [],
    this.description,
    this.userUid = '',
    this.reviewRating,
    this.totalReviews = 0,
    this.isVerified = false,
    this.enableByOwner = true,
    this.enableByAdmin = true,
    this.cancellationPercentage,
  });

  bool get isActive => enableByOwner && enableByAdmin;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  String get displayLocation {
    if (city != null && city!.isNotEmpty) {
      return '$city, ${state ?? 'Sri Lanka'}';
    }
    if (state != null && state!.isNotEmpty) {
      return '$state, Sri Lanka';
    }
    return address.isNotEmpty ? address : 'Sri Lanka';
  }

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return HotelModel(
      id: parseId(json['id'] ?? json['hotel_id']),
      name: json['name']?.toString() ?? 'Unnamed Property',
      category: json['category']?.toString(),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      email: json['email']?.toString(),
      hotline: json['hotline']?.toString(),
      mobile: json['mobile']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['primary_image'] != null ? [json['primary_image'].toString()] : const []),
      description: json['description']?.toString(),
      userUid: json['user_uid']?.toString() ?? json['user_id']?.toString() ?? '',
      reviewRating: (json['review_rating'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble(),
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? json['verified'] as bool? ?? false,
      enableByOwner: json['enable_by_owner'] as bool? ?? json['enabled'] as bool? ?? true,
      enableByAdmin: json['enable_by_admin'] as bool? ?? true,
      cancellationPercentage:
          (json['cancellation_percentage'] as num?)?.toDouble(),
    );
  }

  HotelModel copyWith({
    bool? enableByOwner,
    bool? isVerified,
    String? name,
  }) {
    return HotelModel(
      id: id,
      name: name ?? this.name,
      category: category,
      address: address,
      city: city,
      state: state,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      rules: rules,
      email: email,
      hotline: hotline,
      mobile: mobile,
      whatsapp: whatsapp,
      images: images,
      description: description,
      userUid: userUid,
      reviewRating: reviewRating,
      totalReviews: totalReviews,
      isVerified: isVerified ?? this.isVerified,
      enableByOwner: enableByOwner ?? this.enableByOwner,
      enableByAdmin: enableByAdmin,
      cancellationPercentage: cancellationPercentage,
    );
  }
}
