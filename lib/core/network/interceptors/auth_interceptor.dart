import 'dart:async';

import 'package:dio/dio.dart';

/// Adds an `Authorization: Bearer <token>` header when a token is available.
///
/// Token is provided via a callback so it can change over time (refresh/login)
/// without relying on globals or re-creating Dio.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required FutureOr<String?> Function() tokenProvider})
    : _tokenProvider = tokenProvider;

  final FutureOr<String?> Function() _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _tokenProvider();
      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
    } catch (_) {
      // If token resolution fails, continue without auth header.
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }
}

