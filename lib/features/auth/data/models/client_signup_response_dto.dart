/// Generic success wrapper for `POST /accounts/api/signup/client/`.
///
/// The server may return varying shapes; this extracts a human-readable
/// message for the UI while remaining resilient to unknown fields.
final class ClientSignupResponseDto {
  const ClientSignupResponseDto({required this.message});

  final String message;

  factory ClientSignupResponseDto.fromJson(Map<String, dynamic> json) {
    final msg = json['message'] as String? ??
        json['detail'] as String? ??
        'Client registered successfully.';
    return ClientSignupResponseDto(message: msg);
  }
}
