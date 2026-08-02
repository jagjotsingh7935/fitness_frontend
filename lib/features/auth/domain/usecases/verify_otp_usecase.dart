import '../../../../core/session/auth_session.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Application use case: submit OTP and establish a session.
final class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required String email,
    required String otp,
  }) {
    return _repository.verifyOtp(email: email, otp: otp);
  }
}
