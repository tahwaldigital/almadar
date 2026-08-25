import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

class DioClient {
  late final Dio _dio;
  final Logger _logger;

  DioClient({Logger? logger}) : _logger = logger ?? Logger() {
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
        onRequest: (options, handler) {
          _logger.d('[DIO] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('[DIO] ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
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
