import 'package:json_annotation/json_annotation.dart';

import '../../../../core/session/auth_session.dart';

part 'login_response_dto.g.dart';

/// API JSON for `POST /accounts/api/login/`.
@JsonSerializable(createToJson: false)
class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  final UserDto user;

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  /// Maps DTO → app-wide session model.
  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toDomain(),
    );
  }
}

@JsonSerializable(createToJson: false)
class UserDto {
  const UserDto({
    required this.id,
    required this.profileId,
    required this.username,
    required this.fullName,
    required this.email,
    required this.isAdmin,
    required this.isTrainer,
    required this.isClient,
    required this.roles,
  });

  final int id;
  @JsonKey(name: 'profile_id')
  final int profileId;
  final String username;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String email;
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @JsonKey(name: 'is_trainer')
  final bool isTrainer;
  @JsonKey(name: 'is_client')
  final bool isClient;
  @JsonKey(fromJson: _rolesFromJson)
  final List<String> roles;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  AuthenticatedUser toDomain() {
    return AuthenticatedUser(
      id: id,
      profileId: profileId,
      username: username,
      fullName: fullName,
      email: email,
      isAdmin: isAdmin,
      isTrainer: isTrainer,
      isClient: isClient,
      roles: roles,
    );
  }
}

/// Accepts `[]` or a list of strings/objects from the API.
List<String> _rolesFromJson(Object? json) {
  if (json is! List<dynamic>) return const [];
  return json.map((e) => e.toString()).toList();
}
