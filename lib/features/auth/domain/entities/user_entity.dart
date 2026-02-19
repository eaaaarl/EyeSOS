class UserEntity {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
  });
}
