import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../../shared/storage/secure_storage.dart';
import '../errors/exceptions.dart';

/// KLE HOMECARE — Dio HTTP Client
/// - Attaches Bearer token to every protected request
/// - Auto-refreshes access token on 401
/// - Redirects to login on refresh failure
/// - Web-safe: uses platform-aware storage, no credentials mode on web
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late Dio _dio;   // not final — can be re-initialised when baseUrl changes

  void init() {
    _dio = _buildDio();
  }

  /// Call this after ApiConstants.setBaseUrl() to apply the new URL immediately.
  void updateBaseUrl(String newUrl) {
    _dio = _buildDio(baseUrl: newUrl);
  }

  Dio _buildDio({String? baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Required for ngrok tunnels — skips the browser warning page
          // that ngrok shows for free-tier tunnels on web requests.
          'ngrok-skip-browser-warning': 'true',
        },
        // withCredentials: true is required on web so the browser includes
        // the Authorization header on cross-origin requests and the backend
        // can respond with Access-Control-Allow-Credentials: true.
        extra: kIsWeb ? {'withCredentials': true} : {},
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }

    dio.interceptors.add(_AuthInterceptor(dio));
    return dio;
  }

  Dio get dio => _dio;
}

/// Interceptor that:
/// 1. Attaches Authorization: Bearer <token> to every request
/// 2. On 401, attempts token refresh once
/// 3. On refresh failure, clears storage (triggers login redirect via router)
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    // Skip auth header for public auth endpoints
    if (_isPublicAuthPath(path)) {
      return handler.next(options);
    }

    final token = await SecureStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  static bool _isPublicAuthPath(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/forgot-password') ||
      path.contains('/auth/verify-otp') ||
      path.contains('/auth/reset-password');

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Never attempt a token refresh for the public auth endpoints — a 401
    // here means "wrong mobile/password", not "session expired", and there
    // is no access token on these requests to refresh in the first place.
    if (_isPublicAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.instance.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _clearAndReject(err, handler);
          return;
        }

        // Use a fresh Dio instance for the refresh call to avoid interceptor loops
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            extra: kIsWeb ? {'withCredentials': true} : {},
          ),
        );

        final refreshResp = await refreshDio.post(
          ApiConstants.refresh,
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = refreshResp.data['access_token'] as String;
        await SecureStorage.instance.saveAccessToken(newAccessToken);

        // Retry the original request with the new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResp = await _dio.fetch(opts);
        handler.resolve(retryResp);
      } catch (_) {
        await _clearAndReject(err, handler);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _clearAndReject(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await SecureStorage.instance.clearAll();
    handler.next(err);
  }
}

/// Convert DioException to a typed app exception with a user-friendly message.
Exception mapDioException(DioException e) {
  if (kDebugMode) {
    debugPrint('[DioClient] Error type: ${e.type} | message: ${e.message}');
    debugPrint('[DioClient] Response: ${e.response?.statusCode} ${e.response?.data}');
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const NetworkException(message: 'Connection timed out. Check your network.');
    case DioExceptionType.connectionError:
      return NetworkException(
        message: kIsWeb
            ? 'Cannot reach the server. Make sure the backend is running on ${ApiConstants.baseUrl}'
            : 'No internet connection',
      );
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final message    = _extractMessage(e.response?.data);
      // On the public auth endpoints a 401/400 means invalid credentials or
      // a validation failure — surface the real backend message instead of
      // the generic "session expired" copy.
      if (statusCode == 401 && !_AuthInterceptor._isPublicAuthPath(e.requestOptions.path)) {
        return const UnauthorizedException();
      }
      return ServerException(message: message, statusCode: statusCode);
    case DioExceptionType.unknown:
      // On web, CORS errors surface as DioExceptionType.unknown with no response
      if (kIsWeb && e.response == null) {
        return NetworkException(
          message:
              'Network error — possible CORS issue. '
              'Ensure the backend is running at ${ApiConstants.baseUrl} '
              'and CORS is enabled.',
        );
      }
      return ServerException(message: e.message ?? 'Unknown error');
    default:
      return ServerException(message: e.message ?? 'Unknown error');
  }
}

String _extractMessage(dynamic data) {
  if (data is Map) {
    return data['detail']?.toString() ??
        data['message']?.toString() ??
        'Server error';
  }
  return 'Server error';
}
