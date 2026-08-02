import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Clean request/response logging.
///
/// Enabled only in debug mode to avoid leaking sensitive data in production.
final class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({String tag = 'HTTP'}) : _tag = tag;

  final String _tag;

  bool get _enabled => kDebugMode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      developer.log(
        _formatRequest(options),
        name: _tag,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      developer.log(
        _formatResponse(response),
        name: _tag,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      developer.log(
        _formatError(err),
        name: _tag,
      );
    }
    handler.next(err);
  }

  String _formatRequest(RequestOptions o) {
    final buffer = StringBuffer()
      ..writeln('→ ${o.method} ${o.uri}')
      ..writeln('Headers: ${_pretty(o.headers)}');

    if (o.queryParameters.isNotEmpty) {
      buffer.writeln('Query: ${_pretty(o.queryParameters)}');
    }
    if (o.data != null) {
      buffer.writeln('Body: ${_pretty(o.data)}');
    }
    return buffer.toString().trimRight();
  }

  String _formatResponse(Response r) {
    final buffer = StringBuffer()
      ..writeln('← ${r.statusCode} ${r.requestOptions.method} ${r.requestOptions.uri}')
      ..writeln('Headers: ${_pretty(r.headers.map)}');

    if (r.data != null) {
      buffer.writeln('Response: ${_pretty(r.data)}');
    }
    return buffer.toString().trimRight();
  }

  String _formatError(DioException e) {
    final status = e.response?.statusCode;
    final buffer = StringBuffer()
      ..writeln('⨯ ${status ?? '-'} ${e.requestOptions.method} ${e.requestOptions.uri}')
      ..writeln('Type: ${e.type}')
      ..writeln('Message: ${e.message}');

    final data = e.response?.data;
    if (data != null) {
      buffer.writeln('Error body: ${_pretty(data)}');
    }
    return buffer.toString().trimRight();
  }

  String _pretty(Object? value) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

