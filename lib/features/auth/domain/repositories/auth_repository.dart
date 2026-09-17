import '../../../../core/session/auth_session.dart';
import '../../../../core/utils/result.dart';
import '../../data/models/category_dto.dart';

/// Auth operations used by the presentation/domain layers.
///
/// Implementations live in `data/` and map network models to [AuthSession].
abstract class AuthRepository {
  /// Fetches active fitness categories for signup.
  Future<Result<List<CategoryDto>>> fetchCategories();

  /// Signs in with email + password (API field name: `username`).
  Future<Result<AuthSession>> loginWithEmailAndPassword({
    required String email,
    required String password,
    bool isAdmin = false,
    String? role,
  });

  /// Triggers the backend to email an OTP to [email].
  /// On success, returns the server message (for display).
  Future<Result<String>> requestOtp({required String email});

  /// Validates [otp] for [email] and returns a session (tokens persisted by impl).
  Future<Result<AuthSession>> verifyOtp({
    required String email,
    required String otp,
  });

  /// Registers a new client. Returns a server message on success.
  Future<Result<String>> signupClient({
    required String email,
    required String firstName,
    required String lastName,
    String? password,
    required String phone,
    required String dateOfBirth,
    required String address,
    required List<int> categoryIds,
    String? gender,
    String? age,
    dynamic weight,
    dynamic height,
    dynamic neckCircumference,
    dynamic waist,
    dynamic bmi,
    dynamic fatPercent,
    dynamic preferredBmi,
    dynamic preferredWeight,
    dynamic preferredWaist,
    dynamic preferredFatPercent,
  });
}

