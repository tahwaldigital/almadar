import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<UserModel> socialLogin(String provider, String email, String name);
  Future<void> logout();
  Future<bool> validateToken();
  Future<UserModel> getMe();
  Future<UserModel> updateMe({String? name, String? bio, String? password});
  Future<void> deleteAccount();
  Future<UserModel> verifyEmail(String email, String code);
  Future<void> resendCode(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRemoteDataSourceImpl(this._dio, this._secureStorage);

  /// Stores tokens and builds the user from the auth payload
  /// { token, refresh_token, user: {...} }.
  Future<UserModel> _handleAuthPayload(Map<String, dynamic> data) async {
    final token = data['token'] as String? ?? '';
    final refresh = data['refresh_token'] as String? ?? '';
    await _secureStorage.write(key: ApiConstants.tokenKey, value: token);
    if (refresh.isNotEmpty) {
      await _secureStorage.write(key: ApiConstants.refreshKey, value: refresh);
    }
    final user = (data['user'] as Map<String, dynamic>?) ?? const {};
    return UserModel.fromJson(user, token: token);
  }

  Map<String, dynamic> _data(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return (body as Map<String, dynamic>?) ?? const {};
  }

  @override
  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {'username': username, 'password': password},
      );
      return _handleAuthPayload(_data(response.data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: {'name': name, 'email': email, 'password': password},
      );
      return _handleAuthPayload(_data(response.data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'فشل إنشاء الحساب: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> socialLogin(String provider, String email, String name) async {
    try {
      final response = await _dio.post(
        ApiConstants.authSocial,
        data: {'provider': provider, 'email': email, 'name': name},
      );
      return _handleAuthPayload(_data(response.data));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: ApiConstants.tokenKey);
    await _secureStorage.delete(key: ApiConstants.refreshKey);
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.post(ApiConstants.authDelete);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    } finally {
      // امسح الجلسة محليًا في كل الأحوال بعد طلب الحذف.
      await _secureStorage.delete(key: ApiConstants.tokenKey);
      await _secureStorage.delete(key: ApiConstants.refreshKey);
    }
  }

  @override
  Future<UserModel> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        ApiConstants.authVerifyEmail,
        data: {'email': email, 'code': code},
      );
      final d = _data(response.data);
      final token = await _secureStorage.read(key: ApiConstants.tokenKey) ?? '';
      return UserModel.fromJson(
        (d['user'] as Map?)?.cast<String, dynamic>() ?? const {},
        token: token,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'الرمز غير صحيح أو منتهي الصلاحية');
    }
  }

  @override
  Future<void> resendCode(String email) async {
    try {
      await _dio.post(ApiConstants.authResendCode, data: {'email': email});
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'تعذّر إعادة إرسال الرمز، حاول بعد قليل');
    }
  }

  @override
  Future<bool> validateToken() async {
    try {
      await _dio.get(ApiConstants.authValidate);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.authMe);
      final token = await _secureStorage.read(key: ApiConstants.tokenKey) ?? '';
      return UserModel.fromJson(_data(response.data), token: token);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<UserModel> updateMe({String? name, String? bio, String? password}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (bio != null) body['bio'] = bio;
      if (password != null && password.isNotEmpty) body['password'] = password;
      final response = await _dio.post(ApiConstants.authMe, data: body);
      final token = await _secureStorage.read(key: ApiConstants.tokenKey) ?? '';
      return UserModel.fromJson(_data(response.data), token: token);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }
}
