import '../../../../core/session/auth_session.dart';
import 'login_response_dto.dart';

/// API JSON for `POST /accounts/api/verify-otp/` (tokens use `access` / `refresh`).
final class VerifyOtpResponseDto {
  const VerifyOtpResponseDto({
    required this.access,
    required this.refresh,
    required this.user,
  });

  final String access;
  final String refresh;
  final UserDto user;

  factory VerifyOtpResponseDto.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseDto(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AuthSession toDomain() {
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      user: user.toDomain(),
    );
  }
}
