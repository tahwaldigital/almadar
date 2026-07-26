import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String avatarUrl;
  final String token;
  final bool emailVerified;

  /// دور المستخدم في ووردبريس (administrator / editor / author / subscriber ...).
  /// يُملأ من الخادم؛ يُستخدم لإظهار لوحة التحرير للمصرّح لهم فقط.
  final String role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.token,
    this.emailVerified = true,
    this.role = '',
  });

  /// هل يملك المستخدم صلاحية نشر الأخبار من التطبيق؟
  bool get canPublish =>
      role == 'administrator' || role == 'editor' || role == 'author';

  @override
  List<Object?> get props => [id, email, role];
}
