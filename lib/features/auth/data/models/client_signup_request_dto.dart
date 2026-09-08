/// JSON payload for `POST /accounts/api/signup/client/`.
final class ClientSignupRequestDto {
  const ClientSignupRequestDto({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.password,
    required this.phone,
    required this.dateOfBirth,
    required this.address,
    required this.categoryIds,
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.neckCircumference,
    this.waist,
    this.bmi,
    this.fatPercent,
    this.preferredBmi,
    this.preferredWeight,
    this.preferredWaist,
    this.preferredFatPercent,
  });

  final String email;
  final String firstName;
  final String lastName;
  final String? password;
  final String phone;
  /// ISO-8601 date string (e.g. "1990-05-15").
  final String dateOfBirth;
  final String address;
  final List<int> categoryIds;

  // Optional body stats & preferences
  final String? gender;
  final String? age;
  final dynamic weight;
  final dynamic height;
  final dynamic neckCircumference;
  final dynamic waist;
  final dynamic bmi;
  final dynamic fatPercent;
  final dynamic preferredBmi;
  final dynamic preferredWeight;
  final dynamic preferredWaist;
  final dynamic preferredFatPercent;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'address': address,
      'category_ids': categoryIds,
    };

    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    if (gender != null && gender!.isNotEmpty) {
      data['gender'] = gender;
    }
    if (age != null && age!.isNotEmpty) {
      data['age'] = age;
    }
    if (weight != null) {
      data['weight'] = weight;
    }
    if (height != null) {
      data['height'] = height;
    }
    if (neckCircumference != null) {
      data['neck_circumference'] = neckCircumference;
    }
    if (waist != null) {
      data['waist'] = waist;
    }
    if (bmi != null) {
      data['bmi'] = bmi;
    }
    if (fatPercent != null) {
      data['fat_percent'] = fatPercent;
    }
    if (preferredBmi != null) {
      data['preferred_bmi'] = preferredBmi;
    }
    if (preferredWeight != null) {
      data['preferred_weight'] = preferredWeight;
    }
    if (preferredWaist != null) {
      data['preferred_waist'] = preferredWaist;
    }
    if (preferredFatPercent != null) {
      data['preferred_fat_percent'] = preferredFatPercent;
    }

    return data;
  }
}

