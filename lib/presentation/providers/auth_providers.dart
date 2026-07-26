import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
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

  /// [clearError] يسمح بمسح رسالة الخطأ صراحةً — نمط `?? this` وحده لا يستطيع
  /// إعادتها إلى null، فتبقى رسالة قديمة معلّقة عبر الحالات.
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
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

  /// ينشئ حسابًا، يحدّث الحالة، ويعيد (نجاح، مؤكَّد البريد، رسالة الخطأ).
  Future<({bool ok, bool verified, String? error})> register(
      String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _ref
          .read(authRemoteDataSourceProvider)
          .register(name, email, password);
      await _persist(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return (ok: true, verified: user.emailVerified, error: null);
    } catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      state = AuthState(status: AuthStatus.error, errorMessage: msg);
      return (ok: false, verified: false, error: msg);
    }
  }

  /// يؤكّد كود البريد؛ يعيد null عند النجاح أو رسالة الخطأ.
  Future<String?> verifyEmailCode(String email, String code) async {
    try {
      final user =
          await _ref.read(authRemoteDataSourceProvider).verifyEmail(email, code);
      await _persist(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return null;
    } catch (e) {
      return e is AuthException ? e.message : e.toString();
    }
  }

  /// يعيد إرسال كود التأكيد؛ يعيد null عند النجاح أو رسالة الخطأ.
  Future<String?> resendCode(String email) async {
    try {
      await _ref.read(authRemoteDataSourceProvider).resendCode(email);
      return null;
    } catch (e) {
      return e is AuthException ? e.message : e.toString();
    }
  }

  Future<bool> socialLogin(String provider, String email, String name) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
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
    await _ref.read(secureStorageProvider).delete(key: ApiConstants.userKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// يحذف الحساب من الخادم ويمسح كل بيانات الجلسة المحلية.
  /// يعيد true عند نجاح الحذف.
  Future<bool> deleteAccount() async {
    try {
      await _ref.read(authRemoteDataSourceProvider).deleteAccount();
      await _ref.read(secureStorageProvider).delete(key: ApiConstants.userKey);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
