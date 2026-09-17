import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/network/error/exceptions.dart';
import '../../../auth/data/models/category_dto.dart';
import '../models/client_profile_dto.dart';

class ClientRemoteDataSource {
  ClientRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ClientProfileDto> fetchMyProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.currentUserPath,
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response received from server.');
      }

      return ClientProfileDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to load profile: $e');
    }
  }

  Future<ClientProfileDto> updateMyProfile(Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.currentUserPath,
        data: updateData,
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response received from server.');
      }

      return ClientProfileDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to update profile: $e');
    }
  }

  Future<List<CategoryDto>> fetchCategories() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.categoryListPath,
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic> && data['results'] is List) {
        return (data['results'] as List)
            .map((item) => CategoryDto.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Failed to load categories: $e');
    }
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutException('Connection timeout. Please check your internet connection.');
    }

    final data = e.response?.data;
    String? message;
    if (data is Map<String, dynamic>) {
      message = data['detail']?.toString() ??
          data['message']?.toString() ??
          data['error']?.toString();
      if (message == null && data.isNotEmpty) {
        final errors = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            errors.add('$key: ${value.join(", ")}');
          } else {
            errors.add('$key: $value');
          }
        });
        if (errors.isNotEmpty) {
          message = errors.join('\n');
        }
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    return ServerException(
      message ?? e.message ?? 'Server error occurred.',
      statusCode: e.response?.statusCode,
    );
  }
}
