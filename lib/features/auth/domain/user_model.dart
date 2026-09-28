class UserModel {
  final String uid;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImageUrl;
  final String? role;

  const UserModel({
    required this.uid,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.profileImageUrl,
    this.role,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return firstName ?? lastName ?? email ?? 'Host';
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'H';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString(),
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString(),
      phone: json['phone']?.toString() ?? json['phone_number']?.toString(),
      profileImageUrl: json['profile_image']?.toString() ??
          json['image_url']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'profile_image': profileImageUrl,
        'role': role,
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
    );
  }
}
