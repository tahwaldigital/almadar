import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.avatarUrl,
    required super.token,
    super.emailVerified,
    super.role,
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
        // الافتراضي true فقط عندما لا يرسل الخادم الحقل إطلاقًا (توافق خلفي).
        // إن أرسله بأي صيغة، نحترم قيمته ولا نتجاوز تدفّق التأكيد.
        emailVerified: _parseVerified(json),
        role: _parseRole(json),
      );

  // يقبل bool أو 0/1 أو "true"/"false" من الخادم.
  static bool _parseVerified(Map<String, dynamic> json) {
    final v = json['email_verified'];
    if (v == null) return true; // الحقل غير مُرسَل — لا نمنع المستخدم.
    return v == true || v == 1 || v == '1' || v == 'true';
  }

  // يقبل عدة أشكال من الخادم: role (نص)، roles (قائمة)، أو is_admin (منطقي).
  static String _parseRole(Map<String, dynamic> json) {
    final role = json['role'];
    if (role is String && role.isNotEmpty) return role;
    final roles = json['roles'];
    if (roles is List && roles.isNotEmpty) return roles.first.toString();
    if (json['is_admin'] == true) return 'administrator';
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'token': token,
        'email_verified': emailVerified,
        'role': role,
      };
}
