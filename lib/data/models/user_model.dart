import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.avatarUrl,
    required super.token,
  });

  // Handles both the Almadar API user shape ({name, email, avatar, username})
  // and the locally cached shape ({name, email, avatar_url, token}).
  factory UserModel.fromJson(Map<String, dynamic> json, {String token = ''}) =>
      UserModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ??
            json['display_name'] as String? ??
            json['username'] as String? ??
            '',
        email: json['email'] as String? ?? json['user_email'] as String? ?? '',
        avatarUrl: json['avatar'] as String? ?? json['avatar_url'] as String? ?? '',
        token: json['token'] as String? ?? token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'token': token,
      };
}
