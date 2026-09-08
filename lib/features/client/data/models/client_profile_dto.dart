import '../../../auth/data/models/category_dto.dart';

final class ClientProfileDto {
  const ClientProfileDto({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.dateOfBirth,
    this.phone,
    this.address,
    this.isActive = true,
    this.categories = const [],
    this.activeTrainers = const [],
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

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? dateOfBirth;
  final String? phone;
  final String? address;
  final bool isActive;
  final List<CategoryDto> categories;
  final List<Map<String, dynamic>> activeTrainers;

  // Body stats
  final String? gender;
  final String? age;
  final dynamic weight;
  final dynamic height;
  final dynamic neckCircumference;
  final dynamic waist;
  final dynamic bmi;
  final dynamic fatPercent;

  // Preferred targets
  final dynamic preferredBmi;
  final dynamic preferredWeight;
  final dynamic preferredWaist;
  final dynamic preferredFatPercent;

  factory ClientProfileDto.fromJson(Map<String, dynamic> json) {
    return ClientProfileDto(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      dateOfBirth: json['date_of_birth'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeTrainers: (json['active_trainers'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      gender: json['gender'] as String?,
      age: json['age']?.toString(),
      weight: json['weight'],
      height: json['height'],
      neckCircumference: json['neck_circumference'],
      waist: json['waist'],
      bmi: json['bmi'],
      fatPercent: json['fat_percent'],
      preferredBmi: json['preferred_bmi'],
      preferredWeight: json['preferred_weight'],
      preferredWaist: json['preferred_waist'],
      preferredFatPercent: json['preferred_fat_percent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'phone': phone,
      'address': address,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'neck_circumference': neckCircumference,
      'waist': waist,
      'bmi': bmi,
      'fat_percent': fatPercent,
      'preferred_bmi': preferredBmi,
      'preferred_weight': preferredWeight,
      'preferred_waist': preferredWaist,
      'preferred_fat_percent': preferredFatPercent,
    };
  }

  ClientProfileDto copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? dateOfBirth,
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
    List<CategoryDto>? categories,
  }) {
    return ClientProfileDto(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: '${firstName ?? this.firstName} ${lastName ?? this.lastName}'.trim(),
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isActive: isActive,
      categories: categories ?? this.categories,
      activeTrainers: activeTrainers,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      neckCircumference: neckCircumference ?? this.neckCircumference,
      waist: waist ?? this.waist,
      bmi: bmi ?? this.bmi,
      fatPercent: fatPercent ?? this.fatPercent,
      preferredBmi: preferredBmi ?? this.preferredBmi,
      preferredWeight: preferredWeight ?? this.preferredWeight,
      preferredWaist: preferredWaist ?? this.preferredWaist,
      preferredFatPercent: preferredFatPercent ?? this.preferredFatPercent,
    );
  }
}
