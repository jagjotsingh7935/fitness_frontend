import 'package:equatable/equatable.dart';

/// Logged-in user profile returned by the backend (normalized for the app).
final class AuthenticatedUser extends Equatable {
  const AuthenticatedUser({
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
  final int profileId;
  final String username;
  final String fullName;
  final String email;
  final bool isAdmin;
  final bool isTrainer;
  final bool isClient;

  /// Role names or identifiers from the API (may be empty).
  final List<String> roles;

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as int? ?? 0,
      profileId: json['profile_id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      isTrainer: json['is_trainer'] as bool? ?? false,
      isClient: json['is_client'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'username': username,
      'full_name': fullName,
      'email': email,
      'is_admin': isAdmin,
      'is_trainer': isTrainer,
      'is_client': isClient,
      'roles': roles,
    };
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    username,
    fullName,
    email,
    isAdmin,
    isTrainer,
    isClient,
    roles,
  ];
}

/// Tokens + user snapshot after a successful sign-in.
final class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthenticatedUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      user: AuthenticatedUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}

