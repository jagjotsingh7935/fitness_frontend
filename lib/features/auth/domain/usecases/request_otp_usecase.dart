import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Application use case: ask the backend to email an OTP.
final class RequestOtpUseCase {
  const RequestOtpUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the server [String] message on success (e.g. "OTP sent to email").
  Future<Result<String>> call({required String email}) {
    return _repository.requestOtp(email: email);
  }
}
