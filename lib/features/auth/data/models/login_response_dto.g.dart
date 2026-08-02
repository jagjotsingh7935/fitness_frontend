// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: (json['id'] as num).toInt(),
  profileId: (json['profile_id'] as num).toInt(),
  username: json['username'] as String,
  fullName: json['full_name'] as String,
  email: json['email'] as String,
  isAdmin: json['is_admin'] as bool,
  isTrainer: json['is_trainer'] as bool,
  isClient: json['is_client'] as bool,
  roles: _rolesFromJson(json['roles']),
);
