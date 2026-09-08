import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/error/exceptions.dart';
import '../models/category_dto.dart';
import '../models/client_signup_request_dto.dart';
import '../models/client_signup_response_dto.dart';
import '../models/login_response_dto.dart';
import '../models/request_otp_response_dto.dart';
import '../models/verify_otp_response_dto.dart';

/// Low-level login API calls (Dio only — no domain types).
final class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Fetches active fitness categories for signup.
  Future<List<CategoryDto>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categoryListPath);
      final data = response.data;
      if (data == null) {
        return [];
      }

      List<dynamic> items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data.containsKey('results') && data['results'] is List) {
        items = data['results'] as List<dynamic>;
      }

      return items
          .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
          .where((cat) => cat.isActive)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// `multipart/form-data` with fields `username` (email) and `password`.

  ///
  /// If [isAdmin] is true, the admin login endpoint is used instead of the
  /// regular client login endpoint.
  Future<LoginResponseDto> loginWithEmailAndPassword({
    required String email,
    required String password,
    bool isAdmin = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        // Backend contract uses Django-style `username` for the email/login id.
        'username': email,
        'password': password,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        isAdmin ? ApiConstants.adminLoginPath : ApiConstants.loginPath,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw ServerException(
          'Empty response from server.',
          statusCode: response.statusCode,
        );
      }

      return LoginResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Sends a one-time code to [email] (`multipart/form-data`, field `email`).
  Future<RequestOtpResponseDto> requestOtp({required String email}) async {
    try {
      final formData = FormData.fromMap({'email': email});

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.requestOtpPath,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw ServerException(
          'Empty response from server.',
          statusCode: response.statusCode,
        );
      }

      return RequestOtpResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Exchanges [email] + [otp] for tokens (`multipart/form-data`).
  Future<VerifyOtpResponseDto> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final formData = FormData.fromMap({
        'email': email,
        'otp': otp,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.verifyOtpPath,
        data: formData,
      );

      final data = response.data;
      if (data == null) {
        throw ServerException(
          'Empty response from server.',
          statusCode: response.statusCode,
        );
      }

      return VerifyOtpResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Registers a new client account (`application/json` body).
  Future<ClientSignupResponseDto> signupClient(
    ClientSignupRequestDto request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.clientSignupPath,
        data: request.toJson(),
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data;
      if (data == null) {
        throw ServerException(
          'Empty response from server.',
          statusCode: response.statusCode,
        );
      }

      return ClientSignupResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Prefer validation/detail messages from JSON while preserving status semantics.
  AppException _mapDioException(DioException e) {
    final parsed = _parseServerMessage(e);
    final inferred = e.error;

    if (parsed != null && inferred is AppException) {
      if (inferred is UnauthorizedException) {
        return UnauthorizedException(
          parsed,
          statusCode: inferred.statusCode ?? e.response?.statusCode,
        );
      }
      if (inferred is TimeoutException) {
        return TimeoutException(
          parsed.isNotEmpty ? parsed : inferred.message,
          statusCode: inferred.statusCode ?? e.response?.statusCode,
        );
      }
      if (inferred is ServerException) {
        return ServerException(
          parsed.isNotEmpty ? parsed : inferred.message,
          statusCode: inferred.statusCode ?? e.response?.statusCode,
        );
      }
      if (inferred is NetworkException) {
        return NetworkException(
          parsed.isNotEmpty ? parsed : inferred.message,
          statusCode: inferred.statusCode ?? e.response?.statusCode,
        );
      }
    }

    if (inferred is AppException) return inferred;

    final fallback =
        parsed ??
        e.message ??
        'Could not complete the request. Please try again.';
    return NetworkException(
      fallback,
      statusCode: e.response?.statusCode,
    );
  }

  /// Best-effort extraction for Django/DRF style payloads.
  String? _parseServerMessage(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;

    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List && detail.isNotEmpty) {
      return detail.map((x) => x.toString()).join('\n');
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    // e.g. `{ "error": "Invalid or expired OTP" }`
    final error = data['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();

    final nonField = data['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) {
      return nonField.first.toString();
    }

    // Single-field errors: pick first string list/value if small.
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is List && value.isNotEmpty && entry.key != 'roles') {
        final first = value.first;
        if (first is String) return first;
      }
    }

    return null;
  }
}
