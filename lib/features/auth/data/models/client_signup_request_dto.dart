/// JSON payload for `POST /accounts/api/signup/client/`.
final class ClientSignupRequestDto {
  const ClientSignupRequestDto({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.categoryIds,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  /// ISO-8601 date string (e.g. "1990-05-15").
  final String dateOfBirth;
  final String address;
  final List<int> categoryIds;

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'address': address,
      'category_ids': categoryIds,
    };
  }
}
