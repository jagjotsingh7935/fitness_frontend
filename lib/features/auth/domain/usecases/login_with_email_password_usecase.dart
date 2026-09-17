import '../../../../core/session/auth_session.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Application use case: email/password login.
///
/// The repository is responsible for calling the API and persisting the
/// session (tokens) for subsequent authenticated requests.
final class LoginWithEmailPasswordUseCase {
  const LoginWithEmailPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
    bool isAdmin = false,
    String? role,
  }) {
    return _repository.loginWithEmailAndPassword(
      email: email,
      password: password,
      isAdmin: isAdmin,
      role: role,
    );
  }
}
