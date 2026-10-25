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

  /// Display First Name specifically for greetings and app headers
  String get displayFirstName {
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return firstName!.trim();
    }
    // If fullName is set and not identical to email
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return lastName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      final local = email!.split('@').first.trim();
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'Host';
  }

  /// Full formatted name (First + Last)
  String get fullName {
    final f = firstName?.trim() ?? '';
    final l = lastName?.trim() ?? '';
    if (f.isNotEmpty && l.isNotEmpty) {
      return '$f $l';
    }
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    return 'Host';
  }

  /// 1 or 2 letter uppercase initials for avatar placeholder
  String get initials {
    final f = firstName?.trim() ?? '';
    final l = lastName?.trim() ?? '';
    if (f.isNotEmpty && l.isNotEmpty) {
      return '${f[0]}${l[0]}'.toUpperCase();
    }
    if (f.isNotEmpty) {
      return f[0].toUpperCase();
    }
    if (l.isNotEmpty) {
      return l[0].toUpperCase();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim()[0].toUpperCase();
    }
    return 'H';
  }

  /// Formatted contact phone or placeholder
  String get displayPhone {
    if (phone != null && phone!.trim().isNotEmpty) {
      return phone!.trim();
    }
    return 'Not provided';
  }

  /// Formatted role (e.g. 'Host', 'Superhost')
  String get displayRole {
    if (role != null && role!.trim().isNotEmpty) {
      final r = role!.trim();
      return r[0].toUpperCase() + r.substring(1).toLowerCase();
    }
    return 'Verified Host';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Unwrap if nested under 'data' or 'user'
    final map = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['user'] is Map<String, dynamic>)
            ? json['user'] as Map<String, dynamic>
            : json;

    String? fName = map['first_name']?.toString() ??
        map['firstName']?.toString() ??
        map['given_name']?.toString();
    String? lName = map['last_name']?.toString() ??
        map['lastName']?.toString() ??
        map['family_name']?.toString();

    // If first_name not explicitly provided, extract from full 'name' or 'display_name'
    if (fName == null || fName.trim().isEmpty) {
      final nameRaw = map['name']?.toString() ??
          map['full_name']?.toString() ??
          map['display_name']?.toString() ??
          map['displayName']?.toString();

      if (nameRaw != null && nameRaw.trim().isNotEmpty) {
        final parts = nameRaw.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          fName = parts.first;
          if (parts.length > 1 && (lName == null || lName.trim().isEmpty)) {
            lName = parts.sublist(1).join(' ');
          }
        }
      }
    }

    return UserModel(
      uid: map['uid']?.toString() ??
          map['user_id']?.toString() ??
          map['id']?.toString() ??
          '',
      email: map['email']?.toString(),
      firstName: fName,
      lastName: lName,
      phone: map['phone']?.toString() ??
          map['phone_number']?.toString() ??
          map['contact_number']?.toString(),
      profileImageUrl: map['profile_image']?.toString() ??
          map['profile_image_url']?.toString() ??
          map['avatar_url']?.toString() ??
          map['avatar']?.toString() ??
          map['image_url']?.toString(),
      role: map['role']?.toString() ?? map['user_role']?.toString(),
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
