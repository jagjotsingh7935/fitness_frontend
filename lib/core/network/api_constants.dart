/// Central place for API configuration and endpoints.
///
/// Keep base URL and endpoint paths here to avoid hardcoding strings across
/// the app. Feature data layers can compose URLs using these constants.
abstract final class ApiConstants {
  /// Backend base URL (no trailing slash).
  static const String baseUrl =
      ///'https://fitness-backend-ygh0.onrender.com';
      ///'https://volcanic-yeastily-van.ngrok-free.dev';
      'http://34.131.104.116';

  /// Email/password login (multipart form: `username`, `password`).
  static const String loginPath = '/accounts/api/login/';
  static const String adminLoginPath = '/accounts/api/login/';

  /// Request OTP email (multipart form: `email`).
  static const String requestOtpPath = '/accounts/api/request-otp/';

  /// Verify OTP (multipart form: `email`, `otp`).
  static const String verifyOtpPath = '/accounts/api/verify-otp/';

  /// Client self-registration (JSON body, optionally authenticated).
  static const String clientSignupPath = '/accounts/api/signup/client/';

  /// Public active categories list for signup/profiles.
  static const String categoryListPath = '/accounts/api/category-list/';

  /// Current authenticated user profile (GET/PATCH)
  static const String currentUserPath = '/accounts/api/me/';

  // Other examples (extend as features grow).
  static const String user = '/user';

}
