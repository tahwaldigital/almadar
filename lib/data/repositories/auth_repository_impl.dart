import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._remote, this._secureStorage);

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final user = await _remote.login(username, password);
      await _secureStorage.write(
          key: ApiConstants.userKey, value: jsonEncode(user.toJson()));
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register(String name, String email, String password) async {
    try {
      final user = await _remote.register(name, email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      await _secureStorage.delete(key: ApiConstants.userKey);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userJson = await _secureStorage.read(key: ApiConstants.userKey);
      if (userJson == null) return const Right(null);
      final user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateToken() async {
    try {
      final isValid = await _remote.validateToken();
      return Right(isValid);
    } catch (e) {
      return const Right(false);
    }
  }
}
