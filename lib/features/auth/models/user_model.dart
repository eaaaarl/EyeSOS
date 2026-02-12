class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMetaData = json['user_metadata'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: userMetaData?['full_name'] ?? '',
      phoneNumber: userMetaData?['phone'] ?? '',
      avatarUrl: userMetaData?['avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'user_metadata': {
        'full_name': fullName,
        'phone': phoneNumber,
        'avatar_url': avatarUrl,
      },
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
