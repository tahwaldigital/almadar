import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  DioClient({
    FlutterSecureStorage? secureStorage,
    Logger? logger,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _logger = logger ?? Logger() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: ApiConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('[DIO] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('[DIO] ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) async {
          final req = error.requestOptions;
          final isAuthCall = req.path.contains('/auth/');
          final alreadyRetried = req.extra['retried'] == true;
          if (error.response?.statusCode == 401 && !isAuthCall && !alreadyRetried) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                req.extra['retried'] = true;
                final token = await _secureStorage.read(key: ApiConstants.tokenKey);
                req.headers['Authorization'] = 'Bearer $token';
                final clone = await _dio.fetch(req);
                return handler.resolve(clone);
              } catch (_) {/* fall through to error */}
            }
          }
          _logger.e('[DIO] Error: ${error.message}', error: error.error);
          handler.next(error);
        },
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Attempts to exchange the stored refresh token for a new access token.
  Future<bool> _tryRefresh() async {
    try {
      final refresh = await _secureStorage.read(key: ApiConstants.refreshKey);
      if (refresh == null || refresh.isEmpty) return false;
      // Use a bare Dio to avoid interceptor recursion.
      final res = await Dio().post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refresh},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final body = res.data;
      final data = (body is Map && body['data'] is Map) ? body['data'] : body;
      final newToken = (data is Map) ? data['token'] as String? : null;
      final newRefresh = (data is Map) ? data['refresh_token'] as String? : null;
      if (newToken == null || newToken.isEmpty) return false;
      await _secureStorage.write(key: ApiConstants.tokenKey, value: newToken);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _secureStorage.write(key: ApiConstants.refreshKey, value: newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(message: 'انتهت مهلة الاتصال');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'لا يوجد اتصال بالإنترنت');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMessage = _extractMessage(e.response?.data);
        if (statusCode == 401) {
          return AuthException(message: serverMessage ?? 'انتهت صلاحية الجلسة');
        }
        if (statusCode == 404) {
          return const ServerException(message: 'المحتوى غير موجود', statusCode: 404);
        }
        return ServerException(
          message: serverMessage ?? 'خطأ في الخادم',
          statusCode: statusCode,
        );
      default:
        return ServerException(message: e.message ?? 'خطأ غير متوقع');
    }
  }

  /// Reads the error message from the Almadar envelope
  /// ({ error: { message } }) or a plain { message }.
  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return null;
  }
}
