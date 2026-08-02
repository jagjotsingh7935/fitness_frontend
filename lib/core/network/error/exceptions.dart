// Exceptions thrown by the data/network layer.
//
// IMPORTANT: Do not expose Dio/Retrofit types outside the data layer.
// Interceptors and data sources should throw these exceptions instead.

abstract class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: ${statusCode ?? '-'})';
}

final class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.statusCode});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

final class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.statusCode});
}

