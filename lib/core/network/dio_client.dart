import 'dart:async';

import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Single place to configure Dio.
///
/// - Sets base options (baseUrl, timeouts)
/// - Registers interceptors (auth, logging, error mapping)
/// - Exposes a configured Dio instance for Retrofit/data sources
final class DioClient {
  DioClient({
    required FutureOr<String?> Function() tokenProvider,
    Dio? dio,
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? ApiConstants.baseUrl,
               connectTimeout: connectTimeout,
               receiveTimeout: receiveTimeout,
               headers: const {
                 'Accept': 'application/json',
                 // Ngrok sometimes serves an HTML interstitial unless this hint is sent.
                 'ngrok-skip-browser-warning': 'true',
               },
             ),
           ) {
    _dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  Dio get dio => _dio;
}

