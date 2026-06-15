import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في قراءة البيانات المحلية']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'خطأ في المصادقة، يرجى تسجيل الدخول مجدداً']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'المحتوى غير موجود']);
}
