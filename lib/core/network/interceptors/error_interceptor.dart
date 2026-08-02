import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Converts Dio errors into app-specific exceptions.
///
/// This keeps Dio types contained within the network layer.
final class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _map(err);

    // Attach a strongly-typed exception for the data layer to throw if desired.
    err = err.copyWith(error: exception);
    handler.next(err);
  }

  AppException _map(DioException err) {
    final status = err.response?.statusCode;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'Request timed out. Please try again.',
          statusCode: status,
        );

      case DioExceptionType.badResponse:
        if (status == 401) {
          return UnauthorizedException(
            'Unauthorized. Please sign in again.',
            statusCode: status,
          );
        }
        if (status != null && status >= 500) {
          return ServerException(
            'Server error. Please try again later.',
            statusCode: status,
          );
        }
        return NetworkException(
          'Request failed. Please try again.',
          statusCode: status,
        );

      case DioExceptionType.cancel:
        return NetworkException('Request was cancelled.', statusCode: status);

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection. Check your network and try again.',
          statusCode: status,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'Could not establish a secure connection.',
          statusCode: status,
        );

      case DioExceptionType.unknown:
        // Often indicates SocketException/handshake errors etc.
        return NetworkException(
          'Unexpected network error. Please try again.',
          statusCode: status,
        );
    }
  }
}

