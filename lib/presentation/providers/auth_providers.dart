import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import 'providers.dart';

// ── Auth State ─────────────────────────────────────────────────────────────────
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    final repo = _ref.read(authRepositoryProvider);
    final result = await repo.getCurrentUser();
    result.fold(
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
      (user) {
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    final useCase = _ref.read(loginUserProvider);
    final result = await useCase(username, password);
    return result.fold(
      (failure) {
        state = AuthState(status: AuthStatus.error, errorMessage: failure.message);
        return false;
      },
      (user) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      },
    );
  }

  Future<bool> socialLogin(String provider, String email, String name) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _ref
          .read(authRemoteDataSourceProvider)
          .socialLogin(provider, email, name);
      await _persist(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProfile({String? name, String? bio, String? password}) async {
    try {
      final user = await _ref
          .read(authRemoteDataSourceProvider)
          .updateMe(name: name, bio: bio, password: password);
      await _persist(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist(User user) async {
    if (user is UserModel) {
      await _ref
          .read(secureStorageProvider)
          .write(key: ApiConstants.userKey, value: jsonEncode(user.toJson()));
    }
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
