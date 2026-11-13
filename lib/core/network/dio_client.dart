import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'api_hosts.dart';

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
  }) =>
      _withFailover(
        path,
        (url) => _dio.get<T>(url,
            queryParameters: queryParameters, options: options),
      );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _withFailover(
        path,
        (url) => _dio.post<T>(url,
            data: data, queryParameters: queryParameters, options: options),
      );

  /// Sends the request to the live domain. If that domain can't be reached
  /// (blocked in the user's country, down, or no longer serving the API), the
  /// same request is tried on the other configured domains. If every domain
  /// fails, Remote Config is asked once for a newer list before giving up, so
  /// moving the site never needs an app update.
  Future<Response<T>> _withFailover<T>(
    String path,
    Future<Response<T>> Function(String url) send,
  ) async {
    final hosts = ApiHosts.instance;
    final ours = hosts.owns(path);
    var candidates = hosts.candidatesFor(path);
    DioException? lastError;

    for (var round = 0; round < 2; round++) {
      for (final url in candidates) {
        try {
          final res = await send(url);
          if (!ours) return res;
          if (!_isHtml(res)) {
            hosts.markWorking(url);
            return res;
          }
          // 200 with an HTML page (parked domain, block page): not our API.
          lastError = DioException.badResponse(
            statusCode: res.statusCode ?? 0,
            requestOptions: res.requestOptions,
            response: res,
          );
        } on DioException catch (e) {
          lastError = e;
          if (!ours || !_isHostFailure(e)) throw _handleDioError(e);
        }
      }
      if (round > 0 || !await hosts.refresh()) break;
      candidates = hosts.candidatesFor(path);
    }
    throw _handleDioError(lastError!);
  }

  /// Errors that mean "this domain is unusable", as opposed to the API itself
  /// answering with an error. Only these move the request to another domain.
  static bool _isHostFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.badCertificate:
        return true;
      case DioExceptionType.unknown:
        // A reset during the TLS handshake is how a filtered domain usually fails.
        return e.error is TlsException || e.error is SocketException;
      case DioExceptionType.badResponse:
        // The API always answers in JSON; anything else came from something
        // sitting in front of it (redirect, block page, parked domain).
        return !_isApiResponse(e.response);
      default:
        return false;
    }
  }

  static bool _isApiResponse(Response<dynamic>? res) =>
      res?.headers.value(Headers.contentTypeHeader)?.contains('json') ?? false;

  static bool _isHtml(Response<dynamic> res) =>
      res.headers.value(Headers.contentTypeHeader)?.contains('text/html') ??
      false;

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
