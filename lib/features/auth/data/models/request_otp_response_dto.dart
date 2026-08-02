/// API JSON for `POST /accounts/api/request-otp/`.
final class RequestOtpResponseDto {
  const RequestOtpResponseDto({required this.message});

  final String message;

  factory RequestOtpResponseDto.fromJson(Map<String, dynamic> json) {
    return RequestOtpResponseDto(
      message: json['message'] as String? ?? 'OTP sent.',
    );
  }
}
