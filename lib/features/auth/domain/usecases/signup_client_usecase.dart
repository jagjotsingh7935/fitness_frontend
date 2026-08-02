import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Application use case: register a new client account.
final class SignupClientUseCase {
  const SignupClientUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the server success message on completion.
  Future<Result<String>> call({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    required String address,
    required List<int> categoryIds,
  }) {
    return _repository.signupClient(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dateOfBirth: dateOfBirth,
      address: address,
      categoryIds: categoryIds,
    );
  }
}
