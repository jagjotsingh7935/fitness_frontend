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
  }) {
    return _repository.signupClient(
      email: email,
      firstName: firstName,
      lastName: lastName,
      password: password,
      phone: phone,
      dateOfBirth: dateOfBirth,
      address: address,
      categoryIds: categoryIds,
      gender: gender,
      age: age,
      weight: weight,
      height: height,
      neckCircumference: neckCircumference,
      waist: waist,
      bmi: bmi,
      fatPercent: fatPercent,
      preferredBmi: preferredBmi,
      preferredWeight: preferredWeight,
      preferredWaist: preferredWaist,
      preferredFatPercent: preferredFatPercent,
    );
  }
}

